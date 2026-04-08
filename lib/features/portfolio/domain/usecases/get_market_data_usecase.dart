import '../../../../core/utils/result.dart';
import '../entities/market_data_entity.dart';
import '../repositories/portfolio_repository.dart';

class GetMarketDataUseCase {
  final PortfolioRepository _repository;
  const GetMarketDataUseCase(this._repository);

  Future<Result<List<MarketDataEntity>>> call() =>
      _repository.getMarketData();

  /// Gerçek zamanlı piyasa verisi stream'i (Firestore onSnapshot)
  Stream<List<MarketDataEntity>> watch() =>
      _repository.watchMarketData();

  Future<Result<List<TopFundEntity>>> topFunds() =>
      _repository.getTopFunds();
}
