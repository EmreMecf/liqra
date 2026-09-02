import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TEFAS fon bilgisi
///
/// [currentPrice] TEFAS'ın ücretsiz ucunda BULUNMUYOR ve daima 0'dır.
/// Kullanıcı fon fiyatını "Varlık Ekle" ekranında elle girer.
class TefasFund {
  final String code;
  final String name;
  final String type;
  final double currentPrice;
  final double dailyReturn;
  final double monthlyReturn;
  final double yearlyReturn;

  /// 1–7 arası TEFAS risk değeri (0 = bilinmiyor)
  final int riskValue;

  /// YAT | EMK | BYF
  final String fundType;

  const TefasFund({
    required this.code,
    required this.name,
    required this.type,
    this.currentPrice  = 0,
    this.dailyReturn   = 0,
    this.monthlyReturn = 0,
    this.yearlyReturn  = 0,
    this.riskValue     = 0,
    this.fundType      = 'YAT',
  });
}

abstract interface class TefasDataSource {
  Future<List<TefasFund>> searchFunds(String query);
  Future<double?> getCurrentPrice(String code);
  Future<List<TefasFund>> getAllFunds();
}

/// TEFAS fon kataloğu — Firestore üzerinden.
///
/// ── Neden telefondan TEFAS'a istek atmıyoruz ────────────────────────────────
/// Eski uç (POST /api/DB/BindHistoryInfo) TEFAS tarafından KAPATILDI
/// (404, "Method not found or disabled!") ve site bot koruması arkasında.
/// Katalogu Cloud Functions (`fetchTefasFunds`, günlük 19:30) çeker ve
/// `tefas_funds/catalog` dökümanına yazar. İstemci yalnızca onu okur:
///   • tek doküman → kullanıcı başına 1 Firestore okuması
///   • bot korumasına takılmaz, ağ hatası yüzeyi küçük
///
/// Fiyat bilgisi katalogda yoktur (TEFAS ücretsiz uçta vermiyor).
class TefasDataSourceImpl implements TefasDataSource {
  // Bellek cache — katalog günde bir değişir
  static List<TefasFund>? _memCache;
  static DateTime?        _memCacheAt;
  static const _cacheDuration = Duration(hours: 12);

  // Disk cache anahtarları (çevrimdışı açılış için)
  static const _prefKeyData = 'tefas_funds_json';
  static const _prefKeyTime = 'tefas_funds_ts';

  static const _catalogDoc = 'tefas_funds/catalog';

  TefasDataSourceImpl();

  @override
  Future<List<TefasFund>> searchFunds(String query) async {
    if (query.trim().length < 2) return [];
    final all = await getAllFunds();
    if (all.isEmpty) return [];
    final q = query.toUpperCase().trim();
    // Arama filtresini arka planda çalıştır (2500+ fon)
    return compute(_filterFunds, _FilterParams(all, q));
  }

  /// TEFAS ücretsiz uçta birim pay değeri yok — daima null döner.
  /// Fiyat kullanıcı tarafından elle girilir.
  @override
  Future<double?> getCurrentPrice(String code) async => null;

  @override
  Future<List<TefasFund>> getAllFunds() async {
    // 1. Bellek cache
    if (_isMemCacheValid()) return _memCache!;

    // 2. Firestore kataloğu — kanonik kaynak
    final catalog = await _loadCatalog();
    if (catalog.isNotEmpty) {
      _memCache   = catalog;
      _memCacheAt = DateTime.now();
      await _saveToDisk(catalog);
      debugPrint('[TEFAS] Katalog: ${catalog.length} fon.');
      return catalog;
    }

    // 3. Çevrimdışı — disk cache
    final diskFunds = await _loadFromDisk();
    if (diskFunds != null && diskFunds.isNotEmpty) {
      _memCache   = diskFunds;
      _memCacheAt = DateTime.now();
      debugPrint('[TEFAS] Disk cache: ${diskFunds.length} fon.');
      return diskFunds;
    }

    debugPrint('[TEFAS] Fon kataloğu alınamadı.');
    return _memCache ?? [];
  }

  // ── Firestore Katalog ─────────────────────────────────────────────────────

  /// `tefas_funds/catalog` → { count, updatedAt, funds: [{c,n,t,r,k}] }
  Future<List<TefasFund>> _loadCatalog() async {
    try {
      final snap = await FirebaseFirestore.instance
          .doc(_catalogDoc)
          .get(const GetOptions(source: Source.serverAndCache));

      final raw = snap.data()?['funds'];
      if (raw is! List || raw.isEmpty) return [];

      final result = <TefasFund>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final code = (item['c'] as String? ?? '').toUpperCase();
        if (code.isEmpty) continue;
        result.add(TefasFund(
          code:      code,
          name:      item['n'] as String? ?? code,
          type:      item['t'] as String? ?? 'Fon',
          riskValue: (item['r'] as num?)?.toInt() ?? 0,
          fundType:  item['k'] as String? ?? 'YAT',
        ));
      }
      return result;
    } catch (e) {
      debugPrint('[TEFAS] Katalog okuma hatası: $e');
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

      final json = prefs.getString(_prefKeyData);
      if (json == null) return null;

      // Büyük JSON'u (2500+ fon) arka planda ayrıştır — UI thread'i bloklamaz
      final list = await compute(_decodeJsonToFunds, json);
      return list.isEmpty ? null : list;
    } catch (e) {
      debugPrint('[TEFAS] Disk okuma hatası: $e');
      return null;
    }
  }

  Map<String, dynamic> _fundToJson(TefasFund f) => {
    'c': f.code,
    'n': f.name,
    't': f.type,
    'r': f.riskValue,
    'k': f.fundType,
  };

  static bool _isMemCacheValid() {
    if (_memCache == null || _memCacheAt == null) return false;
    return DateTime.now().difference(_memCacheAt!) < _cacheDuration;
  }
}

// ── Isolate yardımcıları ─────────────────────────────────────────────────────

class _FilterParams {
  final List<TefasFund> funds;
  final String query;
  const _FilterParams(this.funds, this.query);
}

List<TefasFund> _filterFunds(_FilterParams p) {
  // Kod eşleşmesi isim eşleşmesinden önce gelsin
  final byCode = <TefasFund>[];
  final byName = <TefasFund>[];
  for (final f in p.funds) {
    if (f.code.toUpperCase().contains(p.query)) {
      byCode.add(f);
    } else if (f.name.toUpperCase().contains(p.query)) {
      byName.add(f);
    }
  }
  return [...byCode, ...byName].take(20).toList();
}

/// compute() ile çağrılır; 2500+ fon JSON'unu main thread'i bloklamadan ayrıştırır.
List<TefasFund> _decodeJsonToFunds(String json) {
  try {
    final raw = jsonDecode(json) as List;
    return raw
        .whereType<Map<String, dynamic>>()
        .map((m) => TefasFund(
              code:      (m['c'] as String? ?? '').toUpperCase(),
              name:      m['n'] as String? ?? '',
              type:      m['t'] as String? ?? 'Fon',
              riskValue: (m['r'] as num?)?.toInt() ?? 0,
              fundType:  m['k'] as String? ?? 'YAT',
            ))
        .where((f) => f.code.isNotEmpty)
        .toList();
  } catch (_) {
    return [];
  }
}
