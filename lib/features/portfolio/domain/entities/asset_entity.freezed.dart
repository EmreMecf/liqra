// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asset_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AssetEntity {
  String get id => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get quantity => throw _privateConstructorUsedError;
  double get buyPrice => throw _privateConstructorUsedError;
  double get currentPrice => throw _privateConstructorUsedError;
  List<double> get priceHistory => throw _privateConstructorUsedError;

  /// Create a copy of AssetEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AssetEntityCopyWith<AssetEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AssetEntityCopyWith<$Res> {
  factory $AssetEntityCopyWith(
    AssetEntity value,
    $Res Function(AssetEntity) then,
  ) = _$AssetEntityCopyWithImpl<$Res, AssetEntity>;
  @useResult
  $Res call({
    String id,
    String type,
    String name,
    double quantity,
    double buyPrice,
    double currentPrice,
    List<double> priceHistory,
  });
}

/// @nodoc
class _$AssetEntityCopyWithImpl<$Res, $Val extends AssetEntity>
    implements $AssetEntityCopyWith<$Res> {
  _$AssetEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AssetEntity
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
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AssetEntityImplCopyWith<$Res>
    implements $AssetEntityCopyWith<$Res> {
  factory _$$AssetEntityImplCopyWith(
    _$AssetEntityImpl value,
    $Res Function(_$AssetEntityImpl) then,
  ) = __$$AssetEntityImplCopyWithImpl<$Res>;
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
  });
}

/// @nodoc
class __$$AssetEntityImplCopyWithImpl<$Res>
    extends _$AssetEntityCopyWithImpl<$Res, _$AssetEntityImpl>
    implements _$$AssetEntityImplCopyWith<$Res> {
  __$$AssetEntityImplCopyWithImpl(
    _$AssetEntityImpl _value,
    $Res Function(_$AssetEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AssetEntity
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
  }) {
    return _then(
      _$AssetEntityImpl(
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
      ),
    );
  }
}

/// @nodoc

class _$AssetEntityImpl implements _AssetEntity {
  const _$AssetEntityImpl({
    required this.id,
    required this.type,
    required this.name,
    required this.quantity,
    required this.buyPrice,
    required this.currentPrice,
    final List<double> priceHistory = const [],
  }) : _priceHistory = priceHistory;

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
  String toString() {
    return 'AssetEntity(id: $id, type: $type, name: $name, quantity: $quantity, buyPrice: $buyPrice, currentPrice: $currentPrice, priceHistory: $priceHistory)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AssetEntityImpl &&
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
            ));
  }

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
  );

  /// Create a copy of AssetEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AssetEntityImplCopyWith<_$AssetEntityImpl> get copyWith =>
      __$$AssetEntityImplCopyWithImpl<_$AssetEntityImpl>(this, _$identity);
}

abstract class _AssetEntity implements AssetEntity {
  const factory _AssetEntity({
    required final String id,
    required final String type,
    required final String name,
    required final double quantity,
    required final double buyPrice,
    required final double currentPrice,
    final List<double> priceHistory,
  }) = _$AssetEntityImpl;

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

  /// Create a copy of AssetEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AssetEntityImplCopyWith<_$AssetEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PortfolioEntity {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  List<AssetEntity> get assets => throw _privateConstructorUsedError;

  /// Create a copy of PortfolioEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PortfolioEntityCopyWith<PortfolioEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PortfolioEntityCopyWith<$Res> {
  factory $PortfolioEntityCopyWith(
    PortfolioEntity value,
    $Res Function(PortfolioEntity) then,
  ) = _$PortfolioEntityCopyWithImpl<$Res, PortfolioEntity>;
  @useResult
  $Res call({String id, String userId, List<AssetEntity> assets});
}

/// @nodoc
class _$PortfolioEntityCopyWithImpl<$Res, $Val extends PortfolioEntity>
    implements $PortfolioEntityCopyWith<$Res> {
  _$PortfolioEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PortfolioEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? userId = null, Object? assets = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            assets: null == assets
                ? _value.assets
                : assets // ignore: cast_nullable_to_non_nullable
                      as List<AssetEntity>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PortfolioEntityImplCopyWith<$Res>
    implements $PortfolioEntityCopyWith<$Res> {
  factory _$$PortfolioEntityImplCopyWith(
    _$PortfolioEntityImpl value,
    $Res Function(_$PortfolioEntityImpl) then,
  ) = __$$PortfolioEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String userId, List<AssetEntity> assets});
}

/// @nodoc
class __$$PortfolioEntityImplCopyWithImpl<$Res>
    extends _$PortfolioEntityCopyWithImpl<$Res, _$PortfolioEntityImpl>
    implements _$$PortfolioEntityImplCopyWith<$Res> {
  __$$PortfolioEntityImplCopyWithImpl(
    _$PortfolioEntityImpl _value,
    $Res Function(_$PortfolioEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PortfolioEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? userId = null, Object? assets = null}) {
    return _then(
      _$PortfolioEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        assets: null == assets
            ? _value._assets
            : assets // ignore: cast_nullable_to_non_nullable
                  as List<AssetEntity>,
      ),
    );
  }
}

/// @nodoc

class _$PortfolioEntityImpl implements _PortfolioEntity {
  const _$PortfolioEntityImpl({
    required this.id,
    required this.userId,
    required final List<AssetEntity> assets,
  }) : _assets = assets;

  @override
  final String id;
  @override
  final String userId;
  final List<AssetEntity> _assets;
  @override
  List<AssetEntity> get assets {
    if (_assets is EqualUnmodifiableListView) return _assets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_assets);
  }

  @override
  String toString() {
    return 'PortfolioEntity(id: $id, userId: $userId, assets: $assets)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PortfolioEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            const DeepCollectionEquality().equals(other._assets, _assets));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    const DeepCollectionEquality().hash(_assets),
  );

  /// Create a copy of PortfolioEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PortfolioEntityImplCopyWith<_$PortfolioEntityImpl> get copyWith =>
      __$$PortfolioEntityImplCopyWithImpl<_$PortfolioEntityImpl>(
        this,
        _$identity,
      );
}

abstract class _PortfolioEntity implements PortfolioEntity {
  const factory _PortfolioEntity({
    required final String id,
    required final String userId,
    required final List<AssetEntity> assets,
  }) = _$PortfolioEntityImpl;

  @override
  String get id;
  @override
  String get userId;
  @override
  List<AssetEntity> get assets;

  /// Create a copy of PortfolioEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PortfolioEntityImplCopyWith<_$PortfolioEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
