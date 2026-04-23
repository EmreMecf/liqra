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

/// TEFAS resmi sitesi entegrasyonu — direkt istek (CORS mobile'da engellenmez)
///
/// Endpoint: POST https://www.tefas.gov.tr/api/DB/BindHistoryInfo
/// Content-Type: application/x-www-form-urlencoded
/// Tarayıcı header'ları zorunlu — aksi halde 403/500 döner.
class TefasDataSourceImpl implements TefasDataSource {
  late final Dio _dio;

  // Bellek cache
  static List<TefasFund>? _memCache;
  static DateTime?        _memCacheAt;
  static DateTime?        _rateLimitedUntil;
  static const _cacheDuration    = Duration(hours: 4);
  static const _rateLimitBackoff = Duration(minutes: 10);

  // Disk cache anahtarları
  static const _prefKeyData = 'tefas_funds_json';
  static const _prefKeyTime = 'tefas_funds_ts';

  static const _baseUrl = 'https://www.tefas.gov.tr';

  // TEFAS'ın tarayıcı sandığı için zorunlu header'lar
  static Map<String, String> get _browserHeaders => {
    'User-Agent':       'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept':           'application/json, text/javascript, */*; q=0.01',
    'X-Requested-With': 'XMLHttpRequest',
    'Origin':           'https://www.tefas.gov.tr',
    'Referer':          'https://www.tefas.gov.tr/FonKarsilastirma.aspx',
  };

  TefasDataSourceImpl() {
    _dio = Dio(BaseOptions(
      baseUrl:        _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 25),
    ));
  }

  @override
  Future<List<TefasFund>> searchFunds(String query) async {
    if (query.trim().length < 2) return [];
    final all = await getAllFunds();
    if (all.isEmpty) return [];
    final q = query.toUpperCase().trim();
    // Arama filtresini arka planda çalıştır (büyük liste)
    return compute(_filterFunds, _FilterParams(all, q));
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

    // 3. Rate limit backoff aktifse
    if (_rateLimitedUntil != null && DateTime.now().isBefore(_rateLimitedUntil!)) {
      final sn = _rateLimitedUntil!.difference(DateTime.now()).inSeconds;
      debugPrint('[TEFAS] Rate limit backoff: $sn sn kaldı.');
      return _memCache ?? [];
    }

    // 4. TEFAS'tan direkt çek
    final funds = await _fetchFromTefas();

    if (funds.isNotEmpty) {
      _memCache         = funds;
      _memCacheAt       = DateTime.now();
      _rateLimitedUntil = null;
      await _saveToDisk(funds);
      debugPrint('[TEFAS] ${funds.length} fon yüklendi ve diske kaydedildi.');
      return funds;
    }

    // 5. Başarısız — Firestore cache'ini dene
    final firestoreFunds = await _loadFromFirestore();
    if (firestoreFunds.isNotEmpty) {
      _memCache   = firestoreFunds;
      _memCacheAt = DateTime.now();
      debugPrint('[TEFAS] Firestore cache\'den ${firestoreFunds.length} fon yüklendi.');
      return firestoreFunds;
    }

    debugPrint('[TEFAS] Tüm kaynaklar başarısız, mevcut önbellek kullanılıyor.');
    return _memCache ?? [];
  }

  // ── TEFAS Resmi API ───────────────────────────────────────────────────────

  Future<List<TefasFund>> _fetchFromTefas() async {
    try {
      final today     = _fmtDate(DateTime.now());
      final yesterday = _fmtDate(DateTime.now().subtract(const Duration(days: 1)));

      final response = await _dio.post(
        '/api/DB/BindHistoryInfo',
        data: {
          'fontip':   'YAT',
          'bastarih': yesterday,
          'bittarih': today,
        },
        options: Options(
          headers:     _browserHeaders,
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 429) {
        _rateLimitedUntil = DateTime.now().add(_rateLimitBackoff);
        debugPrint('[TEFAS] 429 Rate limit — ${_rateLimitBackoff.inMinutes} dk sonra tekrar denenecek.');
        return [];
      }

      debugPrint('[TEFAS] HTTP ${response.statusCode}');
      return _parseResponse(response.data);
    } on DioException catch (e) {
      debugPrint('[TEFAS] DioException: ${e.response?.statusCode} — ${e.message}');
      return [];
    } catch (e) {
      debugPrint('[TEFAS] Hata: $e');
      return [];
    }
  }

  // ── Firestore Cache ───────────────────────────────────────────────────────

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

      // Büyük JSON'u (3000+ fon) arka planda ayrıştır — UI thread'i bloklamaz
      final list = await compute(_decodeJsonToFunds, json);
      return list.isEmpty ? null : list;
    } catch (e) {
      debugPrint('[TEFAS] Disk okuma hatası: $e');
      return null;
    }
  }

  Map<String, dynamic> _fundToJson(TefasFund f) => {
    'fundCode':  f.code,
    'fundName':  f.name,
    'category':  f.type,
    'price':     f.currentPrice,
    'return1d':  f.dailyReturn,
    'return1m':  f.monthlyReturn,
    'return1y':  f.yearlyReturn,
  };

  // ── Parse ─────────────────────────────────────────────────────────────────

  static bool _isMemCacheValid() {
    if (_memCache == null || _memCacheAt == null) return false;
    return DateTime.now().difference(_memCacheAt!) < _cacheDuration;
  }

  List<TefasFund> _parseResponse(dynamic data) {
    List<dynamic> list;
    if (data is Map) {
      list = (data['data']   as List?) ??
             (data['result'] as List?) ??
             (data['funds']  as List?) ??
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
    // TEFAS resmi alanlar: FONKODU, FONUNVAN, FONTUR, BIRIMPAYDEGERI,
    // GUNLUK, AYLIK, YILLIK — veya küçük harf varyantları
    return TefasFund(
      code: _str(
        item['FONKODU']   ?? item['fundCode'] ?? item['code']    ?? '',
      ),
      name: _str(
        item['FONUNVAN']  ?? item['fundName'] ?? item['name']    ?? '',
      ),
      type: _str(
        item['FONTUR']    ?? item['category'] ?? item['fundType']?? 'Fon',
      ),
      currentPrice:  _dbl(item['BIRIMPAYDEGERI'] ?? item['price']    ?? 0),
      dailyReturn:   _dbl(item['GUNLUK']         ?? item['return1d'] ?? 0),
      monthlyReturn: _dbl(item['AYLIK']          ?? item['return1m'] ?? 0),
      yearlyReturn:  _dbl(item['YILLIK']         ?? item['return1y'] ?? 0),
    );
  }

  /// DD.MM.YYYY formatı — TEFAS'ın beklediği format
  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String _str(dynamic v) => v?.toString().trim() ?? '';

  double _dbl(dynamic v) {
    if (v == null) return 0;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0;
  }
}

// ── Isolate yardımcıları ─────────────────────────────────────────────────────

class _FilterParams {
  final List<TefasFund> funds;
  final String query;
  const _FilterParams(this.funds, this.query);
}

List<TefasFund> _filterFunds(_FilterParams p) {
  return p.funds
      .where((f) =>
          f.code.toUpperCase().contains(p.query) ||
          f.name.toUpperCase().contains(p.query))
      .take(20)
      .toList();
}

// ── Isolate fonksiyonu — JSON parse background'da çalışır ───────────────────
/// compute() ile çağrılır; ~3000+ fon JSON'unu main thread'i bloklamadan ayrıştırır.
List<TefasFund> _decodeJsonToFunds(String json) {
  try {
    final raw = jsonDecode(json) as List;
    return raw
        .cast<Map<String, dynamic>>()
        .map(_parseItemIsolate)
        .where((f) => f.code.isNotEmpty)
        .toList();
  } catch (_) {
    return [];
  }
}

TefasFund _parseItemIsolate(Map<String, dynamic> item) {
  double toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0;
  }
  String toStr(dynamic v) => v?.toString().trim() ?? '';
  return TefasFund(
    code:          toStr(item['FONKODU']        ?? item['fundCode'] ?? item['code']     ?? ''),
    name:          toStr(item['FONUNVAN']       ?? item['fundName'] ?? item['name']     ?? ''),
    type:          toStr(item['FONTUR']         ?? item['category'] ?? item['fundType'] ?? 'Fon'),
    currentPrice:  toDouble(item['BIRIMPAYDEGERI'] ?? item['price']    ?? 0),
    dailyReturn:   toDouble(item['GUNLUK']         ?? item['return1d'] ?? 0),
    monthlyReturn: toDouble(item['AYLIK']          ?? item['return1m'] ?? 0),
    yearlyReturn:  toDouble(item['YILLIK']         ?? item['return1y'] ?? 0),
  );
}
