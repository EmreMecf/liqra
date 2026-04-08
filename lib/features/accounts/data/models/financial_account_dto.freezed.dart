// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'financial_account_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FinancialAccountDto _$FinancialAccountDtoFromJson(Map<String, dynamic> json) {
  return _FinancialAccountDto.fromJson(json);
}

/// @nodoc
mixin _$FinancialAccountDto {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get bank => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  String get createdAt =>
      throw _privateConstructorUsedError; // BankAccount fields
  double? get balance => throw _privateConstructorUsedError;
  String? get iban => throw _privateConstructorUsedError;
  String? get maskedAccountNumber =>
      throw _privateConstructorUsedError; // CreditCard fields
  double? get creditLimit => throw _privateConstructorUsedError;
  double? get usedAmount => throw _privateConstructorUsedError;
  double? get statementBalance => throw _privateConstructorUsedError;
  double? get minimumPayment => throw _privateConstructorUsedError;
  int? get statementClosingDay => throw _privateConstructorUsedError;
  int? get paymentDueDay => throw _privateConstructorUsedError;
  String? get maskedCardNumber => throw _privateConstructorUsedError;

  /// Serializes this FinancialAccountDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FinancialAccountDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FinancialAccountDtoCopyWith<FinancialAccountDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FinancialAccountDtoCopyWith<$Res> {
  factory $FinancialAccountDtoCopyWith(
    FinancialAccountDto value,
    $Res Function(FinancialAccountDto) then,
  ) = _$FinancialAccountDtoCopyWithImpl<$Res, FinancialAccountDto>;
  @useResult
  $Res call({
    String id,
    String userId,
    String type,
    String name,
    String bank,
    String currency,
    String createdAt,
    double? balance,
    String? iban,
    String? maskedAccountNumber,
    double? creditLimit,
    double? usedAmount,
    double? statementBalance,
    double? minimumPayment,
    int? statementClosingDay,
    int? paymentDueDay,
    String? maskedCardNumber,
  });
}

/// @nodoc
class _$FinancialAccountDtoCopyWithImpl<$Res, $Val extends FinancialAccountDto>
    implements $FinancialAccountDtoCopyWith<$Res> {
  _$FinancialAccountDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FinancialAccountDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? type = null,
    Object? name = null,
    Object? bank = null,
    Object? currency = null,
    Object? createdAt = null,
    Object? balance = freezed,
    Object? iban = freezed,
    Object? maskedAccountNumber = freezed,
    Object? creditLimit = freezed,
    Object? usedAmount = freezed,
    Object? statementBalance = freezed,
    Object? minimumPayment = freezed,
    Object? statementClosingDay = freezed,
    Object? paymentDueDay = freezed,
    Object? maskedCardNumber = freezed,
  }) {
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
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            bank: null == bank
                ? _value.bank
                : bank // ignore: cast_nullable_to_non_nullable
                      as String,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
            balance: freezed == balance
                ? _value.balance
                : balance // ignore: cast_nullable_to_non_nullable
                      as double?,
            iban: freezed == iban
                ? _value.iban
                : iban // ignore: cast_nullable_to_non_nullable
                      as String?,
            maskedAccountNumber: freezed == maskedAccountNumber
                ? _value.maskedAccountNumber
                : maskedAccountNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            creditLimit: freezed == creditLimit
                ? _value.creditLimit
                : creditLimit // ignore: cast_nullable_to_non_nullable
                      as double?,
            usedAmount: freezed == usedAmount
                ? _value.usedAmount
                : usedAmount // ignore: cast_nullable_to_non_nullable
                      as double?,
            statementBalance: freezed == statementBalance
                ? _value.statementBalance
                : statementBalance // ignore: cast_nullable_to_non_nullable
                      as double?,
            minimumPayment: freezed == minimumPayment
                ? _value.minimumPayment
                : minimumPayment // ignore: cast_nullable_to_non_nullable
                      as double?,
            statementClosingDay: freezed == statementClosingDay
                ? _value.statementClosingDay
                : statementClosingDay // ignore: cast_nullable_to_non_nullable
                      as int?,
            paymentDueDay: freezed == paymentDueDay
                ? _value.paymentDueDay
                : paymentDueDay // ignore: cast_nullable_to_non_nullable
                      as int?,
            maskedCardNumber: freezed == maskedCardNumber
                ? _value.maskedCardNumber
                : maskedCardNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FinancialAccountDtoImplCopyWith<$Res>
    implements $FinancialAccountDtoCopyWith<$Res> {
  factory _$$FinancialAccountDtoImplCopyWith(
    _$FinancialAccountDtoImpl value,
    $Res Function(_$FinancialAccountDtoImpl) then,
  ) = __$$FinancialAccountDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String type,
    String name,
    String bank,
    String currency,
    String createdAt,
    double? balance,
    String? iban,
    String? maskedAccountNumber,
    double? creditLimit,
    double? usedAmount,
    double? statementBalance,
    double? minimumPayment,
    int? statementClosingDay,
    int? paymentDueDay,
    String? maskedCardNumber,
  });
}

/// @nodoc
class __$$FinancialAccountDtoImplCopyWithImpl<$Res>
    extends _$FinancialAccountDtoCopyWithImpl<$Res, _$FinancialAccountDtoImpl>
    implements _$$FinancialAccountDtoImplCopyWith<$Res> {
  __$$FinancialAccountDtoImplCopyWithImpl(
    _$FinancialAccountDtoImpl _value,
    $Res Function(_$FinancialAccountDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FinancialAccountDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? type = null,
    Object? name = null,
    Object? bank = null,
    Object? currency = null,
    Object? createdAt = null,
    Object? balance = freezed,
    Object? iban = freezed,
    Object? maskedAccountNumber = freezed,
    Object? creditLimit = freezed,
    Object? usedAmount = freezed,
    Object? statementBalance = freezed,
    Object? minimumPayment = freezed,
    Object? statementClosingDay = freezed,
    Object? paymentDueDay = freezed,
    Object? maskedCardNumber = freezed,
  }) {
    return _then(
      _$FinancialAccountDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        bank: null == bank
            ? _value.bank
            : bank // ignore: cast_nullable_to_non_nullable
                  as String,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
        balance: freezed == balance
            ? _value.balance
            : balance // ignore: cast_nullable_to_non_nullable
                  as double?,
        iban: freezed == iban
            ? _value.iban
            : iban // ignore: cast_nullable_to_non_nullable
                  as String?,
        maskedAccountNumber: freezed == maskedAccountNumber
            ? _value.maskedAccountNumber
            : maskedAccountNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        creditLimit: freezed == creditLimit
            ? _value.creditLimit
            : creditLimit // ignore: cast_nullable_to_non_nullable
                  as double?,
        usedAmount: freezed == usedAmount
            ? _value.usedAmount
            : usedAmount // ignore: cast_nullable_to_non_nullable
                  as double?,
        statementBalance: freezed == statementBalance
            ? _value.statementBalance
            : statementBalance // ignore: cast_nullable_to_non_nullable
                  as double?,
        minimumPayment: freezed == minimumPayment
            ? _value.minimumPayment
            : minimumPayment // ignore: cast_nullable_to_non_nullable
                  as double?,
        statementClosingDay: freezed == statementClosingDay
            ? _value.statementClosingDay
            : statementClosingDay // ignore: cast_nullable_to_non_nullable
                  as int?,
        paymentDueDay: freezed == paymentDueDay
            ? _value.paymentDueDay
            : paymentDueDay // ignore: cast_nullable_to_non_nullable
                  as int?,
        maskedCardNumber: freezed == maskedCardNumber
            ? _value.maskedCardNumber
            : maskedCardNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FinancialAccountDtoImpl implements _FinancialAccountDto {
  const _$FinancialAccountDtoImpl({
    required this.id,
    required this.userId,
    required this.type,
    required this.name,
    required this.bank,
    required this.currency,
    required this.createdAt,
    this.balance,
    this.iban,
    this.maskedAccountNumber,
    this.creditLimit,
    this.usedAmount,
    this.statementBalance,
    this.minimumPayment,
    this.statementClosingDay,
    this.paymentDueDay,
    this.maskedCardNumber,
  });

  factory _$FinancialAccountDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$FinancialAccountDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String type;
  @override
  final String name;
  @override
  final String bank;
  @override
  final String currency;
  @override
  final String createdAt;
  // BankAccount fields
  @override
  final double? balance;
  @override
  final String? iban;
  @override
  final String? maskedAccountNumber;
  // CreditCard fields
  @override
  final double? creditLimit;
  @override
  final double? usedAmount;
  @override
  final double? statementBalance;
  @override
  final double? minimumPayment;
  @override
  final int? statementClosingDay;
  @override
  final int? paymentDueDay;
  @override
  final String? maskedCardNumber;

  @override
  String toString() {
    return 'FinancialAccountDto(id: $id, userId: $userId, type: $type, name: $name, bank: $bank, currency: $currency, createdAt: $createdAt, balance: $balance, iban: $iban, maskedAccountNumber: $maskedAccountNumber, creditLimit: $creditLimit, usedAmount: $usedAmount, statementBalance: $statementBalance, minimumPayment: $minimumPayment, statementClosingDay: $statementClosingDay, paymentDueDay: $paymentDueDay, maskedCardNumber: $maskedCardNumber)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FinancialAccountDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.bank, bank) || other.bank == bank) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.iban, iban) || other.iban == iban) &&
            (identical(other.maskedAccountNumber, maskedAccountNumber) ||
                other.maskedAccountNumber == maskedAccountNumber) &&
            (identical(other.creditLimit, creditLimit) ||
                other.creditLimit == creditLimit) &&
            (identical(other.usedAmount, usedAmount) ||
                other.usedAmount == usedAmount) &&
            (identical(other.statementBalance, statementBalance) ||
                other.statementBalance == statementBalance) &&
            (identical(other.minimumPayment, minimumPayment) ||
                other.minimumPayment == minimumPayment) &&
            (identical(other.statementClosingDay, statementClosingDay) ||
                other.statementClosingDay == statementClosingDay) &&
            (identical(other.paymentDueDay, paymentDueDay) ||
                other.paymentDueDay == paymentDueDay) &&
            (identical(other.maskedCardNumber, maskedCardNumber) ||
                other.maskedCardNumber == maskedCardNumber));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    type,
    name,
    bank,
    currency,
    createdAt,
    balance,
    iban,
    maskedAccountNumber,
    creditLimit,
    usedAmount,
    statementBalance,
    minimumPayment,
    statementClosingDay,
    paymentDueDay,
    maskedCardNumber,
  );

  /// Create a copy of FinancialAccountDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FinancialAccountDtoImplCopyWith<_$FinancialAccountDtoImpl> get copyWith =>
      __$$FinancialAccountDtoImplCopyWithImpl<_$FinancialAccountDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$FinancialAccountDtoImplToJson(this);
  }
}

abstract class _FinancialAccountDto implements FinancialAccountDto {
  const factory _FinancialAccountDto({
    required final String id,
    required final String userId,
    required final String type,
    required final String name,
    required final String bank,
    required final String currency,
    required final String createdAt,
    final double? balance,
    final String? iban,
    final String? maskedAccountNumber,
    final double? creditLimit,
    final double? usedAmount,
    final double? statementBalance,
    final double? minimumPayment,
    final int? statementClosingDay,
    final int? paymentDueDay,
    final String? maskedCardNumber,
  }) = _$FinancialAccountDtoImpl;

  factory _FinancialAccountDto.fromJson(Map<String, dynamic> json) =
      _$FinancialAccountDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get type;
  @override
  String get name;
  @override
  String get bank;
  @override
  String get currency;
  @override
  String get createdAt; // BankAccount fields
  @override
  double? get balance;
  @override
  String? get iban;
  @override
  String? get maskedAccountNumber; // CreditCard fields
  @override
  double? get creditLimit;
  @override
  double? get usedAmount;
  @override
  double? get statementBalance;
  @override
  double? get minimumPayment;
  @override
  int? get statementClosingDay;
  @override
  int? get paymentDueDay;
  @override
  String? get maskedCardNumber;

  /// Create a copy of FinancialAccountDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FinancialAccountDtoImplCopyWith<_$FinancialAccountDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
