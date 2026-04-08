import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TEFAS fon bilgisi
class TefasFund {
  final String code;
  final String name;
  final String type;
  final double currentPrice;
  final double dailyReturn;
  final double monthlyReturn;
  final double yearlyReturn;

  const TefasFund({
    required this.code,
    required this.name,
    required this.type,
    required this.currentPrice,
    this.dailyReturn   = 0,
    this.monthlyReturn = 0,
    this.yearlyReturn  = 0,
  });
}

abstract interface class TefasDataSource {
  Future<List<TefasFund>> searchFunds(String query);
  Future<double?> getCurrentPrice(String code);
  Future<List<TefasFund>> getAllFunds();
}

/// TEFAS RapidAPI entegrasyonu
/// Endpoint: https://rapidapi.com/serifcolakel/api/tefas-api
///
/// Kullanılan endpointler:
///   GET /api/v1/funds/returns?fundType=1&startDate=DD.MM.YYYY&endDate=DD.MM.YYYY
///   GET /api/v1/funds
class TefasDataSourceImpl implements TefasDataSource {
  late final Dio _dio;

  // Bellek cache (hot restart'ta korunur)
  static List<TefasFund>? _memCache;
  static DateTime?        _memCacheAt;
  static DateTime?        _rateLimitedUntil;
  static const _cacheDuration    = Duration(hours: 4);
  static const _rateLimitBackoff = Duration(minutes: 5);

  // Disk cache anahtarları (SharedPreferences)
  static const _prefKeyData = 'tefas_funds_json';
  static const _prefKeyTime = 'tefas_funds_ts';

  /// API key: dart-define ile override edilebilir
  /// flutter run --dart-define=RAPIDAPI_TEFAS_KEY=your_key
  static const _apiKey = String.fromEnvironment(
    'RAPIDAPI_TEFAS_KEY',
    defaultValue: '6f9f3b646amsh892717882cf9b7cp16dd7bjsnf389be28196d',
  );
  static const _apiHost = 'tefas-api.p.rapidapi.com';
  static const _baseUrl  = 'https://tefas-api.p.rapidapi.com';

  static Map<String, String> get _headers => {
    'x-rapidapi-key':  _apiKey,
    'x-rapidapi-host': _apiHost,
    'Accept':          'application/json',
  };

  TefasDataSourceImpl() {
    _dio = Dio(BaseOptions(
      baseUrl:        _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ));
  }

  @override
  Future<List<TefasFund>> searchFunds(String query) async {
    if (query.trim().length < 2) return [];
    final all = await getAllFunds();
    final q   = query.toUpperCase().trim();
    return all
        .where((f) =>
            f.code.toUpperCase().contains(q) ||
            f.name.toUpperCase().contains(q))
        .take(20)
        .toList();
  }

  @override
  Future<double?> getCurrentPrice(String code) async {
    final all = await getAllFunds();
    try {
      return all
          .firstWhere((f) => f.code.toUpperCase() == code.toUpperCase())
          .currentPrice;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<TefasFund>> getAllFunds() async {
    // 1. Bellek cache geçerliyse direkt dön
    if (_isMemCacheValid()) return _memCache!;

    // 2. Disk cache'i kontrol et
    final diskFunds = await _loadFromDisk();
    if (diskFunds != null) {
      _memCache   = diskFunds;
      _memCacheAt = DateTime.now();
      debugPrint('[TEFAS] Disk cache\'den yüklendi (${diskFunds.length} fon).');
      return diskFunds;
    }

    // 3. Rate limit backoff aktifse bekle
    if (_rateLimitedUntil != null && DateTime.now().isBefore(_rateLimitedUntil!)) {
      final sn = _rateLimitedUntil!.difference(DateTime.now()).inSeconds;
      debugPrint('[TEFAS] Rate limit backoff: $sn sn kaldı.');
      return _memCache ?? [];
    }

    // 4. API'den çek
    final funds = await _fetchReturns();

    if (funds.isNotEmpty) {
      _memCache         = funds;
      _memCacheAt       = DateTime.now();
      _rateLimitedUntil = null;
      await _saveToDisk(funds);
      debugPrint('[TEFAS] ${funds.length} fon yüklendi ve diske kaydedildi.');
      return funds;
    }

    // 5. API başarısız — Firestore cache'ini dene (Cloud Functions tarafından dolduruluyor)
    final firestoreFunds = await _loadFromFirestore();
    if (firestoreFunds.isNotEmpty) {
      _memCache   = firestoreFunds;
      _memCacheAt = DateTime.now();
      debugPrint('[TEFAS] Firestore cache\'den ${firestoreFunds.length} fon yüklendi.');
      return firestoreFunds;
    }

    debugPrint('[TEFAS] API başarısız, mevcut önbellek kullanılıyor.');
    return _memCache ?? [];
  }

  // ── Firestore Cache (Cloud Functions tarafından yazılır) ─────────────────

  Future<List<TefasFund>> _loadFromFirestore() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('tefas_funds')
          .limit(500)
          .get(const GetOptions(source: Source.serverAndCache));
      if (snap.docs.isEmpty) return [];
      return snap.docs
          .map((d) => _parseItem(d.data()))
          .where((f) => f.code.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[TEFAS] Firestore okuma hatası: $e');
      return [];
    }
  }

  // ── /api/v1/funds/returns — getiri oranlarıyla birlikte ──────────────────

  Future<List<TefasFund>> _fetchReturns() async {
    try {
      // 1 yıllık getiri için 365 gün aralık
      // API cache TTL: 30 dk — günde birkaç kez sorgu yeterli
      final endDate   = _fmtDate(DateTime.now());
      final startDate = _fmtDate(DateTime.now().subtract(const Duration(days: 365)));

      final res = await _dio.get(
        '/api/v1/funds/returns',
        queryParameters: {
          'fundType':  'YAT',   // YAT = Yatırım Fonu (1 de çalışıyor)
          'startDate': startDate,
          'endDate':   endDate,
        },
        options: Options(headers: _headers),
      );

      return _parseResponse(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        // Rate limit — 5 dakika bekle
        _rateLimitedUntil = DateTime.now().add(_rateLimitBackoff);
        debugPrint('[TEFAS] 429 Rate limit, ${_rateLimitBackoff.inMinutes} dk sonra tekrar denenecek.');
      } else {
        debugPrint('[TEFAS] returns endpoint hatası: $e');
      }
      return [];
    } catch (e) {
      debugPrint('[TEFAS] returns endpoint hatası: $e');
      return [];
    }
  }

  // ── Disk Cache ────────────────────────────────────────────────────────────

  Future<void> _saveToDisk(List<TefasFund> funds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json  = jsonEncode(funds.map(_fundToJson).toList());
      await prefs.setString(_prefKeyData, json);
      await prefs.setInt(_prefKeyTime, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[TEFAS] Disk kayıt hatası: $e');
    }
  }

  Future<List<TefasFund>?> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts    = prefs.getInt(_prefKeyTime);
      if (ts == null) return null;

      final savedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(savedAt) >= _cacheDuration) return null;

      final json = prefs.getString(_prefKeyData);
      if (json == null) return null;

      final list = (jsonDecode(json) as List)
          .cast<Map<String, dynamic>>()
          .map(_parseItem)
          .toList();
      return list.isEmpty ? null : list;
    } catch (e) {
      debugPrint('[TEFAS] Disk okuma hatası: $e');
      return null;
    }
  }

  Map<String, dynamic> _fundToJson(TefasFund f) => {
    'fundCode':     f.code,
    'fundName':     f.name,
    'category':     f.type,
    'return1d':     f.dailyReturn,
    'return1m':     f.monthlyReturn,
    'return1y':     f.yearlyReturn,
  };

  // ── Parse ─────────────────────────────────────────────────────────────────

  static bool _isMemCacheValid() {
    if (_memCache == null || _memCacheAt == null) return false;
    return DateTime.now().difference(_memCacheAt!) < _cacheDuration;
  }

  List<TefasFund> _parseResponse(dynamic data) {
    List<dynamic> list;
    if (data is Map) {
      list = (data['data'] as List?) ??
             (data['result'] as List?) ??
             (data['funds'] as List?) ??
             [];
    } else if (data is List) {
      list = data;
    } else {
      return [];
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map(_parseItem)
        .where((f) => f.code.isNotEmpty)
        .toList();
  }

  TefasFund _parseItem(Map<String, dynamic> item) {
    // RapidAPI alanları: fundCode, fundName, fundType, category,
    //   return1d, return1w, return1m, return3m, return6m,
    //   returnYtd, return1y, return3y, return5y
    return TefasFund(
      code: _str(item['fundCode']  ?? item['code']    ?? item['FonKod']   ?? ''),
      name: _str(item['fundName']  ?? item['name']    ?? item['FonUnvan'] ?? ''),
      type: _str(item['category']  ?? item['fundType']?? item['FonTur']   ?? 'Fon'),
      currentPrice:  _dbl(item['price'] ?? item['BirimPayDegeri'] ?? 0),
      dailyReturn:   _dbl(item['return1d'] ?? item['GunlukGetiri'] ?? 0),
      monthlyReturn: _dbl(item['return1m'] ?? item['AylikGetiri']  ?? 0),
      yearlyReturn:  _dbl(item['return1y'] ?? item['BirYillikGetiri'] ?? 0),
    );
  }

  /// DD.MM.YYYY formatı
  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String _str(dynamic v) => v?.toString().trim() ?? '';

  double _dbl(dynamic v) {
    if (v == null) return 0;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0;
  }
}
