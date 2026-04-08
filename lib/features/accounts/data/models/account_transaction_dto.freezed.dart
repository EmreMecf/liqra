// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_transaction_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AccountTransactionDto _$AccountTransactionDtoFromJson(
  Map<String, dynamic> json,
) {
  return _AccountTransactionDto.fromJson(json);
}

/// @nodoc
mixin _$AccountTransactionDto {
  String get id => throw _privateConstructorUsedError;
  String get accountId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get date => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  bool get isInstallment => throw _privateConstructorUsedError;
  int get installmentCount => throw _privateConstructorUsedError;
  int get installmentNumber => throw _privateConstructorUsedError;
  String? get merchantName => throw _privateConstructorUsedError;
  String? get statementId => throw _privateConstructorUsedError;
  String get source => throw _privateConstructorUsedError;

  /// Serializes this AccountTransactionDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AccountTransactionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AccountTransactionDtoCopyWith<AccountTransactionDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountTransactionDtoCopyWith<$Res> {
  factory $AccountTransactionDtoCopyWith(
    AccountTransactionDto value,
    $Res Function(AccountTransactionDto) then,
  ) = _$AccountTransactionDtoCopyWithImpl<$Res, AccountTransactionDto>;
  @useResult
  $Res call({
    String id,
    String accountId,
    String userId,
    double amount,
    String description,
    String date,
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
class _$AccountTransactionDtoCopyWithImpl<
  $Res,
  $Val extends AccountTransactionDto
>
    implements $AccountTransactionDtoCopyWith<$Res> {
  _$AccountTransactionDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AccountTransactionDto
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
                      as String,
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
abstract class _$$AccountTransactionDtoImplCopyWith<$Res>
    implements $AccountTransactionDtoCopyWith<$Res> {
  factory _$$AccountTransactionDtoImplCopyWith(
    _$AccountTransactionDtoImpl value,
    $Res Function(_$AccountTransactionDtoImpl) then,
  ) = __$$AccountTransactionDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String accountId,
    String userId,
    double amount,
    String description,
    String date,
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
class __$$AccountTransactionDtoImplCopyWithImpl<$Res>
    extends
        _$AccountTransactionDtoCopyWithImpl<$Res, _$AccountTransactionDtoImpl>
    implements _$$AccountTransactionDtoImplCopyWith<$Res> {
  __$$AccountTransactionDtoImplCopyWithImpl(
    _$AccountTransactionDtoImpl _value,
    $Res Function(_$AccountTransactionDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountTransactionDto
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
      _$AccountTransactionDtoImpl(
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
                  as String,
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
class _$AccountTransactionDtoImpl implements _AccountTransactionDto {
  const _$AccountTransactionDtoImpl({
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

  factory _$AccountTransactionDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$AccountTransactionDtoImplFromJson(json);

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
  final String date;
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
    return 'AccountTransactionDto(id: $id, accountId: $accountId, userId: $userId, amount: $amount, description: $description, date: $date, type: $type, category: $category, isInstallment: $isInstallment, installmentCount: $installmentCount, installmentNumber: $installmentNumber, merchantName: $merchantName, statementId: $statementId, source: $source)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountTransactionDtoImpl &&
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

  /// Create a copy of AccountTransactionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountTransactionDtoImplCopyWith<_$AccountTransactionDtoImpl>
  get copyWith =>
      __$$AccountTransactionDtoImplCopyWithImpl<_$AccountTransactionDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AccountTransactionDtoImplToJson(this);
  }
}

abstract class _AccountTransactionDto implements AccountTransactionDto {
  const factory _AccountTransactionDto({
    required final String id,
    required final String accountId,
    required final String userId,
    required final double amount,
    required final String description,
    required final String date,
    required final String type,
    required final String category,
    final bool isInstallment,
    final int installmentCount,
    final int installmentNumber,
    final String? merchantName,
    final String? statementId,
    final String source,
  }) = _$AccountTransactionDtoImpl;

  factory _AccountTransactionDto.fromJson(Map<String, dynamic> json) =
      _$AccountTransactionDtoImpl.fromJson;

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
  String get date;
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

  /// Create a copy of AccountTransactionDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountTransactionDtoImplCopyWith<_$AccountTransactionDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}
