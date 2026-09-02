import 'package:freezed_annotation/freezed_annotation.dart';

part 'market_data_entity.freezed.dart';

@freezed
class MarketDataEntity with _$MarketDataEntity {
  const factory MarketDataEntity({
    required String symbol,
    required String name,
    required String icon,
    required double price,
    required double changePercent,
    required String currency,
    String? subLabel,
    DateTime? lastUpdated,
    @Default(0) double volume,
    /// Döviz alış/satış (CollectAPI). 0 = bu enstrüman için verilmiyor.
    @Default(0) double alis,
    @Default(0) double satis,
    /// Hisse günlük en düşük / en yüksek (CollectAPI). 0 = yok.
    @Default(0) double dayLow,
    @Default(0) double dayHigh,
  }) = _MarketDataEntity;
}

extension MarketDataEntityX on MarketDataEntity {
  bool get hasSpread   => alis > 0 && satis > 0;
  bool get hasDayRange => dayLow > 0 && dayHigh > 0 && dayHigh >= dayLow;
}

@freezed
class TopFundEntity with _$TopFundEntity {
  const factory TopFundEntity({
    required String code,
    required String name,
    required String type,
    required double returnPercent,
  }) = _TopFundEntity;
}
