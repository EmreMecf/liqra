// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'accounts_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AccountsState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<FinancialAccountEntity> accounts,
      Map<String, List<AccountTransactionEntity>> transactionsByAccount,
      String? selectedAccountId,
    )
    loaded,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<FinancialAccountEntity> accounts,
      Map<String, List<AccountTransactionEntity>> transactionsByAccount,
      String? selectedAccountId,
    )?
    loaded,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<FinancialAccountEntity> accounts,
      Map<String, List<AccountTransactionEntity>> transactionsByAccount,
      String? selectedAccountId,
    )?
    loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountsInitial value) initial,
    required TResult Function(AccountsLoading value) loading,
    required TResult Function(AccountsLoaded value) loaded,
    required TResult Function(AccountsError value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountsInitial value)? initial,
    TResult? Function(AccountsLoading value)? loading,
    TResult? Function(AccountsLoaded value)? loaded,
    TResult? Function(AccountsError value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountsInitial value)? initial,
    TResult Function(AccountsLoading value)? loading,
    TResult Function(AccountsLoaded value)? loaded,
    TResult Function(AccountsError value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountsStateCopyWith<$Res> {
  factory $AccountsStateCopyWith(
    AccountsState value,
    $Res Function(AccountsState) then,
  ) = _$AccountsStateCopyWithImpl<$Res, AccountsState>;
}

/// @nodoc
class _$AccountsStateCopyWithImpl<$Res, $Val extends AccountsState>
    implements $AccountsStateCopyWith<$Res> {
  _$AccountsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AccountsState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$AccountsInitialImplCopyWith<$Res> {
  factory _$$AccountsInitialImplCopyWith(
    _$AccountsInitialImpl value,
    $Res Function(_$AccountsInitialImpl) then,
  ) = __$$AccountsInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$AccountsInitialImplCopyWithImpl<$Res>
    extends _$AccountsStateCopyWithImpl<$Res, _$AccountsInitialImpl>
    implements _$$AccountsInitialImplCopyWith<$Res> {
  __$$AccountsInitialImplCopyWithImpl(
    _$AccountsInitialImpl _value,
    $Res Function(_$AccountsInitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountsState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$AccountsInitialImpl implements AccountsInitial {
  const _$AccountsInitialImpl();

  @override
  String toString() {
    return 'AccountsState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$AccountsInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<FinancialAccountEntity> accounts,
      Map<String, List<AccountTransactionEntity>> transactionsByAccount,
      String? selectedAccountId,
    )
    loaded,
    required TResult Function(String message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<FinancialAccountEntity> accounts,
      Map<String, List<AccountTransactionEntity>> transactionsByAccount,
      String? selectedAccountId,
    )?
    loaded,
    TResult? Function(String message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<FinancialAccountEntity> accounts,
      Map<String, List<AccountTransactionEntity>> transactionsByAccount,
      String? selectedAccountId,
    )?
    loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountsInitial value) initial,
    required TResult Function(AccountsLoading value) loading,
    required TResult Function(AccountsLoaded value) loaded,
    required TResult Function(AccountsError value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountsInitial value)? initial,
    TResult? Function(AccountsLoading value)? loading,
    TResult? Function(AccountsLoaded value)? loaded,
    TResult? Function(AccountsError value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountsInitial value)? initial,
    TResult Function(AccountsLoading value)? loading,
    TResult Function(AccountsLoaded value)? loaded,
    TResult Function(AccountsError value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class AccountsInitial implements AccountsState {
  const factory AccountsInitial() = _$AccountsInitialImpl;
}

/// @nodoc
abstract class _$$AccountsLoadingImplCopyWith<$Res> {
  factory _$$AccountsLoadingImplCopyWith(
    _$AccountsLoadingImpl value,
    $Res Function(_$AccountsLoadingImpl) then,
  ) = __$$AccountsLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$AccountsLoadingImplCopyWithImpl<$Res>
    extends _$AccountsStateCopyWithImpl<$Res, _$AccountsLoadingImpl>
    implements _$$AccountsLoadingImplCopyWith<$Res> {
  __$$AccountsLoadingImplCopyWithImpl(
    _$AccountsLoadingImpl _value,
    $Res Function(_$AccountsLoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountsState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$AccountsLoadingImpl implements AccountsLoading {
  const _$AccountsLoadingImpl();

  @override
  String toString() {
    return 'AccountsState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$AccountsLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<FinancialAccountEntity> accounts,
      Map<String, List<AccountTransactionEntity>> transactionsByAccount,
      String? selectedAccountId,
    )
    loaded,
    required TResult Function(String message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<FinancialAccountEntity> accounts,
      Map<String, List<AccountTransactionEntity>> transactionsByAccount,
      String? selectedAccountId,
    )?
    loaded,
    TResult? Function(String message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<FinancialAccountEntity> accounts,
      Map<String, List<AccountTransactionEntity>> transactionsByAccount,
      String? selectedAccountId,
    )?
    loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountsInitial value) initial,
    required TResult Function(AccountsLoading value) loading,
    required TResult Function(AccountsLoaded value) loaded,
    required TResult Function(AccountsError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountsInitial value)? initial,
    TResult? Function(AccountsLoading value)? loading,
    TResult? Function(AccountsLoaded value)? loaded,
    TResult? Function(AccountsError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountsInitial value)? initial,
    TResult Function(AccountsLoading value)? loading,
    TResult Function(AccountsLoaded value)? loaded,
    TResult Function(AccountsError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class AccountsLoading implements AccountsState {
  const factory AccountsLoading() = _$AccountsLoadingImpl;
}

/// @nodoc
abstract class _$$AccountsLoadedImplCopyWith<$Res> {
  factory _$$AccountsLoadedImplCopyWith(
    _$AccountsLoadedImpl value,
    $Res Function(_$AccountsLoadedImpl) then,
  ) = __$$AccountsLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    List<FinancialAccountEntity> accounts,
    Map<String, List<AccountTransactionEntity>> transactionsByAccount,
    String? selectedAccountId,
  });
}

/// @nodoc
class __$$AccountsLoadedImplCopyWithImpl<$Res>
    extends _$AccountsStateCopyWithImpl<$Res, _$AccountsLoadedImpl>
    implements _$$AccountsLoadedImplCopyWith<$Res> {
  __$$AccountsLoadedImplCopyWithImpl(
    _$AccountsLoadedImpl _value,
    $Res Function(_$AccountsLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accounts = null,
    Object? transactionsByAccount = null,
    Object? selectedAccountId = freezed,
  }) {
    return _then(
      _$AccountsLoadedImpl(
        accounts: null == accounts
            ? _value._accounts
            : accounts // ignore: cast_nullable_to_non_nullable
                  as List<FinancialAccountEntity>,
        transactionsByAccount: null == transactionsByAccount
            ? _value._transactionsByAccount
            : transactionsByAccount // ignore: cast_nullable_to_non_nullable
                  as Map<String, List<AccountTransactionEntity>>,
        selectedAccountId: freezed == selectedAccountId
            ? _value.selectedAccountId
            : selectedAccountId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$AccountsLoadedImpl implements AccountsLoaded {
  const _$AccountsLoadedImpl({
    required final List<FinancialAccountEntity> accounts,
    required final Map<String, List<AccountTransactionEntity>>
    transactionsByAccount,
    this.selectedAccountId,
  }) : _accounts = accounts,
       _transactionsByAccount = transactionsByAccount;

  final List<FinancialAccountEntity> _accounts;
  @override
  List<FinancialAccountEntity> get accounts {
    if (_accounts is EqualUnmodifiableListView) return _accounts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_accounts);
  }

  final Map<String, List<AccountTransactionEntity>> _transactionsByAccount;
  @override
  Map<String, List<AccountTransactionEntity>> get transactionsByAccount {
    if (_transactionsByAccount is EqualUnmodifiableMapView)
      return _transactionsByAccount;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_transactionsByAccount);
  }

  @override
  final String? selectedAccountId;

  @override
  String toString() {
    return 'AccountsState.loaded(accounts: $accounts, transactionsByAccount: $transactionsByAccount, selectedAccountId: $selectedAccountId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountsLoadedImpl &&
            const DeepCollectionEquality().equals(other._accounts, _accounts) &&
            const DeepCollectionEquality().equals(
              other._transactionsByAccount,
              _transactionsByAccount,
            ) &&
            (identical(other.selectedAccountId, selectedAccountId) ||
                other.selectedAccountId == selectedAccountId));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_accounts),
    const DeepCollectionEquality().hash(_transactionsByAccount),
    selectedAccountId,
  );

  /// Create a copy of AccountsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountsLoadedImplCopyWith<_$AccountsLoadedImpl> get copyWith =>
      __$$AccountsLoadedImplCopyWithImpl<_$AccountsLoadedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<FinancialAccountEntity> accounts,
      Map<String, List<AccountTransactionEntity>> transactionsByAccount,
      String? selectedAccountId,
    )
    loaded,
    required TResult Function(String message) error,
  }) {
    return loaded(accounts, transactionsByAccount, selectedAccountId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<FinancialAccountEntity> accounts,
      Map<String, List<AccountTransactionEntity>> transactionsByAccount,
      String? selectedAccountId,
    )?
    loaded,
    TResult? Function(String message)? error,
  }) {
    return loaded?.call(accounts, transactionsByAccount, selectedAccountId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<FinancialAccountEntity> accounts,
      Map<String, List<AccountTransactionEntity>> transactionsByAccount,
      String? selectedAccountId,
    )?
    loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(accounts, transactionsByAccount, selectedAccountId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountsInitial value) initial,
    required TResult Function(AccountsLoading value) loading,
    required TResult Function(AccountsLoaded value) loaded,
    required TResult Function(AccountsError value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountsInitial value)? initial,
    TResult? Function(AccountsLoading value)? loading,
    TResult? Function(AccountsLoaded value)? loaded,
    TResult? Function(AccountsError value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountsInitial value)? initial,
    TResult Function(AccountsLoading value)? loading,
    TResult Function(AccountsLoaded value)? loaded,
    TResult Function(AccountsError value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class AccountsLoaded implements AccountsState {
  const factory AccountsLoaded({
    required final List<FinancialAccountEntity> accounts,
    required final Map<String, List<AccountTransactionEntity>>
    transactionsByAccount,
    final String? selectedAccountId,
  }) = _$AccountsLoadedImpl;

  List<FinancialAccountEntity> get accounts;
  Map<String, List<AccountTransactionEntity>> get transactionsByAccount;
  String? get selectedAccountId;

  /// Create a copy of AccountsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountsLoadedImplCopyWith<_$AccountsLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AccountsErrorImplCopyWith<$Res> {
  factory _$$AccountsErrorImplCopyWith(
    _$AccountsErrorImpl value,
    $Res Function(_$AccountsErrorImpl) then,
  ) = __$$AccountsErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$AccountsErrorImplCopyWithImpl<$Res>
    extends _$AccountsStateCopyWithImpl<$Res, _$AccountsErrorImpl>
    implements _$$AccountsErrorImplCopyWith<$Res> {
  __$$AccountsErrorImplCopyWithImpl(
    _$AccountsErrorImpl _value,
    $Res Function(_$AccountsErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$AccountsErrorImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$AccountsErrorImpl implements AccountsError {
  const _$AccountsErrorImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'AccountsState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountsErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of AccountsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountsErrorImplCopyWith<_$AccountsErrorImpl> get copyWith =>
      __$$AccountsErrorImplCopyWithImpl<_$AccountsErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<FinancialAccountEntity> accounts,
      Map<String, List<AccountTransactionEntity>> transactionsByAccount,
      String? selectedAccountId,
    )
    loaded,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<FinancialAccountEntity> accounts,
      Map<String, List<AccountTransactionEntity>> transactionsByAccount,
      String? selectedAccountId,
    )?
    loaded,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<FinancialAccountEntity> accounts,
      Map<String, List<AccountTransactionEntity>> transactionsByAccount,
      String? selectedAccountId,
    )?
    loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountsInitial value) initial,
    required TResult Function(AccountsLoading value) loading,
    required TResult Function(AccountsLoaded value) loaded,
    required TResult Function(AccountsError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountsInitial value)? initial,
    TResult? Function(AccountsLoading value)? loading,
    TResult? Function(AccountsLoaded value)? loaded,
    TResult? Function(AccountsError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountsInitial value)? initial,
    TResult Function(AccountsLoading value)? loading,
    TResult Function(AccountsLoaded value)? loaded,
    TResult Function(AccountsError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class AccountsError implements AccountsState {
  const factory AccountsError({required final String message}) =
      _$AccountsErrorImpl;

  String get message;

  /// Create a copy of AccountsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountsErrorImplCopyWith<_$AccountsErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
