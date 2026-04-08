// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AssetDtoImpl _$$AssetDtoImplFromJson(Map<String, dynamic> json) =>
    _$AssetDtoImpl(
      id: json['id'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      buyPrice: (json['buyPrice'] as num).toDouble(),
      currentPrice: (json['currentPrice'] as num).toDouble(),
      priceHistory:
          (json['priceHistory'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$AssetDtoImplToJson(_$AssetDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'name': instance.name,
      'quantity': instance.quantity,
      'buyPrice': instance.buyPrice,
      'currentPrice': instance.currentPrice,
      'priceHistory': instance.priceHistory,
    };

_$MarketDataDtoImpl _$$MarketDataDtoImplFromJson(Map<String, dynamic> json) =>
    _$MarketDataDtoImpl(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      price: (json['price'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      currency: json['currency'] as String,
      subLabel: json['subLabel'] as String?,
      lastUpdated: json['lastUpdated'] as String?,
    );

Map<String, dynamic> _$$MarketDataDtoImplToJson(_$MarketDataDtoImpl instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'name': instance.name,
      'icon': instance.icon,
      'price': instance.price,
      'changePercent': instance.changePercent,
      'currency': instance.currency,
      'subLabel': instance.subLabel,
      'lastUpdated': instance.lastUpdated,
    };
