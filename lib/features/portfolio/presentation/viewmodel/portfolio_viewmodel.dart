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

  static const _uuid = Uuid();

  /// Gerçek Firebase UID — boş ise oturum açılmamış
  String get _uid => AuthService.instance.userId ?? '';

  PortfolioViewModel({
    required GetPortfolioUseCase getPortfolio,
    required AddAssetUseCase     addAsset,
    required UpdateAssetUseCase  updateAsset,
    required DeleteAssetUseCase  deleteAsset,
  })  : _getPortfolio = getPortfolio,
        _addAsset     = addAsset,
        _updateAsset  = updateAsset,
        _deleteAsset  = deleteAsset;

  PortfolioState _state = const PortfolioState.initial();
  PortfolioState get state => _state;

  Future<void> load() async {
    final uid = _uid;
    if (uid.isEmpty) {
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
      success: (p) => _state = PortfolioState.loaded(portfolio: p),
      failure: (f) => _state = PortfolioState.error(message: f.message),
    );
    notifyListeners();
  }

  /// Yeni varlık ekler — gerçek kullanıcı UID ile Firestore'a yazar
  Future<String?> addAsset({
    required String type,
    required String name,
    required double quantity,
    required double buyPrice,
    double? currentPrice,
  }) async {
    final uid = _uid;
    if (uid.isEmpty) return 'Oturum açmanız gerekiyor.';

    final asset = AssetEntity(
      id:           _uuid.v4(),
      type:         type,
      name:         name,
      quantity:     quantity,
      buyPrice:     buyPrice,
      currentPrice: currentPrice ?? buyPrice,
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
      _state = PortfolioState.loaded(
        portfolio: PortfolioEntity(
          id:     portfolio.id,
          userId: portfolio.userId,
          assets: portfolio.assets.where((a) => a.id != assetId).toList(),
        ),
      );
      notifyListeners();
    }

    final uid = _uid;
    final result = await _deleteAsset(assetId: assetId, userId: uid);
    return result.when(
      success: (_) { load(); return null; },
      failure: (f) { load(); return f.message; },
    );
  }

  /// AI bağlamı için portföy özeti
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
}
