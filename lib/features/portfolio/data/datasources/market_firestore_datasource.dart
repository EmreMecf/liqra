import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/asset_dto.dart';
import 'market_remote_datasource.dart';

/// Firestore tabanlı piyasa verisi kaynağı
///
/// Cloud Functions her 1 dakikada bir [market/live_prices] dökümanını günceller.
///
/// Firestore şeması:
/// {
///   prices: { "USDTRY": {price, changePercent, lastUpdated}, ... }
///   stocks: { "GARAN": {price, changePercent, name, currency, lastUpdated}, ... }
///   gold:   { "gram": {alis, satis, degisim, lastUpdated}, ... }
/// }
///
/// subLabel: kategori kodu olarak kullanılır (UI filtreleme için)
///   "doviz" | "emtia" | "bist100" | "kripto" | "bist"
class MarketFirestoreDataSource implements MarketRemoteDataSource {
  MarketFirestoreDataSource() : _db = FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  static const _docPath = 'market/live_prices';

  // Temel sembol meta: Firestore key → (displaySymbol, displayName, icon, category)
  // Döviz anahtarları: CollectAPI "USDTRY", "EURTRY" vb. yazar (=X suffix yok)
  static const Map<String, (String, String, String, String)> _meta = {
    'USDTRY':  ('USD/TRY', 'Dolar/TL',       '💵', 'doviz'),
    'EURTRY':  ('EUR/TRY', 'Euro/TL',        '💶', 'doviz'),
    'GBPTRY':  ('GBP/TRY', 'Sterlin/TL',     '💷', 'doviz'),
    'CHFTRY':  ('CHF/TRY', 'İsviçre Fr/TL',  '🇨🇭', 'doviz'),
    'XU100':   ('XU100',   'BIST100',        '📊', 'bist100'),
    'BTC_TRY': ('BTC/TRY', 'Bitcoin',        '₿',  'kripto'),
    'ETH_TRY': ('ETH/TRY', 'Ethereum',       '⟠',  'kripto'),
    'SOL_TRY': ('SOL/TRY', 'Solana',         '◎',  'kripto'),
    'BNB_TRY': ('BNB/TRY', 'BNB',            '🔶', 'kripto'),
    'XRP_TRY': ('XRP/TRY', 'XRP',            '✕',  'kripto'),
    'DOGE_TRY':('DOGE/TRY','Dogecoin',       '🐕', 'kripto'),
    'USDT_TRY':('USDT/TRY','Tether',         '💲', 'kripto'),
  };

  // BIST hisse ikonları
  static const Map<String, String> _bistIcons = {
    'GARAN': '🏦', 'BIMAS': '🛒', 'THYAO': '✈️', 'AKBNK': '🏦',
    'ASELS': '🛡️', 'EREGL': '⚙️', 'SISE':  '🔬', 'KCHOL': '🏭',
    'ISCTR': '🏦', 'SAHOL': '🏢', 'TCELL': '📱', 'ARCLK': '🏠',
    'FROTO': '🚗', 'KOZAL': '🥇', 'YKBNK': '🏦', 'TUPRS': '⛽',
    'TOASO': '🚙', 'PGSUS': '✈️', 'VESTL': '📺', 'SOKM':  '🛍️',
  };

  // ── Gerçek zamanlı stream ─────────────────────────────────────────────────

  @override
  Stream<List<MarketDataDto>> watchMarketData() =>
      _db.doc(_docPath).snapshots().map(_parseSnapshot);

  // ── Tek seferlik okuma ────────────────────────────────────────────────────

  @override
  Future<List<MarketDataDto>> getMarketData() async {
    final snap = await _db.doc(_docPath).get();
    return _parseSnapshot(snap);
  }

  // ── Parse ─────────────────────────────────────────────────────────────────

  List<MarketDataDto> _parseSnapshot(DocumentSnapshot snap) {
    if (!snap.exists) return const [];
    final docData = snap.data() as Map<String, dynamic>?;
    if (docData == null) return const [];

    final result = <MarketDataDto>[];

    // 1. Temel fiyatlar (döviz, emtia, BIST100, kripto)
    final prices = docData['prices'] as Map<String, dynamic>?;
    if (prices != null) {
      for (final entry in prices.entries) {
        final key   = entry.key;
        final value = entry.value;
        if (value is! Map<String, dynamic>) continue;

        final meta = _meta[key];
        if (meta == null) continue;

        final price = _toDouble(value['price']);
        if (price <= 0) continue;

        result.add(MarketDataDto(
          symbol:        meta.$1,
          name:          meta.$2,
          icon:          meta.$3,
          price:         price,
          changePercent: _toDouble(value['changePercent']),
          currency:      'TRY',
          subLabel:      meta.$4,
          lastUpdated:   value['lastUpdated'] as String?,
        ));
      }
    }

    // 2. BIST hisse senetleri
    final stocks = docData['stocks'] as Map<String, dynamic>?;
    if (stocks != null) {
      for (final entry in stocks.entries) {
        final code  = entry.key;
        final value = entry.value;
        if (value is! Map<String, dynamic>) continue;
        final price = _toDouble(value['price']);
        if (price <= 0) continue;
        result.add(MarketDataDto(
          symbol:        code,
          name:          (value['name'] as String?) ?? code,
          icon:          _bistIcons[code] ?? '📈',
          price:         price,
          changePercent: _toDouble(value['changePercent']),
          currency:      'TRY',
          subLabel:      'bist',
          lastUpdated:   value['lastUpdated'] as String?,
          volume:        _toDouble(value['hacim']),
        ));
      }
    }

    // 3. Altın (gold map) — CollectAPI: gram, ceyrek, yarim, tam, cumhuriyet...
    final goldMap = docData['gold'] as Map<String, dynamic>?;
    if (goldMap != null) {
      const goldMeta = <String, (String, String)>{
        'gram':        ('Gram Altın',       '🥇'),
        'ceyrek':      ('Çeyrek Altın',     '🪙'),
        'yarim':       ('Yarım Altın',      '🪙'),
        'tam':         ('Tam Altın',        '🥇'),
        'cumhuriyet':  ('Cumhuriyet Altını','🏅'),
        'resat':       ('Reşat Altın',      '🏅'),
        'ons':         ('Ons Altın',        '🥇'),
        'gumus':       ('Gümüş',            '🔘'),
        'bilezik22':   ('22 Ayar Altın',    '💛'),
        'bilezik18':   ('18 Ayar Altın',    '🟡'),
        'bilezik14':   ('14 Ayar Altın',    '🔶'),
      };

      double gramPrice = 0; // fallback hesaplama için

      for (final entry in goldMap.entries) {
        final key   = entry.key;
        final value = entry.value;
        if (value is! Map<String, dynamic>) continue;

        final meta = goldMeta[key];

        if (key.startsWith('bilezik')) {
          // bilezik22/18/14 → alisgram / satisgram alanlarını kullan
          final alis  = _toDouble(value['alisgram']);
          final satis = _toDouble(value['satisgram']);
          final price = alis > 0 ? alis : satis;
          if (price <= 0) continue;
          result.add(MarketDataDto(
            symbol:        key.toUpperCase(),
            name:          meta?.$1 ?? key,
            icon:          meta?.$2 ?? '💛',
            price:         price,
            changePercent: _toDouble(value['degisim']),
            currency:      'TRY',
            subLabel:      'emtia',
            lastUpdated:   value['lastUpdated'] as String?,
          ));
        } else {
          final alis  = _toDouble(value['alis']);
          final satis = _toDouble(value['satis']);
          final price = alis > 0 ? alis : satis;
          if (price <= 0) continue;
          if (key == 'gram') gramPrice = price;
          result.add(MarketDataDto(
            symbol:        key.toUpperCase(),
            name:          meta?.$1 ?? key,
            icon:          meta?.$2 ?? '🥇',
            price:         price,
            changePercent: _toDouble(value['degisim']),
            currency:      'TRY',
            subLabel:      'emtia',
            lastUpdated:   value['lastUpdated'] as String?,
          ));
        }
      }

      // Bilezik verileri Firestore'da yoksa gram altından hesapla
      if (gramPrice > 0) {
        const ayarlar = [
          ('bilezik22', '22 Ayar Altın', '💛', 22.0 / 24.0),
          ('bilezik18', '18 Ayar Altın', '🟡', 18.0 / 24.0),
          ('bilezik14', '14 Ayar Altın', '🔶', 14.0 / 24.0),
        ];
        final existingSymbols = result.map((d) => d.symbol).toSet();
        for (final (key, name, icon, ratio) in ayarlar) {
          if (!existingSymbols.contains(key.toUpperCase())) {
            result.add(MarketDataDto(
              symbol:        key.toUpperCase(),
              name:          name,
              icon:          icon,
              price:         gramPrice * ratio,
              changePercent: 0,
              currency:      'TRY',
              subLabel:      'hesaplama',
              lastUpdated:   null,
            ));
          }
        }
      }
    }

    // Sıralama: önce temel döviz, BIST100, altın, kripto, sonra hisseler
    const baseOrder = [
      'USD/TRY', 'EUR/TRY', 'GBP/TRY', 'CHF/TRY',
      'XU100',
      'GRAM', 'CEYREK', 'YARIM', 'TAM', 'ONS',
      'BTC/TRY', 'ETH/TRY', 'SOL/TRY', 'BNB/TRY', 'XRP/TRY', 'DOGE/TRY', 'USDT/TRY',
    ];
    result.sort((a, b) {
      final ai = baseOrder.indexOf(a.symbol);
      final bi = baseOrder.indexOf(b.symbol);
      if (ai >= 0 && bi >= 0) return ai.compareTo(bi);
      if (ai >= 0) return -1; // a önce
      if (bi >= 0) return 1;  // b önce
      return a.symbol.compareTo(b.symbol);
    });

    return result;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
