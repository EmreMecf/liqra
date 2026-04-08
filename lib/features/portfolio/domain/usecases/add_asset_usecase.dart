import '../../../../core/utils/result.dart';
import '../entities/asset_entity.dart';
import '../repositories/portfolio_repository.dart';

class AddAssetUseCase {
  final PortfolioRepository _repository;
  const AddAssetUseCase(this._repository);

  Future<Result<AssetEntity>> call({
    required AssetEntity asset,
    required String userId,
  }) =>
      _repository.addAsset(asset, userId);
}
