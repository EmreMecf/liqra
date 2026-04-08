// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'financial_account_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$FinancialAccountEntity {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  BankName get bank => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String id,
      String userId,
      String name,
      BankName bank,
      double balance,
      String currency,
      String? iban,
      String? maskedAccountNumber,
      DateTime createdAt,
    )
    bankAccount,
    required TResult Function(
      String id,
      String userId,
      String name,
      BankName bank,
      double creditLimit,
      double usedAmount,
      double statementBalance,
      double minimumPayment,
      int statementClosingDay,
      int paymentDueDay,
      String? maskedCardNumber,
      String currency,
      DateTime createdAt,
    )
    creditCard,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String id,
      String userId,
      String name,
      BankName bank,
      double balance,
      String currency,
      String? iban,
      String? maskedAccountNumber,
      DateTime createdAt,
    )?
    bankAccount,
    TResult? Function(
      String id,
      String userId,
      String name,
      BankName bank,
      double creditLimit,
      double usedAmount,
      double statementBalance,
      double minimumPayment,
      int statementClosingDay,
      int paymentDueDay,
      String? maskedCardNumber,
      String currency,
      DateTime createdAt,
    )?
    creditCard,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
      String id,
      String userId,
      String name,
      BankName bank,
      double balance,
      String currency,
      String? iban,
      String? maskedAccountNumber,
      DateTime createdAt,
    )?
    bankAccount,
    TResult Function(
      String id,
      String userId,
      String name,
      BankName bank,
      double creditLimit,
      double usedAmount,
      double statementBalance,
      double minimumPayment,
      int statementClosingDay,
      int paymentDueDay,
      String? maskedCardNumber,
      String currency,
      DateTime createdAt,
    )?
    creditCard,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(BankAccountEntity value) bankAccount,
    required TResult Function(CreditCardEntity value) creditCard,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(BankAccountEntity value)? bankAccount,
    TResult? Function(CreditCardEntity value)? creditCard,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(BankAccountEntity value)? bankAccount,
    TResult Function(CreditCardEntity value)? creditCard,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;

  /// Create a copy of FinancialAccountEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FinancialAccountEntityCopyWith<FinancialAccountEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FinancialAccountEntityCopyWith<$Res> {
  factory $FinancialAccountEntityCopyWith(
    FinancialAccountEntity value,
    $Res Function(FinancialAccountEntity) then,
  ) = _$FinancialAccountEntityCopyWithImpl<$Res, FinancialAccountEntity>;
  @useResult
  $Res call({
    String id,
    String userId,
    String name,
    BankName bank,
    String currency,
    DateTime createdAt,
  });
}

/// @nodoc
class _$FinancialAccountEntityCopyWithImpl<
  $Res,
  $Val extends FinancialAccountEntity
>
    implements $FinancialAccountEntityCopyWith<$Res> {
  _$FinancialAccountEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FinancialAccountEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? bank = null,
    Object? currency = null,
    Object? createdAt = null,
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
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            bank: null == bank
                ? _value.bank
                : bank // ignore: cast_nullable_to_non_nullable
                      as BankName,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BankAccountEntityImplCopyWith<$Res>
    implements $FinancialAccountEntityCopyWith<$Res> {
  factory _$$BankAccountEntityImplCopyWith(
    _$BankAccountEntityImpl value,
    $Res Function(_$BankAccountEntityImpl) then,
  ) = __$$BankAccountEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String name,
    BankName bank,
    double balance,
    String currency,
    String? iban,
    String? maskedAccountNumber,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$BankAccountEntityImplCopyWithImpl<$Res>
    extends _$FinancialAccountEntityCopyWithImpl<$Res, _$BankAccountEntityImpl>
    implements _$$BankAccountEntityImplCopyWith<$Res> {
  __$$BankAccountEntityImplCopyWithImpl(
    _$BankAccountEntityImpl _value,
    $Res Function(_$BankAccountEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FinancialAccountEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? bank = null,
    Object? balance = null,
    Object? currency = null,
    Object? iban = freezed,
    Object? maskedAccountNumber = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$BankAccountEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        bank: null == bank
            ? _value.bank
            : bank // ignore: cast_nullable_to_non_nullable
                  as BankName,
        balance: null == balance
            ? _value.balance
            : balance // ignore: cast_nullable_to_non_nullable
                  as double,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        iban: freezed == iban
            ? _value.iban
            : iban // ignore: cast_nullable_to_non_nullable
                  as String?,
        maskedAccountNumber: freezed == maskedAccountNumber
            ? _value.maskedAccountNumber
            : maskedAccountNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$BankAccountEntityImpl implements BankAccountEntity {
  const _$BankAccountEntityImpl({
    required this.id,
    required this.userId,
    required this.name,
    required this.bank,
    required this.balance,
    this.currency = 'TRY',
    this.iban,
    this.maskedAccountNumber,
    required this.createdAt,
  });

  @override
  final String id;
  @override
  final String userId;
  @override
  final String name;
  @override
  final BankName bank;
  @override
  final double balance;
  @override
  @JsonKey()
  final String currency;
  @override
  final String? iban;
  @override
  final String? maskedAccountNumber;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'FinancialAccountEntity.bankAccount(id: $id, userId: $userId, name: $name, bank: $bank, balance: $balance, currency: $currency, iban: $iban, maskedAccountNumber: $maskedAccountNumber, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BankAccountEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.bank, bank) || other.bank == bank) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.iban, iban) || other.iban == iban) &&
            (identical(other.maskedAccountNumber, maskedAccountNumber) ||
                other.maskedAccountNumber == maskedAccountNumber) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    name,
    bank,
    balance,
    currency,
    iban,
    maskedAccountNumber,
    createdAt,
  );

  /// Create a copy of FinancialAccountEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BankAccountEntityImplCopyWith<_$BankAccountEntityImpl> get copyWith =>
      __$$BankAccountEntityImplCopyWithImpl<_$BankAccountEntityImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String id,
      String userId,
      String name,
      BankName bank,
      double balance,
      String currency,
      String? iban,
      String? maskedAccountNumber,
      DateTime createdAt,
    )
    bankAccount,
    required TResult Function(
      String id,
      String userId,
      String name,
      BankName bank,
      double creditLimit,
      double usedAmount,
      double statementBalance,
      double minimumPayment,
      int statementClosingDay,
      int paymentDueDay,
      String? maskedCardNumber,
      String currency,
      DateTime createdAt,
    )
    creditCard,
  }) {
    return bankAccount(
      id,
      userId,
      name,
      bank,
      balance,
      currency,
      iban,
      maskedAccountNumber,
      createdAt,
    );
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String id,
      String userId,
      String name,
      BankName bank,
      double balance,
      String currency,
      String? iban,
      String? maskedAccountNumber,
      DateTime createdAt,
    )?
    bankAccount,
    TResult? Function(
      String id,
      String userId,
      String name,
      BankName bank,
      double creditLimit,
      double usedAmount,
      double statementBalance,
      double minimumPayment,
      int statementClosingDay,
      int paymentDueDay,
      String? maskedCardNumber,
      String currency,
      DateTime createdAt,
    )?
    creditCard,
  }) {
    return bankAccount?.call(
      id,
      userId,
      name,
      bank,
      balance,
      currency,
      iban,
      maskedAccountNumber,
      createdAt,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
      String id,
      String userId,
      String name,
      BankName bank,
      double balance,
      String currency,
      String? iban,
      String? maskedAccountNumber,
      DateTime createdAt,
    )?
    bankAccount,
    TResult Function(
      String id,
      String userId,
      String name,
      BankName bank,
      double creditLimit,
      double usedAmount,
      double statementBalance,
      double minimumPayment,
      int statementClosingDay,
      int paymentDueDay,
      String? maskedCardNumber,
      String currency,
      DateTime createdAt,
    )?
    creditCard,
    required TResult orElse(),
  }) {
    if (bankAccount != null) {
      return bankAccount(
        id,
        userId,
        name,
        bank,
        balance,
        currency,
        iban,
        maskedAccountNumber,
        createdAt,
      );
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(BankAccountEntity value) bankAccount,
    required TResult Function(CreditCardEntity value) creditCard,
  }) {
    return bankAccount(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(BankAccountEntity value)? bankAccount,
    TResult? Function(CreditCardEntity value)? creditCard,
  }) {
    return bankAccount?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(BankAccountEntity value)? bankAccount,
    TResult Function(CreditCardEntity value)? creditCard,
    required TResult orElse(),
  }) {
    if (bankAccount != null) {
      return bankAccount(this);
    }
    return orElse();
  }
}

abstract class BankAccountEntity implements FinancialAccountEntity {
  const factory BankAccountEntity({
    required final String id,
    required final String userId,
    required final String name,
    required final BankName bank,
    required final double balance,
    final String currency,
    final String? iban,
    final String? maskedAccountNumber,
    required final DateTime createdAt,
  }) = _$BankAccountEntityImpl;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get name;
  @override
  BankName get bank;
  double get balance;
  @override
  String get currency;
  String? get iban;
  String? get maskedAccountNumber;
  @override
  DateTime get createdAt;

  /// Create a copy of FinancialAccountEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BankAccountEntityImplCopyWith<_$BankAccountEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CreditCardEntityImplCopyWith<$Res>
    implements $FinancialAccountEntityCopyWith<$Res> {
  factory _$$CreditCardEntityImplCopyWith(
    _$CreditCardEntityImpl value,
    $Res Function(_$CreditCardEntityImpl) then,
  ) = __$$CreditCardEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String name,
    BankName bank,
    double creditLimit,
    double usedAmount,
    double statementBalance,
    double minimumPayment,
    int statementClosingDay,
    int paymentDueDay,
    String? maskedCardNumber,
    String currency,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$CreditCardEntityImplCopyWithImpl<$Res>
    extends _$FinancialAccountEntityCopyWithImpl<$Res, _$CreditCardEntityImpl>
    implements _$$CreditCardEntityImplCopyWith<$Res> {
  __$$CreditCardEntityImplCopyWithImpl(
    _$CreditCardEntityImpl _value,
    $Res Function(_$CreditCardEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FinancialAccountEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? bank = null,
    Object? creditLimit = null,
    Object? usedAmount = null,
    Object? statementBalance = null,
    Object? minimumPayment = null,
    Object? statementClosingDay = null,
    Object? paymentDueDay = null,
    Object? maskedCardNumber = freezed,
    Object? currency = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$CreditCardEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        bank: null == bank
            ? _value.bank
            : bank // ignore: cast_nullable_to_non_nullable
                  as BankName,
        creditLimit: null == creditLimit
            ? _value.creditLimit
            : creditLimit // ignore: cast_nullable_to_non_nullable
                  as double,
        usedAmount: null == usedAmount
            ? _value.usedAmount
            : usedAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        statementBalance: null == statementBalance
            ? _value.statementBalance
            : statementBalance // ignore: cast_nullable_to_non_nullable
                  as double,
        minimumPayment: null == minimumPayment
            ? _value.minimumPayment
            : minimumPayment // ignore: cast_nullable_to_non_nullable
                  as double,
        statementClosingDay: null == statementClosingDay
            ? _value.statementClosingDay
            : statementClosingDay // ignore: cast_nullable_to_non_nullable
                  as int,
        paymentDueDay: null == paymentDueDay
            ? _value.paymentDueDay
            : paymentDueDay // ignore: cast_nullable_to_non_nullable
                  as int,
        maskedCardNumber: freezed == maskedCardNumber
            ? _value.maskedCardNumber
            : maskedCardNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$CreditCardEntityImpl implements CreditCardEntity {
  const _$CreditCardEntityImpl({
    required this.id,
    required this.userId,
    required this.name,
    required this.bank,
    required this.creditLimit,
    required this.usedAmount,
    required this.statementBalance,
    required this.minimumPayment,
    required this.statementClosingDay,
    required this.paymentDueDay,
    this.maskedCardNumber,
    this.currency = 'TRY',
    required this.createdAt,
  });

  @override
  final String id;
  @override
  final String userId;
  @override
  final String name;
  @override
  final BankName bank;
  @override
  final double creditLimit;
  @override
  final double usedAmount;
  @override
  final double statementBalance;
  @override
  final double minimumPayment;
  @override
  final int statementClosingDay;
  @override
  final int paymentDueDay;
  @override
  final String? maskedCardNumber;
  @override
  @JsonKey()
  final String currency;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'FinancialAccountEntity.creditCard(id: $id, userId: $userId, name: $name, bank: $bank, creditLimit: $creditLimit, usedAmount: $usedAmount, statementBalance: $statementBalance, minimumPayment: $minimumPayment, statementClosingDay: $statementClosingDay, paymentDueDay: $paymentDueDay, maskedCardNumber: $maskedCardNumber, currency: $currency, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreditCardEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.bank, bank) || other.bank == bank) &&
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
                other.maskedCardNumber == maskedCardNumber) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    name,
    bank,
    creditLimit,
    usedAmount,
    statementBalance,
    minimumPayment,
    statementClosingDay,
    paymentDueDay,
    maskedCardNumber,
    currency,
    createdAt,
  );

  /// Create a copy of FinancialAccountEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreditCardEntityImplCopyWith<_$CreditCardEntityImpl> get copyWith =>
      __$$CreditCardEntityImplCopyWithImpl<_$CreditCardEntityImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String id,
      String userId,
      String name,
      BankName bank,
      double balance,
      String currency,
      String? iban,
      String? maskedAccountNumber,
      DateTime createdAt,
    )
    bankAccount,
    required TResult Function(
      String id,
      String userId,
      String name,
      BankName bank,
      double creditLimit,
      double usedAmount,
      double statementBalance,
      double minimumPayment,
      int statementClosingDay,
      int paymentDueDay,
      String? maskedCardNumber,
      String currency,
      DateTime createdAt,
    )
    creditCard,
  }) {
    return creditCard(
      id,
      userId,
      name,
      bank,
      creditLimit,
      usedAmount,
      statementBalance,
      minimumPayment,
      statementClosingDay,
      paymentDueDay,
      maskedCardNumber,
      currency,
      createdAt,
    );
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String id,
      String userId,
      String name,
      BankName bank,
      double balance,
      String currency,
      String? iban,
      String? maskedAccountNumber,
      DateTime createdAt,
    )?
    bankAccount,
    TResult? Function(
      String id,
      String userId,
      String name,
      BankName bank,
      double creditLimit,
      double usedAmount,
      double statementBalance,
      double minimumPayment,
      int statementClosingDay,
      int paymentDueDay,
      String? maskedCardNumber,
      String currency,
      DateTime createdAt,
    )?
    creditCard,
  }) {
    return creditCard?.call(
      id,
      userId,
      name,
      bank,
      creditLimit,
      usedAmount,
      statementBalance,
      minimumPayment,
      statementClosingDay,
      paymentDueDay,
      maskedCardNumber,
      currency,
      createdAt,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
      String id,
      String userId,
      String name,
      BankName bank,
      double balance,
      String currency,
      String? iban,
      String? maskedAccountNumber,
      DateTime createdAt,
    )?
    bankAccount,
    TResult Function(
      String id,
      String userId,
      String name,
      BankName bank,
      double creditLimit,
      double usedAmount,
      double statementBalance,
      double minimumPayment,
      int statementClosingDay,
      int paymentDueDay,
      String? maskedCardNumber,
      String currency,
      DateTime createdAt,
    )?
    creditCard,
    required TResult orElse(),
  }) {
    if (creditCard != null) {
      return creditCard(
        id,
        userId,
        name,
        bank,
        creditLimit,
        usedAmount,
        statementBalance,
        minimumPayment,
        statementClosingDay,
        paymentDueDay,
        maskedCardNumber,
        currency,
        createdAt,
      );
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(BankAccountEntity value) bankAccount,
    required TResult Function(CreditCardEntity value) creditCard,
  }) {
    return creditCard(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(BankAccountEntity value)? bankAccount,
    TResult? Function(CreditCardEntity value)? creditCard,
  }) {
    return creditCard?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(BankAccountEntity value)? bankAccount,
    TResult Function(CreditCardEntity value)? creditCard,
    required TResult orElse(),
  }) {
    if (creditCard != null) {
      return creditCard(this);
    }
    return orElse();
  }
}

abstract class CreditCardEntity implements FinancialAccountEntity {
  const factory CreditCardEntity({
    required final String id,
    required final String userId,
    required final String name,
    required final BankName bank,
    required final double creditLimit,
    required final double usedAmount,
    required final double statementBalance,
    required final double minimumPayment,
    required final int statementClosingDay,
    required final int paymentDueDay,
    final String? maskedCardNumber,
    final String currency,
    required final DateTime createdAt,
  }) = _$CreditCardEntityImpl;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get name;
  @override
  BankName get bank;
  double get creditLimit;
  double get usedAmount;
  double get statementBalance;
  double get minimumPayment;
  int get statementClosingDay;
  int get paymentDueDay;
  String? get maskedCardNumber;
  @override
  String get currency;
  @override
  DateTime get createdAt;

  /// Create a copy of FinancialAccountEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreditCardEntityImplCopyWith<_$CreditCardEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
