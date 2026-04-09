import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/asset_entity.dart';
import '../../domain/entities/market_data_entity.dart';
import '../../domain/repositories/portfolio_repository.dart';
import '../datasources/portfolio_local_datasource.dart';
import '../datasources/market_remote_datasource.dart';
import '../datasources/tefas_datasource.dart';
import '../models/asset_dto.dart';

class PortfolioRepositoryImpl implements PortfolioRepository {
  final PortfolioLocalDataSource _localDataSource;
  final MarketRemoteDataSource   _remoteDataSource;
  final TefasDataSource          _tefasDataSource;

  const PortfolioRepositoryImpl({
    required PortfolioLocalDataSource localDataSource,
    required MarketRemoteDataSource   remoteDataSource,
    required TefasDataSource          tefasDataSource,
  })  : _localDataSource  = localDataSource,
        _remoteDataSource = remoteDataSource,
        _tefasDataSource  = tefasDataSource;

  @override
  Future<Result<PortfolioEntity>> getPortfolio(String userId) async {
    try {
      final dtos = await _localDataSource.getAssets(userId);
      final assets = dtos.map(_dtoToAsset).toList();
      return Success(PortfolioEntity(
        id: 'portfolio_$userId',
        userId: userId,
        assets: assets,
      ));
    } catch (e) {
      return Failure(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<MarketDataEntity>>> getMarketData() async {
    try {
      final dtos = await _remoteDataSource.getMarketData();
      return Success(dtos.map(_dtoToMarket).toList());
    } on AppException catch (e) {
      return Failure(NetworkFailure(e.userMessage));
    } catch (e) {
      return Failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<List<MarketDataEntity>> watchMarketData() {
    return _remoteDataSource
        .watchMarketData()
        .map((dtos) => dtos.map(_dtoToMarket).toList());
  }

  @override
  Future<Result<List<TopFundEntity>>> getTopFunds() async {
    try {
      final funds = await _tefasDataSource.getAllFunds();

      if (funds.isEmpty) return _mockTopFunds();

      // 1 yıllık getiriye göre sırala, en iyi 5'i al
      final sorted = [...funds]
        ..sort((a, b) => b.yearlyReturn.compareTo(a.yearlyReturn));

      return Success(sorted.take(5).map((f) => TopFundEntity(
        code:          f.code,
        name:          f.name,
        type:          f.type,
        returnPercent: f.yearlyReturn,
      )).toList());
    } catch (_) {
      return _mockTopFunds();
    }
  }

  static Result<List<TopFundEntity>> _mockTopFunds() => const Success([]);

  @override
  Future<Result<AssetEntity>> addAsset(AssetEntity asset, String userId) async {
    try {
      final dto = _assetToDto(asset);
      final saved = await _localDataSource.addAsset(dto);
      return Success(_dtoToAsset(saved));
    } catch (e) {
      return Failure(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateAsset(AssetEntity asset) async {
    try {
      await _localDataSource.updateAsset(_assetToDto(asset));
      return const Success(null);
    } catch (e) {
      return Failure(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteAsset(String assetId, String userId) async {
    try {
      await _localDataSource.deleteAsset(assetId);
      return const Success(null);
    } catch (e) {
      return Failure(CacheFailure(e.toString()));
    }
  }

  // ── Dönüşümler ────────────────────────────────────────────────────────────

  AssetEntity _dtoToAsset(AssetDto dto) => AssetEntity(
        id: dto.id,
        type: dto.type,
        name: dto.name,
        quantity: dto.quantity,
        buyPrice: dto.buyPrice,
        currentPrice: dto.currentPrice,
        priceHistory: dto.priceHistory,
        priceSection: dto.priceSection,
        priceKey: dto.priceKey,
      );

  AssetDto _assetToDto(AssetEntity entity) => AssetDto(
        id: entity.id,
        type: entity.type,
        name: entity.name,
        quantity: entity.quantity,
        buyPrice: entity.buyPrice,
        currentPrice: entity.currentPrice,
        priceHistory: entity.priceHistory,
        priceSection: entity.priceSection,
        priceKey: entity.priceKey,
      );

  MarketDataEntity _dtoToMarket(MarketDataDto dto) => MarketDataEntity(
        symbol: dto.symbol,
        name: dto.name,
        icon: dto.icon,
        price: dto.price,
        changePercent: dto.changePercent,
        currency: dto.currency,
        subLabel: dto.subLabel,
        lastUpdated: dto.lastUpdated != null
            ? DateTime.tryParse(dto.lastUpdated!)
            : DateTime.now(),
        volume: dto.volume,
      );
}
