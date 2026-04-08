import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/asset_dto.dart';
import 'market_remote_datasource.dart';

/// Firestore tabanlı piyasa verisi kaynağı
///
/// Cloud Functions her 1 dakikada bir [market/live_prices] dökümanını günceller.
///
/// Firestore şeması:
/// {
///   prices:    { "USDTRY=X": {price, changePercent, lastUpdated}, ... }
///   stocks:    { "GARAN": {price, changePercent, name, currency, lastUpdated}, ... }
///   us_stocks: { "AAPL": {priceUsd, priceTry, changePercent, name, currency, lastUpdated}, ... }
/// }
///
/// subLabel: kategori kodu olarak kullanılır (UI filtreleme için)
///   "doviz" | "emtia" | "bist100" | "kripto" | "bist" | "abd"
class MarketFirestoreDataSource implements MarketRemoteDataSource {
  MarketFirestoreDataSource() : _db = FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  static const _docPath = 'market/live_prices';

  // Temel sembol meta: Firestore key → (displaySymbol, displayName, icon, category)
  static const Map<String, (String, String, String, String)> _meta = {
    'USDTRY=X':    ('USD/TRY', 'Dolar/TL',    '💵', 'doviz'),
    'EURTRY=X':    ('EUR/TRY', 'Euro/TL',     '💶', 'doviz'),
    'GBPTRY=X':    ('GBP/TRY', 'Sterlin/TL',  '💷', 'doviz'),
    'CHFTRY=X':    ('CHF/TRY', 'İsviçre Fr/TL','🇨🇭','doviz'),
    'XAU_GRAM_TRY':('XAU/TRY', 'Gram Altın',  '🥇', 'emtia'),
    'XU100':       ('XU100',   'BIST100',     '📊', 'bist100'),
    'BTC_TRY':     ('BTC/TRY', 'Bitcoin',     '₿',  'kripto'),
    'ETH_TRY':     ('ETH/TRY', 'Ethereum',    '⟠',  'kripto'),
    'SOL_TRY':     ('SOL/TRY', 'Solana',      '◎',  'kripto'),
    'BNB_TRY':     ('BNB/TRY', 'BNB',         '🔶', 'kripto'),
    'XRP_TRY':     ('XRP/TRY', 'XRP',         '✕',  'kripto'),
    'DOGE_TRY':    ('DOGE/TRY','Dogecoin',    '🐕', 'kripto'),
  };

  // BIST hisse ikonları
  static const Map<String, String> _bistIcons = {
    'GARAN': '🏦', 'BIMAS': '🛒', 'THYAO': '✈️', 'AKBNK': '🏦',
    'ASELS': '🛡️', 'EREGL': '⚙️', 'SISE':  '🔬', 'KCHOL': '🏭',
    'ISCTR': '🏦', 'SAHOL': '🏢', 'TCELL': '📱', 'ARCLK': '🏠',
    'FROTO': '🚗', 'KOZAL': '🥇', 'YKBNK': '🏦', 'TUPRS': '⛽',
    'TOASO': '🚙', 'PGSUS': '✈️', 'VESTL': '📺', 'SOKM':  '🛍️',
  };

  // ABD hisse ikonları
  static const Map<String, String> _usIcons = {
    'AAPL': '🍎', 'TSLA': '⚡', 'NVDA': '🟢', 'MSFT': '🪟',
    'AMZN': '📦', 'META': '👓', 'GOOGL': '🔍', 'BRK-B': '💼',
    'JPM':  '🏦', 'V':   '💳',
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
        ));
      }
    }

    // 3. ABD hisseleri
    final usStocks = docData['us_stocks'] as Map<String, dynamic>?;
    if (usStocks != null) {
      for (final entry in usStocks.entries) {
        final sym   = entry.key;
        final value = entry.value;
        if (value is! Map<String, dynamic>) continue;
        final priceUsd = _toDouble(value['priceUsd']);
        if (priceUsd <= 0) continue;
        result.add(MarketDataDto(
          symbol:        sym,
          name:          (value['name'] as String?) ?? sym,
          icon:          _usIcons[sym] ?? '🇺🇸',
          price:         priceUsd,
          changePercent: _toDouble(value['changePercent']),
          currency:      'USD',
          subLabel:      'abd',
          lastUpdated:   value['lastUpdated'] as String?,
        ));
      }
    }

    // Sıralama: önce temel döviz, sonra BIST100, sonra emtia, kripto
    const baseOrder = [
      'USD/TRY', 'EUR/TRY', 'GBP/TRY', 'CHF/TRY',
      'XAU/TRY', 'XU100',
      'BTC/TRY', 'ETH/TRY', 'SOL/TRY', 'BNB/TRY', 'XRP/TRY', 'DOGE/TRY',
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
