import 'package:freezed_annotation/freezed_annotation.dart';

part 'asset_entity.freezed.dart';

@freezed
class AssetEntity with _$AssetEntity {
  const factory AssetEntity({
    required String id,
    required String type,
    required String name,
    required double quantity,
    required double buyPrice,
    required double currentPrice,
    @Default([]) List<double> priceHistory,
    /// Firestore market/live_prices içindeki bölüm: "stocks" | "prices" | "gold" | "funds"
    String? priceSection,
    /// Bölüm içindeki anahtar: "GARAN", "USDTRY", "gram", "BTC_TRY", "AAK"...
    String? priceKey,
  }) = _AssetEntity;
}

@freezed
class PortfolioEntity with _$PortfolioEntity {
  const factory PortfolioEntity({
    required String id,
    required String userId,
    required List<AssetEntity> assets,
  }) = _PortfolioEntity;
}

extension AssetEntityX on AssetEntity {
  double get totalValue      => quantity * currentPrice;
  double get totalCost       => quantity * buyPrice;
  double get gainLoss        => totalValue - totalCost;
  double get gainLossPercent => ((currentPrice - buyPrice) / buyPrice) * 100;
  bool   get isProfit        => gainLoss >= 0;
}

extension PortfolioEntityX on PortfolioEntity {
  double get totalValue    => assets.fold(0, (s, a) => s + a.totalValue);
  double get totalCost     => assets.fold(0, (s, a) => s + a.totalCost);
  double get totalGainLoss => totalValue - totalCost;
  double get gainLossPercent =>
      totalCost > 0 ? ((totalValue - totalCost) / totalCost) * 100 : 0;
}
