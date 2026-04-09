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
  }) = _MarketDataEntity;
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
