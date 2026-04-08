import '../../../../core/utils/result.dart';
import '../entities/asset_entity.dart';
import '../repositories/portfolio_repository.dart';

class UpdateAssetUseCase {
  final PortfolioRepository _repository;
  const UpdateAssetUseCase(this._repository);

  Future<Result<void>> call({required AssetEntity asset}) =>
      _repository.updateAsset(asset);
}
