import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/gold_price_entity.dart';
import '../../domain/entities/market_data_entity.dart';
import '../../domain/usecases/get_market_data_usecase.dart';
import 'portfolio_state.dart';

/// Piyasa + Altın ViewModel
///
/// Firestore [market/live_prices] dökümanını dinler.
/// Cloud Functions her 1dk'da bir piyasa, 5dk'da bir altın günceller.
class MarketViewModel extends ChangeNotifier {
  final GetMarketDataUseCase _getMarketData;
  StreamSubscription<dynamic>? _priceSub;
  StreamSubscription<DocumentSnapshot>? _goldSub;
  StreamSubscription<User?>? _authSub;

  MarketViewModel({required GetMarketDataUseCase getMarketData})
      : _getMarketData = getMarketData {
    // Auth değişiminde stream'leri yönet
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        // Çıkış yapıldı — stream'leri durdur, state'i sıfırla
        _priceSub?.cancel();
        _priceSub = null;
        _goldSub?.cancel();
        _goldSub = null;
        _goldPrices = [];
        _state = const MarketState.initial();
        notifyListeners();
      } else if (_priceSub == null) {
        // Giriş yapıldı ve stream yoksa başlat
        load();
      }
    });
  }

  MarketState _state = const MarketState.initial();
  MarketState get state => _state;

  DateTime? _lastUpdated;
  DateTime? get lastUpdated => _lastUpdated;

  // ── Altın fiyatları ───────────────────────────────────────────────────────

  List<GoldPriceData> _goldPrices = [];
  List<GoldPriceData> get goldPrices => _goldPrices;
  DateTime? _goldLastUpdated;
  DateTime? get goldLastUpdated => _goldLastUpdated;

  // ── Başlat ────────────────────────────────────────────────────────────────

  Future<void> load() async {
    _state = const MarketState.loading();
    notifyListeners();

    // Piyasa verisi stream
    _priceSub?.cancel();
    _priceSub = _getMarketData.watch().listen(
      (data) {
        final currentFunds = _state.topFunds ?? const <TopFundEntity>[];
        _state       = MarketState.loaded(data: data, topFunds: currentFunds);
        _lastUpdated = DateTime.now();
        notifyListeners();
        if (_lastUpdated != null) _fetchTopFunds();
      },
      onError: (Object e) {
        _state = MarketState.error(
          message:   e.toString(),
          staleData: _state.marketData,
        );
        notifyListeners();
      },
    );

    // Altın fiyatı stream — aynı Firestore dökümanı
    _goldSub?.cancel();
    _goldSub = FirebaseFirestore.instance
        .doc('market/live_prices')
        .snapshots()
        .listen(
      (snap) {
        _goldPrices      = _parseGold(snap);
        _goldLastUpdated = DateTime.now();
        notifyListeners();
      },
      onError: (_) {}, // sessiz hata — mevcut veriyi koru
    );
  }

  /// Manuel yenileme
  Future<void> refresh() => _fetchTopFunds();

  Future<void> _fetchTopFunds() async {
    final fundsResult = await _getMarketData.topFunds();
    fundsResult.when(
      success: (funds) {
        _state = MarketState.loaded(data: _state.marketData, topFunds: funds);
        notifyListeners();
      },
      failure: (_) {},
    );
  }

  // ── Altın Parse ───────────────────────────────────────────────────────────

  static const _goldMeta = <String, (String, String, String, String, String)>{
    // code: (name, icon, unit, category, unitLabel)
    'gram':       ('Gram Altın',       '🥇', 'Gram',  'madeni', '1 gram'),
    'ceyrek':     ('Çeyrek Altın',     '🪙', 'Adet',  'madeni', '1.75 gr'),
    'yarim':      ('Yarım Altın',      '🪙', 'Adet',  'madeni', '3.5 gr'),
    'tam':        ('Tam Altın',        '🏅', 'Adet',  'madeni', '7 gr'),
    'cumhuriyet': ('Cumhuriyet Altını','🏅', 'Adet',  'madeni', '7 gr 22A'),
    'resat':      ('Reşat Altın',      '🏅', 'Adet',  'madeni', '7.3 gr'),
    'beslilik':   ('Beşlilik Altın',   '🏆', 'Adet',  'madeni', '35 gr'),
    'hamit':      ('Hamit Altın',      '🏅', 'Adet',  'madeni', '7.3 gr'),
    'bilezik22':  ('22 Ayar Altın',    '💛', 'gr/gr', 'bilezik','22 Ayar'),
    'bilezik18':  ('18 Ayar Altın',    '🟡', 'gr/gr', 'bilezik','18 Ayar'),
    'bilezik14':  ('14 Ayar Altın',    '🔶', 'gr/gr', 'bilezik','14 Ayar'),
    'gumus':      ('Gümüş',            '🥈', 'Gram',  'diger',  '1 gram'),
  };

  static const _bilezikCodes = {'bilezik22', 'bilezik18', 'bilezik14'};

  List<GoldPriceData> _parseGold(DocumentSnapshot snap) {
    if (!snap.exists) return [];
    final docData = snap.data() as Map<String, dynamic>?;
    final goldMap = docData?['gold'] as Map<String, dynamic>?;
    if (goldMap == null) return [];

    const order = [
      'gram', 'ceyrek', 'yarim', 'tam', 'cumhuriyet',
      'resat', 'beslilik', 'hamit',
      'bilezik22', 'bilezik18', 'bilezik14',
      'gumus',
    ];

    final result = <GoldPriceData>[];
    for (final code in order) {
      final meta = _goldMeta[code];
      if (meta == null) continue;

      final v         = goldMap[code];
      final isBilezik = _bilezikCodes.contains(code);

      double alis = 0, satis = 0;

      if (v is Map<String, dynamic>) {
        if (isBilezik) {
          alis  = _toDouble(v['alisgram']);
          satis = _toDouble(v['satisgram']);
        } else {
          alis  = _toDouble(v['alis']);
          satis = _toDouble(v['satis']);
        }
      }

      // Bilezik fiyatı Firestore'da yoksa veya 0 ise → gram altından hesapla
      if (isBilezik && alis <= 0 && satis <= 0) {
        final gramData  = goldMap['gram'] as Map<String, dynamic>?;
        final gramAlis  = _toDouble(gramData?['alis']);
        final gramSatis = _toDouble(gramData?['satis']);
        final gramPrice = gramAlis > 0 ? gramAlis : gramSatis;
        if (gramPrice > 0) {
          final ratio = switch (code) {
            'bilezik22' => 22.0 / 24.0,
            'bilezik18' => 18.0 / 24.0,
            'bilezik14' => 14.0 / 24.0,
            _           => 0.0,
          };
          if (ratio > 0) {
            alis  = gramPrice * ratio;
            satis = alis;
          }
        }
      }

      if (alis <= 0 && satis <= 0) continue;
      if (alis <= 0)  alis  = satis;
      if (satis <= 0) satis = alis;

      final data = v is Map<String, dynamic> ? v : null;
      result.add(GoldPriceData(
        code:         code,
        name:         meta.$1,
        icon:         meta.$2,
        unit:         meta.$3,
        alis:         alis,
        satis:        satis,
        degisim:      _toDouble(data?['degisim']),
        degisimTutar: _toDouble(data?['degisimTutar']),
        category:     meta.$4,
      ));
    }
    return result;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _priceSub?.cancel();
    _goldSub?.cancel();
    super.dispose();
  }
}
