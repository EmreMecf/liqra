import '../../../../core/utils/result.dart';
import '../entities/asset_entity.dart';
import '../entities/market_data_entity.dart';

abstract interface class PortfolioRepository {
  Future<Result<PortfolioEntity>> getPortfolio(String userId);
  Future<Result<List<MarketDataEntity>>> getMarketData();
  Stream<List<MarketDataEntity>> watchMarketData();
  Future<Result<List<TopFundEntity>>> getTopFunds();
  Future<Result<AssetEntity>> addAsset(AssetEntity asset, String userId);
  Future<Result<void>> updateAsset(AssetEntity asset);
  Future<Result<void>> deleteAsset(String assetId, String userId);
}
