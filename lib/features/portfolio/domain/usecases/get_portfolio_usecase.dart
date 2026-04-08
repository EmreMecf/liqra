import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/result.dart';
import '../entities/asset_entity.dart';
import '../repositories/portfolio_repository.dart';

class GetPortfolioUseCase {
  final PortfolioRepository _repository;
  const GetPortfolioUseCase(this._repository);

  Future<Result<PortfolioEntity>> call({String? userId}) =>
      _repository.getPortfolio(
        userId ?? AuthService.instance.userId ?? '',
      );
}
