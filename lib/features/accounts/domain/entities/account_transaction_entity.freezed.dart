// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_transaction_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AccountTransactionEntity _$AccountTransactionEntityFromJson(
  Map<String, dynamic> json,
) {
  return _AccountTransactionEntity.fromJson(json);
}

/// @nodoc
mixin _$AccountTransactionEntity {
  String get id => throw _privateConstructorUsedError;
  String get accountId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  bool get isInstallment => throw _privateConstructorUsedError;
  int get installmentCount => throw _privateConstructorUsedError;
  int get installmentNumber => throw _privateConstructorUsedError;
  String? get merchantName => throw _privateConstructorUsedError;
  String? get statementId => throw _privateConstructorUsedError;
  String get source => throw _privateConstructorUsedError;

  /// Serializes this AccountTransactionEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AccountTransactionEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AccountTransactionEntityCopyWith<AccountTransactionEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountTransactionEntityCopyWith<$Res> {
  factory $AccountTransactionEntityCopyWith(
    AccountTransactionEntity value,
    $Res Function(AccountTransactionEntity) then,
  ) = _$AccountTransactionEntityCopyWithImpl<$Res, AccountTransactionEntity>;
  @useResult
  $Res call({
    String id,
    String accountId,
    String userId,
    double amount,
    String description,
    DateTime date,
    String type,
    String category,
    bool isInstallment,
    int installmentCount,
    int installmentNumber,
    String? merchantName,
    String? statementId,
    String source,
  });
}

/// @nodoc
class _$AccountTransactionEntityCopyWithImpl<
  $Res,
  $Val extends AccountTransactionEntity
>
    implements $AccountTransactionEntityCopyWith<$Res> {
  _$AccountTransactionEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AccountTransactionEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? accountId = null,
    Object? userId = null,
    Object? amount = null,
    Object? description = null,
    Object? date = null,
    Object? type = null,
    Object? category = null,
    Object? isInstallment = null,
    Object? installmentCount = null,
    Object? installmentNumber = null,
    Object? merchantName = freezed,
    Object? statementId = freezed,
    Object? source = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            accountId: null == accountId
                ? _value.accountId
                : accountId // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            isInstallment: null == isInstallment
                ? _value.isInstallment
                : isInstallment // ignore: cast_nullable_to_non_nullable
                      as bool,
            installmentCount: null == installmentCount
                ? _value.installmentCount
                : installmentCount // ignore: cast_nullable_to_non_nullable
                      as int,
            installmentNumber: null == installmentNumber
                ? _value.installmentNumber
                : installmentNumber // ignore: cast_nullable_to_non_nullable
                      as int,
            merchantName: freezed == merchantName
                ? _value.merchantName
                : merchantName // ignore: cast_nullable_to_non_nullable
                      as String?,
            statementId: freezed == statementId
                ? _value.statementId
                : statementId // ignore: cast_nullable_to_non_nullable
                      as String?,
            source: null == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AccountTransactionEntityImplCopyWith<$Res>
    implements $AccountTransactionEntityCopyWith<$Res> {
  factory _$$AccountTransactionEntityImplCopyWith(
    _$AccountTransactionEntityImpl value,
    $Res Function(_$AccountTransactionEntityImpl) then,
  ) = __$$AccountTransactionEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String accountId,
    String userId,
    double amount,
    String description,
    DateTime date,
    String type,
    String category,
    bool isInstallment,
    int installmentCount,
    int installmentNumber,
    String? merchantName,
    String? statementId,
    String source,
  });
}

/// @nodoc
class __$$AccountTransactionEntityImplCopyWithImpl<$Res>
    extends
        _$AccountTransactionEntityCopyWithImpl<
          $Res,
          _$AccountTransactionEntityImpl
        >
    implements _$$AccountTransactionEntityImplCopyWith<$Res> {
  __$$AccountTransactionEntityImplCopyWithImpl(
    _$AccountTransactionEntityImpl _value,
    $Res Function(_$AccountTransactionEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountTransactionEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? accountId = null,
    Object? userId = null,
    Object? amount = null,
    Object? description = null,
    Object? date = null,
    Object? type = null,
    Object? category = null,
    Object? isInstallment = null,
    Object? installmentCount = null,
    Object? installmentNumber = null,
    Object? merchantName = freezed,
    Object? statementId = freezed,
    Object? source = null,
  }) {
    return _then(
      _$AccountTransactionEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        accountId: null == accountId
            ? _value.accountId
            : accountId // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        isInstallment: null == isInstallment
            ? _value.isInstallment
            : isInstallment // ignore: cast_nullable_to_non_nullable
                  as bool,
        installmentCount: null == installmentCount
            ? _value.installmentCount
            : installmentCount // ignore: cast_nullable_to_non_nullable
                  as int,
        installmentNumber: null == installmentNumber
            ? _value.installmentNumber
            : installmentNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        merchantName: freezed == merchantName
            ? _value.merchantName
            : merchantName // ignore: cast_nullable_to_non_nullable
                  as String?,
        statementId: freezed == statementId
            ? _value.statementId
            : statementId // ignore: cast_nullable_to_non_nullable
                  as String?,
        source: null == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AccountTransactionEntityImpl implements _AccountTransactionEntity {
  const _$AccountTransactionEntityImpl({
    required this.id,
    required this.accountId,
    required this.userId,
    required this.amount,
    required this.description,
    required this.date,
    required this.type,
    required this.category,
    this.isInstallment = false,
    this.installmentCount = 1,
    this.installmentNumber = 1,
    this.merchantName,
    this.statementId,
    this.source = 'manual',
  });

  factory _$AccountTransactionEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$AccountTransactionEntityImplFromJson(json);

  @override
  final String id;
  @override
  final String accountId;
  @override
  final String userId;
  @override
  final double amount;
  @override
  final String description;
  @override
  final DateTime date;
  @override
  final String type;
  @override
  final String category;
  @override
  @JsonKey()
  final bool isInstallment;
  @override
  @JsonKey()
  final int installmentCount;
  @override
  @JsonKey()
  final int installmentNumber;
  @override
  final String? merchantName;
  @override
  final String? statementId;
  @override
  @JsonKey()
  final String source;

  @override
  String toString() {
    return 'AccountTransactionEntity(id: $id, accountId: $accountId, userId: $userId, amount: $amount, description: $description, date: $date, type: $type, category: $category, isInstallment: $isInstallment, installmentCount: $installmentCount, installmentNumber: $installmentNumber, merchantName: $merchantName, statementId: $statementId, source: $source)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountTransactionEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.isInstallment, isInstallment) ||
                other.isInstallment == isInstallment) &&
            (identical(other.installmentCount, installmentCount) ||
                other.installmentCount == installmentCount) &&
            (identical(other.installmentNumber, installmentNumber) ||
                other.installmentNumber == installmentNumber) &&
            (identical(other.merchantName, merchantName) ||
                other.merchantName == merchantName) &&
            (identical(other.statementId, statementId) ||
                other.statementId == statementId) &&
            (identical(other.source, source) || other.source == source));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    accountId,
    userId,
    amount,
    description,
    date,
    type,
    category,
    isInstallment,
    installmentCount,
    installmentNumber,
    merchantName,
    statementId,
    source,
  );

  /// Create a copy of AccountTransactionEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountTransactionEntityImplCopyWith<_$AccountTransactionEntityImpl>
  get copyWith =>
      __$$AccountTransactionEntityImplCopyWithImpl<
        _$AccountTransactionEntityImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AccountTransactionEntityImplToJson(this);
  }
}

abstract class _AccountTransactionEntity implements AccountTransactionEntity {
  const factory _AccountTransactionEntity({
    required final String id,
    required final String accountId,
    required final String userId,
    required final double amount,
    required final String description,
    required final DateTime date,
    required final String type,
    required final String category,
    final bool isInstallment,
    final int installmentCount,
    final int installmentNumber,
    final String? merchantName,
    final String? statementId,
    final String source,
  }) = _$AccountTransactionEntityImpl;

  factory _AccountTransactionEntity.fromJson(Map<String, dynamic> json) =
      _$AccountTransactionEntityImpl.fromJson;

  @override
  String get id;
  @override
  String get accountId;
  @override
  String get userId;
  @override
  double get amount;
  @override
  String get description;
  @override
  DateTime get date;
  @override
  String get type;
  @override
  String get category;
  @override
  bool get isInstallment;
  @override
  int get installmentCount;
  @override
  int get installmentNumber;
  @override
  String? get merchantName;
  @override
  String? get statementId;
  @override
  String get source;

  /// Create a copy of AccountTransactionEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountTransactionEntityImplCopyWith<_$AccountTransactionEntityImpl>
  get copyWith => throw _privateConstructorUsedError;
}
