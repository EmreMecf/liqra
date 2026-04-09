import 'package:freezed_annotation/freezed_annotation.dart';

part 'asset_dto.freezed.dart';
part 'asset_dto.g.dart';

@freezed
class AssetDto with _$AssetDto {
  const factory AssetDto({
    required String id,
    required String type,
    required String name,
    required double quantity,
    required double buyPrice,
    required double currentPrice,
    @Default([]) List<double> priceHistory,
    String? priceSection,
    String? priceKey,
  }) = _AssetDto;

  factory AssetDto.fromJson(Map<String, dynamic> json) =>
      _$AssetDtoFromJson(json);
}

@freezed
class MarketDataDto with _$MarketDataDto {
  const factory MarketDataDto({
    required String symbol,
    required String name,
    required String icon,
    required double price,
    required double changePercent,
    required String currency,
    String? subLabel,
    String? lastUpdated,
    @Default(0) double volume,
  }) = _MarketDataDto;

  factory MarketDataDto.fromJson(Map<String, dynamic> json) =>
      _$MarketDataDtoFromJson(json);
}
