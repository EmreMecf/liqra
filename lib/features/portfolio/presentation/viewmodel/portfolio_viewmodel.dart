import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/auth_service.dart';
import '../../domain/entities/asset_entity.dart';
import '../../domain/usecases/get_portfolio_usecase.dart';
import '../../domain/usecases/add_asset_usecase.dart';
import '../../domain/usecases/update_asset_usecase.dart';
import '../../domain/usecases/delete_asset_usecase.dart';
import 'portfolio_state.dart';

class PortfolioViewModel extends ChangeNotifier {
  final GetPortfolioUseCase _getPortfolio;
  final AddAssetUseCase     _addAsset;
  final UpdateAssetUseCase  _updateAsset;
  final DeleteAssetUseCase  _deleteAsset;

  static const _uuid    = Uuid();
  static const _mktDoc  = 'market/live_prices';

  String get _uid => AuthService.instance.userId ?? '';

  /// Firestore'dan gelen canlı fiyat haritası
  Map<String, dynamic> _liveData = {};

  /// market/live_prices stream aboneliği
  StreamSubscription<DocumentSnapshot>? _marketSub;
  StreamSubscription<User?>? _authSub;

  /// Son yüklenen ham portföy (fiyat uygulanmadan önce)
  List<AssetEntity> _rawAssets = [];

  PortfolioViewModel({
    required GetPortfolioUseCase getPortfolio,
    required AddAssetUseCase     addAsset,
    required UpdateAssetUseCase  updateAsset,
    required DeleteAssetUseCase  deleteAsset,
  })  : _getPortfolio = getPortfolio,
        _addAsset     = addAsset,
        _updateAsset  = updateAsset,
        _deleteAsset  = deleteAsset {
    _startMarketSync();
    // Çıkış yapıldığında stream'i durdur, portföyü sıfırla
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _marketSub?.cancel();
        _marketSub = null;
        _rawAssets = [];
        _liveData = {};
        _state = const PortfolioState.initial();
        notifyListeners();
      } else if (_marketSub == null) {
        _startMarketSync();
      }
    });
  }

  PortfolioState _state = const PortfolioState.initial();
  PortfolioState get state => _state;

  /// Yüklü portföy varlıkları (kolay erişim için kısayol)
  List<AssetEntity> get assets {
    final s = _state;
    return s is PortfolioLoaded ? s.portfolio.assets : const [];
  }

  // ── Market Sync ─────────────────────────────────────────────────────────────

  /// market/live_prices dökümanını dinler; her güncellemede portföy fiyatlarını yeniler.
  void _startMarketSync() {
    _marketSub?.cancel();
    _marketSub = FirebaseFirestore.instance
        .doc(_mktDoc)
        .snapshots()
        .listen(
      (snap) {
        if (!snap.exists) return;
        final data = snap.data();
        _liveData = (data is Map<String, dynamic>) ? data : {};
        _rebuildWithLivePrices();
      },
      onError: (_) {}, // market verisi herkese açık — sessizce yoksay
    );
  }

  /// Ham asset listesine canlı fiyatları uygular, state'i günceller.
  void _rebuildWithLivePrices() {
    if (_rawAssets.isEmpty) return;

    final updated = _rawAssets.map((a) {
      final price = _resolvePrice(a);
      if (price > 0 && price != a.currentPrice) {
        return a.copyWith(currentPrice: price);
      }
      return a;
    }).toList();

    final portfolio = _state.portfolio;
    if (portfolio == null) return;

    _state = PortfolioState.loaded(
      portfolio: portfolio.copyWith(assets: updated),
    );
    notifyListeners();
  }

  /// priceSection + priceKey'e göre canlı fiyat döndürür. 0 = bulunamadı.
  double _resolvePrice(AssetEntity a) {
    final section = a.priceSection;
    final key     = a.priceKey;
    if (section == null || key == null || _liveData.isEmpty) return 0;

    try {
      switch (section) {
        case 'stocks':
          final map = _liveData['stocks'] as Map<String, dynamic>?;
          return _toDouble((map?[key] as Map?)? ['price']);

        case 'prices':
          final map = _liveData['prices'] as Map<String, dynamic>?;
          return _toDouble((map?[key] as Map?)? ['price']);

        case 'gold':
          final map   = _liveData['gold'] as Map<String, dynamic>?;
          final entry = map?[key] as Map<String, dynamic>?;
          if (entry != null) {
            if (key.startsWith('bilezik')) {
              // 22/18/14 ayar → alisgram / satisgram
              final alis  = _toDouble(entry['alisgram']);
              final satis = _toDouble(entry['satisgram']);
              if (alis > 0 || satis > 0) return alis > 0 ? alis : satis;
            } else {
              final alis  = _toDouble(entry['alis']);
              final satis = _toDouble(entry['satis']);
              if (alis > 0 || satis > 0) return alis > 0 ? alis : satis;
            }
          }
          // Fallback: bilezik verisi yoksa gram altından hesapla
          if (key.startsWith('bilezik')) {
            final gramEntry = map?['gram'] as Map<String, dynamic>?;
            final gramAlis  = _toDouble(gramEntry?['alis']);
            final gramSatis = _toDouble(gramEntry?['satis']);
            final gramPrice = gramAlis > 0 ? gramAlis : gramSatis;
            if (gramPrice > 0) {
              final ratio = switch (key) {
                'bilezik22' => 22.0 / 24.0,
                'bilezik18' => 18.0 / 24.0,
                'bilezik14' => 14.0 / 24.0,
                _           => 0.0,
              };
              if (ratio > 0) return gramPrice * ratio;
            }
          }
          return 0;

        case 'funds':
          final map = _liveData['funds'] as Map<String, dynamic>?;
          return _toDouble((map?[key] as Map?)? ['price']);
      }
    } catch (_) {}
    return 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  // ── Portfolio Load ───────────────────────────────────────────────────────────

  Future<void> load() async {
    final uid = _uid;
    if (uid.isEmpty) {
      _rawAssets = [];
      _state = PortfolioState.loaded(
        portfolio: PortfolioEntity(id: 'empty', userId: '', assets: []),
      );
      notifyListeners();
      return;
    }

    _state = const PortfolioState.loading();
    notifyListeners();

    final result = await _getPortfolio(userId: uid);
    result.when(
      success: (p) {
        _rawAssets = p.assets;
        // Canlı fiyatları hemen uygula
        final livePriced = p.assets.map((a) {
          final price = _resolvePrice(a);
          return price > 0 ? a.copyWith(currentPrice: price) : a;
        }).toList();
        _state = PortfolioState.loaded(
          portfolio: p.copyWith(assets: livePriced),
        );
      },
      failure: (f) => _state = PortfolioState.error(message: f.message),
    );
    notifyListeners();
  }

  // ── CRUD ────────────────────────────────────────────────────────────────────

  /// Yeni varlık ekler.
  /// [priceKey] + [priceSection] ile canlı fiyat bağlantısı kurulur.
  Future<String?> addAsset({
    required String type,
    required String name,
    required double quantity,
    required double buyPrice,
    double?  currentPrice,
    String?  priceSection,
    String?  priceKey,
  }) async {
    final uid = _uid;
    if (uid.isEmpty) return 'Oturum açmanız gerekiyor.';

    // Canlı fiyat varsa onu kullan, yoksa alış fiyatı
    double livePrice = 0;
    if (priceSection != null && priceKey != null) {
      final tmp = AssetEntity(
        id: '', type: type, name: name,
        quantity: 1, buyPrice: buyPrice,
        currentPrice: 0,
        priceSection: priceSection,
        priceKey: priceKey,
      );
      livePrice = _resolvePrice(tmp);
    }

    final asset = AssetEntity(
      id:           _uuid.v4(),
      type:         type,
      name:         name,
      quantity:     quantity,
      buyPrice:     buyPrice,
      currentPrice: livePrice > 0 ? livePrice : (currentPrice ?? buyPrice),
      priceSection: priceSection,
      priceKey:     priceKey,
    );

    final result = await _addAsset(asset: asset, userId: uid);
    return result.when(
      success: (_) { load(); return null; },
      failure: (f)  => f.message,
    );
  }

  /// Varlık günceller
  Future<String?> updateAsset(AssetEntity updated) async {
    final result = await _updateAsset(asset: updated);
    return result.when(
      success: (_) { load(); return null; },
      failure: (f)  => f.message,
    );
  }

  /// Optimistik silme
  Future<String?> deleteAsset(String assetId) async {
    final portfolio = _state.portfolio;
    if (portfolio != null) {
      _rawAssets = _rawAssets.where((a) => a.id != assetId).toList();
      _state = PortfolioState.loaded(
        portfolio: PortfolioEntity(
          id:     portfolio.id,
          userId: portfolio.userId,
          assets: portfolio.assets.where((a) => a.id != assetId).toList(),
        ),
      );
      notifyListeners();
    }

    final uid    = _uid;
    final result = await _deleteAsset(assetId: assetId, userId: uid);
    return result.when(
      success: (_) { load(); return null; },
      failure: (f) { load(); return f.message; },
    );
  }

  // ── AI Özeti ────────────────────────────────────────────────────────────────

  String buildPortfolioSummary() {
    final p = _state.portfolio;
    if (p == null || p.assets.isEmpty) return 'Portföy verisi yok.';

    final assetLines = p.assets.map((a) =>
      '${a.name}: ${a.totalValue.toStringAsFixed(0)} TL'
      ' (${a.gainLossPercent >= 0 ? "+" : ""}${a.gainLossPercent.toStringAsFixed(1)}%)'
    ).join(', ');

    return 'Toplam: ${p.totalValue.toStringAsFixed(0)} TL, '
        'G/K: ${p.totalGainLoss >= 0 ? "+" : ""}${p.totalGainLoss.toStringAsFixed(0)} TL. '
        'Varlıklar: $assetLines';
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _marketSub?.cancel();
    super.dispose();
  }
}
