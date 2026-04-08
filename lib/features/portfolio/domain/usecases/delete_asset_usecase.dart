import '../../../../core/utils/result.dart';
import '../repositories/portfolio_repository.dart';

class DeleteAssetUseCase {
  final PortfolioRepository _repository;
  const DeleteAssetUseCase(this._repository);

  Future<Result<void>> call({
    required String assetId,
    required String userId,
  }) =>
      _repository.deleteAsset(assetId, userId);
}
