import 'package:dio/dio.dart';
import '../../../../core/services/feature_flag_service.dart';
import '../models/asset_dto.dart';

abstract class MarketRemoteDataSource {
  Future<List<MarketDataDto>> getMarketData();

  /// Gerçek zamanlı piyasa verisi stream'i.
  /// Varsayılan implementasyon getMarketData()'yı bir kez çağırır.
  /// Firestore implementasyonu onSnapshot kullanır.
  Stream<List<MarketDataDto>> watchMarketData() =>
      Stream.fromFuture(getMarketData());
}

/// Gerçek zamanlı piyasa verileri:
///
/// • Gram Altın + USD/TRY + EUR/TRY → CollectAPI  (api key: Remote Config veya --dart-define=COLLECT_API_KEY=xxx)
/// • BTC/TRY + ETH/TRY              → Binance API (ücretsiz, auth yok)
/// • BIST100                        → Yahoo Finance (ücretsiz, auth yok)
///
/// CollectAPI endpoints:
///   GET https://api.collectapi.com/economy/goldPrice              → gram altın TL
///   GET https://api.collectapi.com/economy/currencyToAll?from=USD → döviz kurları
///
/// API key alma:
///   flutter run --dart-define=COLLECT_API_KEY=apikey_XXXXXXXXXXXXXXXX
class MarketRemoteDataSourceImpl extends MarketRemoteDataSource {
  late final Dio _collect;
  late final Dio _binance;
  late final Dio _yahoo;

  // ignore: avoid_unused_constructor_parameters
  MarketRemoteDataSourceImpl(Dio _) {
    const t = Duration(seconds: 10);
    _collect = Dio(BaseOptions(
      baseUrl:        'https://api.collectapi.com',
      connectTimeout: t,
      receiveTimeout: t,
    ));
    _binance = Dio(BaseOptions(
      baseUrl:        'https://api.binance.com',
      connectTimeout: t,
      receiveTimeout: t,
    ));
    _yahoo = Dio(BaseOptions(
      baseUrl:        'https://query1.finance.yahoo.com',
      connectTimeout: t,
      receiveTimeout: t,
      headers: {'User-Agent': 'Mozilla/5.0'},
    ));
  }

  /// CollectAPI key önceliği: build-time dart-define → Firebase Remote Config
  String get _collectKey {
    const envKey = String.fromEnvironment('COLLECT_API_KEY');
    if (envKey.isNotEmpty) return envKey;
    return FeatureFlagService.instance.getString('collectapi_key');
  }

  @override
  Future<List<MarketDataDto>> getMarketData() async {
    final results = await Future.wait([
      _fetchCollect().catchError((_) => <MarketDataDto>[]),
      _fetchBinance().catchError((_) => <MarketDataDto>[]),
      _fetchBist100().catchError((_) => <MarketDataDto>[]),
      _fetchYahooFx().catchError((_) => <MarketDataDto>[]),
    ]);

    // Öncelik: CollectAPI > Yahoo Finance (döviz/altın için)
    final collectItems = results[0];
    final binanceItems = results[1];
    final bistItems    = results[2];
    final yahooItems   = results[3];

    // Hangi sembollerin CollectAPI'den geldiğini bul
    final collectSymbols = collectItems.map((e) => e.symbol).toSet();

    // Yahoo'dan sadece CollectAPI'nin kapsamadığı sembolleri al
    final yahooFiltered = yahooItems
        .where((e) => !collectSymbols.contains(e.symbol))
        .toList();

    final all = [...collectItems, ...binanceItems, ...bistItems, ...yahooFiltered];
    if (all.isEmpty) return _mockData();

    // Sembole göre deduplicate (ilk kazanır)
    final seen = <String>{};
    return all.where((e) => seen.add(e.symbol)).toList();
  }

  // ── CollectAPI: Altın + USD/TRY + EUR/TRY ────────────────────────────────

  Future<List<MarketDataDto>> _fetchCollect() async {
    if (_collectKey.isEmpty) {
      // API key yoksa Binance'den USD/EUR almayı dene
      return _fetchFxFromBinance();
    }

    final headers = {
      'authorization': 'apikey $_collectKey',
      'content-type':  'application/json',
    };

    final futures = await Future.wait([
      _collect.get('/economy/goldPrice',
          options: Options(headers: headers)).catchError((_) => null),
      _collect.get('/economy/currencyToAll',
          queryParameters: {'from': 'USD'},
          options: Options(headers: headers)).catchError((_) => null),
    ]);

    final goldResp     = futures[0];
    final currencyResp = futures[1];

    final now    = DateTime.now().toIso8601String();
    final result = <MarketDataDto>[];

    // Gram Altın
    if (goldResp != null) {
      final data = goldResp.data;
      final list = (data is Map ? data['result'] : null) as List?;
      if (list != null) {
        // "Gram" key'ini bul
        for (final item in list) {
          if (item is Map) {
            final name = (item['name'] ?? item['isim'] ?? '').toString();
            if (name.toLowerCase().contains('gram') &&
                !name.toLowerCase().contains('çeyrek') &&
                !name.toLowerCase().contains('yarim') &&
                !name.toLowerCase().contains('tam')) {
              final buying  = _n(item['buying']  ?? item['alis']   ?? 0);
              final selling = _n(item['selling'] ?? item['satis']  ?? buying);
              final price   = (buying + selling) / 2;
              if (price > 0) {
                result.add(MarketDataDto(
                  symbol: 'XAU/TRY', name: 'Gram Altın', icon: '🥇',
                  price: price, changePercent: 0,
                  currency: 'TRY', subLabel: 'CollectAPI',
                  lastUpdated: now,
                ));
                break;
              }
            }
          }
        }
      }
    }

    // USD/TRY + EUR/TRY
    if (currencyResp != null) {
      final data = currencyResp.data;
      final list = (data is Map ? data['result'] : null) as List?;
      if (list != null) {
        for (final item in list) {
          if (item is Map) {
            final code = (item['code'] ?? item['code_'] ?? '').toString().toUpperCase();
            final rate = _n(item['rate'] ?? item['calculateAmount'] ?? 0);
            if (rate <= 0) continue;
            if (code == 'TRY') {
              result.add(MarketDataDto(
                symbol: 'USD/TRY', name: 'Dolar/TL', icon: '💵',
                price: rate, changePercent: 0,
                currency: 'TRY', subLabel: 'CollectAPI',
                lastUpdated: now,
              ));
            } else if (code == 'EUR') {
              result.add(MarketDataDto(
                symbol: 'EUR/TRY', name: 'Euro/TL', icon: '💶',
                price: rate, changePercent: 0,
                currency: 'TRY', subLabel: 'CollectAPI',
                lastUpdated: now,
              ));
            }
          }
        }
      }
    }

    // CollectAPI başarısız olduysa Binance'e fall back
    if (result.isEmpty) return _fetchFxFromBinance();
    return result;
  }

  // ── Binance: BTC/TRY + ETH/TRY (+ USD+EUR fallback) ─────────────────────

  Future<List<MarketDataDto>> _fetchBinance() async {
    final symbols = '["BTCTRY","ETHTRY"]';
    final res = await _binance.get(
      '/api/v3/ticker/24hr',
      queryParameters: {'symbols': symbols},
    );

    final list = (res.data as List).cast<Map<String, dynamic>>();
    final map  = {for (final e in list) e['symbol'] as String: e};

    final now   = DateTime.now().toIso8601String();
    final items = <MarketDataDto>[];

    final btcTry = _n(map['BTCTRY']?['lastPrice']);
    final ethTry = _n(map['ETHTRY']?['lastPrice']);
    final btcChg = _n(map['BTCTRY']?['priceChangePercent']);
    final ethChg = _n(map['ETHTRY']?['priceChangePercent']);

    if (btcTry > 0) items.add(MarketDataDto(
      symbol: 'BTC/TRY', name: 'Bitcoin/TL', icon: '₿',
      price: btcTry, changePercent: btcChg,
      currency: 'TRY', subLabel: 'Binance',
      lastUpdated: now,
    ));
    if (ethTry > 0) items.add(MarketDataDto(
      symbol: 'ETH/TRY', name: 'Ethereum/TL', icon: '⟠',
      price: ethTry, changePercent: ethChg,
      currency: 'TRY', subLabel: 'Binance',
      lastUpdated: now,
    ));
    return items;
  }

  // ── Yahoo Finance: USD/TRY + EUR/TRY + Gram Altın (ücretsiz) ────────────

  Future<List<MarketDataDto>> _fetchYahooFx() async {
    // GC=F: Altın vadeli ($/oz), USDTRY=X: USD/TRY, EURTRY=X: EUR/TRY
    final res = await _yahoo.get(
      '/v7/finance/quote',
      queryParameters: {'symbols': 'GC=F,USDTRY=X,EURTRY=X'},
    );

    final quoteList = ((res.data as Map)['quoteResponse']?['result'] as List?) ?? [];
    final map = <String, Map>{};
    for (final q in quoteList) {
      if (q is Map) map[q['symbol'] as String? ?? ''] = q;
    }

    final now    = DateTime.now().toIso8601String();
    final result = <MarketDataDto>[];

    // USD/TRY
    final usdData = map['USDTRY=X'];
    final usdRate = _n(usdData?['regularMarketPrice']);
    final usdChg  = _n(usdData?['regularMarketChangePercent']);
    if (usdRate > 0) {
      result.add(MarketDataDto(
        symbol: 'USD/TRY', name: 'Dolar/TL', icon: '💵',
        price: usdRate, changePercent: usdChg,
        currency: 'TRY', subLabel: 'Yahoo Finance',
        lastUpdated: now,
      ));
    }

    // EUR/TRY
    final eurData = map['EURTRY=X'];
    final eurRate = _n(eurData?['regularMarketPrice']);
    final eurChg  = _n(eurData?['regularMarketChangePercent']);
    if (eurRate > 0) {
      result.add(MarketDataDto(
        symbol: 'EUR/TRY', name: 'Euro/TL', icon: '💶',
        price: eurRate, changePercent: eurChg,
        currency: 'TRY', subLabel: 'Yahoo Finance',
        lastUpdated: now,
      ));
    }

    // Gram Altın: GC=F ($/oz) → TL/gram
    final goldData = map['GC=F'];
    final goldUsd  = _n(goldData?['regularMarketPrice']); // $/troy oz
    final goldChg  = _n(goldData?['regularMarketChangePercent']);
    if (goldUsd > 0 && usdRate > 0) {
      // troy oz → gram: 1 troy oz = 31.1035 gram
      final goldTry = (goldUsd / 31.1035) * usdRate;
      result.add(MarketDataDto(
        symbol: 'XAU/TRY', name: 'Gram Altın', icon: '🥇',
        price: goldTry, changePercent: goldChg,
        currency: 'TRY', subLabel: 'Yahoo Finance',
        lastUpdated: now,
      ));
    }

    return result;
  }

  // ── Yahoo Finance: BIST100 (ücretsiz) ────────────────────────────────────

  Future<List<MarketDataDto>> _fetchBist100() async {
    final res = await _yahoo.get(
      '/v8/finance/chart/XU100.IS',
      queryParameters: {'interval': '1d', 'range': '2d'},
    );
    final meta = ((res.data as Map)['chart']?['result'] as List?)?.first?['meta'];
    if (meta == null) return [];

    final price = _n(meta['regularMarketPrice']);
    final prev  = _n(meta['chartPreviousClose']);
    if (price <= 0) return [];

    final change = prev > 0 ? ((price - prev) / prev) * 100 : 0.0;
    return [
      MarketDataDto(
        symbol: 'XU100', name: 'BIST100', icon: '📊',
        price: price, changePercent: change,
        currency: 'TRY', subLabel: 'Yahoo Finance',
        lastUpdated: DateTime.now().toIso8601String(),
      ),
    ];
  }

  /// CollectAPI key yoksa Binance'den USD/TRY + EUR/TRY fallback
  Future<List<MarketDataDto>> _fetchFxFromBinance() async {
    try {
      final symbols = '["USDTTRY","EURUSDT"]';
      final res = await _binance.get(
        '/api/v3/ticker/24hr',
        queryParameters: {'symbols': symbols},
      );
      final list = (res.data as List).cast<Map<String, dynamic>>();
      final map  = {for (final e in list) e['symbol'] as String: e};

      final usdtTry = _n(map['USDTTRY']?['lastPrice']);
      final eurUsdt = _n(map['EURUSDT']?['lastPrice']);
      final usdChg  = _n(map['USDTTRY']?['priceChangePercent']);
      final eurChg  = _n(map['EURUSDT']?['priceChangePercent']);
      final eurTry  = (eurUsdt > 0 && usdtTry > 0) ? eurUsdt * usdtTry : 0.0;

      final now = DateTime.now().toIso8601String();
      final items = <MarketDataDto>[];
      if (usdtTry > 0) items.add(MarketDataDto(
        symbol: 'USD/TRY', name: 'Dolar/TL', icon: '💵',
        price: usdtTry, changePercent: usdChg,
        currency: 'TRY', subLabel: 'Binance',
        lastUpdated: now,
      ));
      if (eurTry > 0) items.add(MarketDataDto(
        symbol: 'EUR/TRY', name: 'Euro/TL', icon: '💶',
        price: eurTry, changePercent: eurChg,
        currency: 'TRY', subLabel: 'Binance',
        lastUpdated: now,
      ));
      return items;
    } catch (_) {
      return [];
    }
  }

  // ── Yardımcı ─────────────────────────────────────────────────────────────

  double _n(dynamic v) {
    if (v == null) return 0;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static List<MarketDataDto> _mockData() => const [
    MarketDataDto(symbol: 'XAU/TRY', name: 'Gram Altın',  icon: '🥇', price: 4100,    changePercent: 0, currency: 'TRY', subLabel: 'mock'),
    MarketDataDto(symbol: 'USD/TRY', name: 'Dolar/TL',    icon: '💵', price: 39.0,    changePercent: 0, currency: 'TRY', subLabel: 'mock'),
    MarketDataDto(symbol: 'EUR/TRY', name: 'Euro/TL',     icon: '💶', price: 42.5,    changePercent: 0, currency: 'TRY', subLabel: 'mock'),
    MarketDataDto(symbol: 'BTC/TRY', name: 'Bitcoin/TL',  icon: '₿',  price: 3800000, changePercent: 0, currency: 'TRY', subLabel: 'mock'),
    MarketDataDto(symbol: 'ETH/TRY', name: 'Ethereum/TL', icon: '⟠',  price: 180000,  changePercent: 0, currency: 'TRY', subLabel: 'mock'),
  ];
}
