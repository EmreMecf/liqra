// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asset_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AssetDto _$AssetDtoFromJson(Map<String, dynamic> json) {
  return _AssetDto.fromJson(json);
}

/// @nodoc
mixin _$AssetDto {
  String get id => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get quantity => throw _privateConstructorUsedError;
  double get buyPrice => throw _privateConstructorUsedError;
  double get currentPrice => throw _privateConstructorUsedError;
  List<double> get priceHistory => throw _privateConstructorUsedError;
  String? get priceSection => throw _privateConstructorUsedError;
  String? get priceKey => throw _privateConstructorUsedError;

  /// Serializes this AssetDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AssetDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AssetDtoCopyWith<AssetDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AssetDtoCopyWith<$Res> {
  factory $AssetDtoCopyWith(AssetDto value, $Res Function(AssetDto) then) =
      _$AssetDtoCopyWithImpl<$Res, AssetDto>;
  @useResult
  $Res call({
    String id,
    String type,
    String name,
    double quantity,
    double buyPrice,
    double currentPrice,
    List<double> priceHistory,
    String? priceSection,
    String? priceKey,
  });
}

/// @nodoc
class _$AssetDtoCopyWithImpl<$Res, $Val extends AssetDto>
    implements $AssetDtoCopyWith<$Res> {
  _$AssetDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AssetDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? name = null,
    Object? quantity = null,
    Object? buyPrice = null,
    Object? currentPrice = null,
    Object? priceHistory = null,
    Object? priceSection = freezed,
    Object? priceKey = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            quantity: null == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as double,
            buyPrice: null == buyPrice
                ? _value.buyPrice
                : buyPrice // ignore: cast_nullable_to_non_nullable
                      as double,
            currentPrice: null == currentPrice
                ? _value.currentPrice
                : currentPrice // ignore: cast_nullable_to_non_nullable
                      as double,
            priceHistory: null == priceHistory
                ? _value.priceHistory
                : priceHistory // ignore: cast_nullable_to_non_nullable
                      as List<double>,
            priceSection: freezed == priceSection
                ? _value.priceSection
                : priceSection // ignore: cast_nullable_to_non_nullable
                      as String?,
            priceKey: freezed == priceKey
                ? _value.priceKey
                : priceKey // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AssetDtoImplCopyWith<$Res>
    implements $AssetDtoCopyWith<$Res> {
  factory _$$AssetDtoImplCopyWith(
    _$AssetDtoImpl value,
    $Res Function(_$AssetDtoImpl) then,
  ) = __$$AssetDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String type,
    String name,
    double quantity,
    double buyPrice,
    double currentPrice,
    List<double> priceHistory,
    String? priceSection,
    String? priceKey,
  });
}

/// @nodoc
class __$$AssetDtoImplCopyWithImpl<$Res>
    extends _$AssetDtoCopyWithImpl<$Res, _$AssetDtoImpl>
    implements _$$AssetDtoImplCopyWith<$Res> {
  __$$AssetDtoImplCopyWithImpl(
    _$AssetDtoImpl _value,
    $Res Function(_$AssetDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AssetDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? name = null,
    Object? quantity = null,
    Object? buyPrice = null,
    Object? currentPrice = null,
    Object? priceHistory = null,
    Object? priceSection = freezed,
    Object? priceKey = freezed,
  }) {
    return _then(
      _$AssetDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        quantity: null == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as double,
        buyPrice: null == buyPrice
            ? _value.buyPrice
            : buyPrice // ignore: cast_nullable_to_non_nullable
                  as double,
        currentPrice: null == currentPrice
            ? _value.currentPrice
            : currentPrice // ignore: cast_nullable_to_non_nullable
                  as double,
        priceHistory: null == priceHistory
            ? _value._priceHistory
            : priceHistory // ignore: cast_nullable_to_non_nullable
                  as List<double>,
        priceSection: freezed == priceSection
            ? _value.priceSection
            : priceSection // ignore: cast_nullable_to_non_nullable
                  as String?,
        priceKey: freezed == priceKey
            ? _value.priceKey
            : priceKey // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AssetDtoImpl implements _AssetDto {
  const _$AssetDtoImpl({
    required this.id,
    required this.type,
    required this.name,
    required this.quantity,
    required this.buyPrice,
    required this.currentPrice,
    final List<double> priceHistory = const [],
    this.priceSection,
    this.priceKey,
  }) : _priceHistory = priceHistory;

  factory _$AssetDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$AssetDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String type;
  @override
  final String name;
  @override
  final double quantity;
  @override
  final double buyPrice;
  @override
  final double currentPrice;
  final List<double> _priceHistory;
  @override
  @JsonKey()
  List<double> get priceHistory {
    if (_priceHistory is EqualUnmodifiableListView) return _priceHistory;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_priceHistory);
  }

  @override
  final String? priceSection;
  @override
  final String? priceKey;

  @override
  String toString() {
    return 'AssetDto(id: $id, type: $type, name: $name, quantity: $quantity, buyPrice: $buyPrice, currentPrice: $currentPrice, priceHistory: $priceHistory, priceSection: $priceSection, priceKey: $priceKey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AssetDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.buyPrice, buyPrice) ||
                other.buyPrice == buyPrice) &&
            (identical(other.currentPrice, currentPrice) ||
                other.currentPrice == currentPrice) &&
            const DeepCollectionEquality().equals(
              other._priceHistory,
              _priceHistory,
            ) &&
            (identical(other.priceSection, priceSection) ||
                other.priceSection == priceSection) &&
            (identical(other.priceKey, priceKey) ||
                other.priceKey == priceKey));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    type,
    name,
    quantity,
    buyPrice,
    currentPrice,
    const DeepCollectionEquality().hash(_priceHistory),
    priceSection,
    priceKey,
  );

  /// Create a copy of AssetDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AssetDtoImplCopyWith<_$AssetDtoImpl> get copyWith =>
      __$$AssetDtoImplCopyWithImpl<_$AssetDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AssetDtoImplToJson(this);
  }
}

abstract class _AssetDto implements AssetDto {
  const factory _AssetDto({
    required final String id,
    required final String type,
    required final String name,
    required final double quantity,
    required final double buyPrice,
    required final double currentPrice,
    final List<double> priceHistory,
    final String? priceSection,
    final String? priceKey,
  }) = _$AssetDtoImpl;

  factory _AssetDto.fromJson(Map<String, dynamic> json) =
      _$AssetDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get type;
  @override
  String get name;
  @override
  double get quantity;
  @override
  double get buyPrice;
  @override
  double get currentPrice;
  @override
  List<double> get priceHistory;
  @override
  String? get priceSection;
  @override
  String? get priceKey;

  /// Create a copy of AssetDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AssetDtoImplCopyWith<_$AssetDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MarketDataDto _$MarketDataDtoFromJson(Map<String, dynamic> json) {
  return _MarketDataDto.fromJson(json);
}

/// @nodoc
mixin _$MarketDataDto {
  String get symbol => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get icon => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  double get changePercent => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  String? get subLabel => throw _privateConstructorUsedError;
  String? get lastUpdated => throw _privateConstructorUsedError;
  double get volume => throw _privateConstructorUsedError;

  /// Serializes this MarketDataDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MarketDataDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MarketDataDtoCopyWith<MarketDataDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MarketDataDtoCopyWith<$Res> {
  factory $MarketDataDtoCopyWith(
    MarketDataDto value,
    $Res Function(MarketDataDto) then,
  ) = _$MarketDataDtoCopyWithImpl<$Res, MarketDataDto>;
  @useResult
  $Res call({
    String symbol,
    String name,
    String icon,
    double price,
    double changePercent,
    String currency,
    String? subLabel,
    String? lastUpdated,
    double volume,
  });
}

/// @nodoc
class _$MarketDataDtoCopyWithImpl<$Res, $Val extends MarketDataDto>
    implements $MarketDataDtoCopyWith<$Res> {
  _$MarketDataDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MarketDataDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbol = null,
    Object? name = null,
    Object? icon = null,
    Object? price = null,
    Object? changePercent = null,
    Object? currency = null,
    Object? subLabel = freezed,
    Object? lastUpdated = freezed,
    Object? volume = null,
  }) {
    return _then(
      _value.copyWith(
            symbol: null == symbol
                ? _value.symbol
                : symbol // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            icon: null == icon
                ? _value.icon
                : icon // ignore: cast_nullable_to_non_nullable
                      as String,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as double,
            changePercent: null == changePercent
                ? _value.changePercent
                : changePercent // ignore: cast_nullable_to_non_nullable
                      as double,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            subLabel: freezed == subLabel
                ? _value.subLabel
                : subLabel // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastUpdated: freezed == lastUpdated
                ? _value.lastUpdated
                : lastUpdated // ignore: cast_nullable_to_non_nullable
                      as String?,
            volume: null == volume
                ? _value.volume
                : volume // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MarketDataDtoImplCopyWith<$Res>
    implements $MarketDataDtoCopyWith<$Res> {
  factory _$$MarketDataDtoImplCopyWith(
    _$MarketDataDtoImpl value,
    $Res Function(_$MarketDataDtoImpl) then,
  ) = __$$MarketDataDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String symbol,
    String name,
    String icon,
    double price,
    double changePercent,
    String currency,
    String? subLabel,
    String? lastUpdated,
    double volume,
  });
}

/// @nodoc
class __$$MarketDataDtoImplCopyWithImpl<$Res>
    extends _$MarketDataDtoCopyWithImpl<$Res, _$MarketDataDtoImpl>
    implements _$$MarketDataDtoImplCopyWith<$Res> {
  __$$MarketDataDtoImplCopyWithImpl(
    _$MarketDataDtoImpl _value,
    $Res Function(_$MarketDataDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MarketDataDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbol = null,
    Object? name = null,
    Object? icon = null,
    Object? price = null,
    Object? changePercent = null,
    Object? currency = null,
    Object? subLabel = freezed,
    Object? lastUpdated = freezed,
    Object? volume = null,
  }) {
    return _then(
      _$MarketDataDtoImpl(
        symbol: null == symbol
            ? _value.symbol
            : symbol // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        icon: null == icon
            ? _value.icon
            : icon // ignore: cast_nullable_to_non_nullable
                  as String,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        changePercent: null == changePercent
            ? _value.changePercent
            : changePercent // ignore: cast_nullable_to_non_nullable
                  as double,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        subLabel: freezed == subLabel
            ? _value.subLabel
            : subLabel // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastUpdated: freezed == lastUpdated
            ? _value.lastUpdated
            : lastUpdated // ignore: cast_nullable_to_non_nullable
                  as String?,
        volume: null == volume
            ? _value.volume
            : volume // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MarketDataDtoImpl implements _MarketDataDto {
  const _$MarketDataDtoImpl({
    required this.symbol,
    required this.name,
    required this.icon,
    required this.price,
    required this.changePercent,
    required this.currency,
    this.subLabel,
    this.lastUpdated,
    this.volume = 0,
  });

  factory _$MarketDataDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$MarketDataDtoImplFromJson(json);

  @override
  final String symbol;
  @override
  final String name;
  @override
  final String icon;
  @override
  final double price;
  @override
  final double changePercent;
  @override
  final String currency;
  @override
  final String? subLabel;
  @override
  final String? lastUpdated;
  @override
  @JsonKey()
  final double volume;

  @override
  String toString() {
    return 'MarketDataDto(symbol: $symbol, name: $name, icon: $icon, price: $price, changePercent: $changePercent, currency: $currency, subLabel: $subLabel, lastUpdated: $lastUpdated, volume: $volume)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MarketDataDtoImpl &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.changePercent, changePercent) ||
                other.changePercent == changePercent) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.subLabel, subLabel) ||
                other.subLabel == subLabel) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated) &&
            (identical(other.volume, volume) || other.volume == volume));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    symbol,
    name,
    icon,
    price,
    changePercent,
    currency,
    subLabel,
    lastUpdated,
    volume,
  );

  /// Create a copy of MarketDataDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MarketDataDtoImplCopyWith<_$MarketDataDtoImpl> get copyWith =>
      __$$MarketDataDtoImplCopyWithImpl<_$MarketDataDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MarketDataDtoImplToJson(this);
  }
}

abstract class _MarketDataDto implements MarketDataDto {
  const factory _MarketDataDto({
    required final String symbol,
    required final String name,
    required final String icon,
    required final double price,
    required final double changePercent,
    required final String currency,
    final String? subLabel,
    final String? lastUpdated,
    final double volume,
  }) = _$MarketDataDtoImpl;

  factory _MarketDataDto.fromJson(Map<String, dynamic> json) =
      _$MarketDataDtoImpl.fromJson;

  @override
  String get symbol;
  @override
  String get name;
  @override
  String get icon;
  @override
  double get price;
  @override
  double get changePercent;
  @override
  String get currency;
  @override
  String? get subLabel;
  @override
  String? get lastUpdated;
  @override
  double get volume;

  /// Create a copy of MarketDataDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MarketDataDtoImplCopyWith<_$MarketDataDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
