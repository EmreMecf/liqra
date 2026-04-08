// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'spending_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SpendingState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<TransactionEntity> transactions,
      MonthlySummaryEntity summary,
      String? filterCategory,
    )
    loaded,
    required TResult Function(
      String message,
      List<TransactionEntity>? previousTransactions,
    )
    error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<TransactionEntity> transactions,
      MonthlySummaryEntity summary,
      String? filterCategory,
    )?
    loaded,
    TResult? Function(
      String message,
      List<TransactionEntity>? previousTransactions,
    )?
    error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<TransactionEntity> transactions,
      MonthlySummaryEntity summary,
      String? filterCategory,
    )?
    loaded,
    TResult Function(
      String message,
      List<TransactionEntity>? previousTransactions,
    )?
    error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SpendingInitial value) initial,
    required TResult Function(SpendingLoading value) loading,
    required TResult Function(SpendingLoaded value) loaded,
    required TResult Function(SpendingError value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SpendingInitial value)? initial,
    TResult? Function(SpendingLoading value)? loading,
    TResult? Function(SpendingLoaded value)? loaded,
    TResult? Function(SpendingError value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SpendingInitial value)? initial,
    TResult Function(SpendingLoading value)? loading,
    TResult Function(SpendingLoaded value)? loaded,
    TResult Function(SpendingError value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpendingStateCopyWith<$Res> {
  factory $SpendingStateCopyWith(
    SpendingState value,
    $Res Function(SpendingState) then,
  ) = _$SpendingStateCopyWithImpl<$Res, SpendingState>;
}

/// @nodoc
class _$SpendingStateCopyWithImpl<$Res, $Val extends SpendingState>
    implements $SpendingStateCopyWith<$Res> {
  _$SpendingStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpendingState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$SpendingInitialImplCopyWith<$Res> {
  factory _$$SpendingInitialImplCopyWith(
    _$SpendingInitialImpl value,
    $Res Function(_$SpendingInitialImpl) then,
  ) = __$$SpendingInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SpendingInitialImplCopyWithImpl<$Res>
    extends _$SpendingStateCopyWithImpl<$Res, _$SpendingInitialImpl>
    implements _$$SpendingInitialImplCopyWith<$Res> {
  __$$SpendingInitialImplCopyWithImpl(
    _$SpendingInitialImpl _value,
    $Res Function(_$SpendingInitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SpendingState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$SpendingInitialImpl implements SpendingInitial {
  const _$SpendingInitialImpl();

  @override
  String toString() {
    return 'SpendingState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$SpendingInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<TransactionEntity> transactions,
      MonthlySummaryEntity summary,
      String? filterCategory,
    )
    loaded,
    required TResult Function(
      String message,
      List<TransactionEntity>? previousTransactions,
    )
    error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<TransactionEntity> transactions,
      MonthlySummaryEntity summary,
      String? filterCategory,
    )?
    loaded,
    TResult? Function(
      String message,
      List<TransactionEntity>? previousTransactions,
    )?
    error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<TransactionEntity> transactions,
      MonthlySummaryEntity summary,
      String? filterCategory,
    )?
    loaded,
    TResult Function(
      String message,
      List<TransactionEntity>? previousTransactions,
    )?
    error,
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
    required TResult Function(SpendingInitial value) initial,
    required TResult Function(SpendingLoading value) loading,
    required TResult Function(SpendingLoaded value) loaded,
    required TResult Function(SpendingError value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SpendingInitial value)? initial,
    TResult? Function(SpendingLoading value)? loading,
    TResult? Function(SpendingLoaded value)? loaded,
    TResult? Function(SpendingError value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SpendingInitial value)? initial,
    TResult Function(SpendingLoading value)? loading,
    TResult Function(SpendingLoaded value)? loaded,
    TResult Function(SpendingError value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class SpendingInitial implements SpendingState {
  const factory SpendingInitial() = _$SpendingInitialImpl;
}

/// @nodoc
abstract class _$$SpendingLoadingImplCopyWith<$Res> {
  factory _$$SpendingLoadingImplCopyWith(
    _$SpendingLoadingImpl value,
    $Res Function(_$SpendingLoadingImpl) then,
  ) = __$$SpendingLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SpendingLoadingImplCopyWithImpl<$Res>
    extends _$SpendingStateCopyWithImpl<$Res, _$SpendingLoadingImpl>
    implements _$$SpendingLoadingImplCopyWith<$Res> {
  __$$SpendingLoadingImplCopyWithImpl(
    _$SpendingLoadingImpl _value,
    $Res Function(_$SpendingLoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SpendingState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$SpendingLoadingImpl implements SpendingLoading {
  const _$SpendingLoadingImpl();

  @override
  String toString() {
    return 'SpendingState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$SpendingLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<TransactionEntity> transactions,
      MonthlySummaryEntity summary,
      String? filterCategory,
    )
    loaded,
    required TResult Function(
      String message,
      List<TransactionEntity>? previousTransactions,
    )
    error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<TransactionEntity> transactions,
      MonthlySummaryEntity summary,
      String? filterCategory,
    )?
    loaded,
    TResult? Function(
      String message,
      List<TransactionEntity>? previousTransactions,
    )?
    error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<TransactionEntity> transactions,
      MonthlySummaryEntity summary,
      String? filterCategory,
    )?
    loaded,
    TResult Function(
      String message,
      List<TransactionEntity>? previousTransactions,
    )?
    error,
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
    required TResult Function(SpendingInitial value) initial,
    required TResult Function(SpendingLoading value) loading,
    required TResult Function(SpendingLoaded value) loaded,
    required TResult Function(SpendingError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SpendingInitial value)? initial,
    TResult? Function(SpendingLoading value)? loading,
    TResult? Function(SpendingLoaded value)? loaded,
    TResult? Function(SpendingError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SpendingInitial value)? initial,
    TResult Function(SpendingLoading value)? loading,
    TResult Function(SpendingLoaded value)? loaded,
    TResult Function(SpendingError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class SpendingLoading implements SpendingState {
  const factory SpendingLoading() = _$SpendingLoadingImpl;
}

/// @nodoc
abstract class _$$SpendingLoadedImplCopyWith<$Res> {
  factory _$$SpendingLoadedImplCopyWith(
    _$SpendingLoadedImpl value,
    $Res Function(_$SpendingLoadedImpl) then,
  ) = __$$SpendingLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    List<TransactionEntity> transactions,
    MonthlySummaryEntity summary,
    String? filterCategory,
  });

  $MonthlySummaryEntityCopyWith<$Res> get summary;
}

/// @nodoc
class __$$SpendingLoadedImplCopyWithImpl<$Res>
    extends _$SpendingStateCopyWithImpl<$Res, _$SpendingLoadedImpl>
    implements _$$SpendingLoadedImplCopyWith<$Res> {
  __$$SpendingLoadedImplCopyWithImpl(
    _$SpendingLoadedImpl _value,
    $Res Function(_$SpendingLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SpendingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transactions = null,
    Object? summary = null,
    Object? filterCategory = freezed,
  }) {
    return _then(
      _$SpendingLoadedImpl(
        transactions: null == transactions
            ? _value._transactions
            : transactions // ignore: cast_nullable_to_non_nullable
                  as List<TransactionEntity>,
        summary: null == summary
            ? _value.summary
            : summary // ignore: cast_nullable_to_non_nullable
                  as MonthlySummaryEntity,
        filterCategory: freezed == filterCategory
            ? _value.filterCategory
            : filterCategory // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }

  /// Create a copy of SpendingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MonthlySummaryEntityCopyWith<$Res> get summary {
    return $MonthlySummaryEntityCopyWith<$Res>(_value.summary, (value) {
      return _then(_value.copyWith(summary: value));
    });
  }
}

/// @nodoc

class _$SpendingLoadedImpl implements SpendingLoaded {
  const _$SpendingLoadedImpl({
    required final List<TransactionEntity> transactions,
    required this.summary,
    this.filterCategory,
  }) : _transactions = transactions;

  final List<TransactionEntity> _transactions;
  @override
  List<TransactionEntity> get transactions {
    if (_transactions is EqualUnmodifiableListView) return _transactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_transactions);
  }

  @override
  final MonthlySummaryEntity summary;
  @override
  final String? filterCategory;

  @override
  String toString() {
    return 'SpendingState.loaded(transactions: $transactions, summary: $summary, filterCategory: $filterCategory)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpendingLoadedImpl &&
            const DeepCollectionEquality().equals(
              other._transactions,
              _transactions,
            ) &&
            (identical(other.summary, summary) || other.summary == summary) &&
            (identical(other.filterCategory, filterCategory) ||
                other.filterCategory == filterCategory));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_transactions),
    summary,
    filterCategory,
  );

  /// Create a copy of SpendingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpendingLoadedImplCopyWith<_$SpendingLoadedImpl> get copyWith =>
      __$$SpendingLoadedImplCopyWithImpl<_$SpendingLoadedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<TransactionEntity> transactions,
      MonthlySummaryEntity summary,
      String? filterCategory,
    )
    loaded,
    required TResult Function(
      String message,
      List<TransactionEntity>? previousTransactions,
    )
    error,
  }) {
    return loaded(transactions, summary, filterCategory);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<TransactionEntity> transactions,
      MonthlySummaryEntity summary,
      String? filterCategory,
    )?
    loaded,
    TResult? Function(
      String message,
      List<TransactionEntity>? previousTransactions,
    )?
    error,
  }) {
    return loaded?.call(transactions, summary, filterCategory);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<TransactionEntity> transactions,
      MonthlySummaryEntity summary,
      String? filterCategory,
    )?
    loaded,
    TResult Function(
      String message,
      List<TransactionEntity>? previousTransactions,
    )?
    error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(transactions, summary, filterCategory);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SpendingInitial value) initial,
    required TResult Function(SpendingLoading value) loading,
    required TResult Function(SpendingLoaded value) loaded,
    required TResult Function(SpendingError value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SpendingInitial value)? initial,
    TResult? Function(SpendingLoading value)? loading,
    TResult? Function(SpendingLoaded value)? loaded,
    TResult? Function(SpendingError value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SpendingInitial value)? initial,
    TResult Function(SpendingLoading value)? loading,
    TResult Function(SpendingLoaded value)? loaded,
    TResult Function(SpendingError value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class SpendingLoaded implements SpendingState {
  const factory SpendingLoaded({
    required final List<TransactionEntity> transactions,
    required final MonthlySummaryEntity summary,
    final String? filterCategory,
  }) = _$SpendingLoadedImpl;

  List<TransactionEntity> get transactions;
  MonthlySummaryEntity get summary;
  String? get filterCategory;

  /// Create a copy of SpendingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpendingLoadedImplCopyWith<_$SpendingLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SpendingErrorImplCopyWith<$Res> {
  factory _$$SpendingErrorImplCopyWith(
    _$SpendingErrorImpl value,
    $Res Function(_$SpendingErrorImpl) then,
  ) = __$$SpendingErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message, List<TransactionEntity>? previousTransactions});
}

/// @nodoc
class __$$SpendingErrorImplCopyWithImpl<$Res>
    extends _$SpendingStateCopyWithImpl<$Res, _$SpendingErrorImpl>
    implements _$$SpendingErrorImplCopyWith<$Res> {
  __$$SpendingErrorImplCopyWithImpl(
    _$SpendingErrorImpl _value,
    $Res Function(_$SpendingErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SpendingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null, Object? previousTransactions = freezed}) {
    return _then(
      _$SpendingErrorImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        previousTransactions: freezed == previousTransactions
            ? _value._previousTransactions
            : previousTransactions // ignore: cast_nullable_to_non_nullable
                  as List<TransactionEntity>?,
      ),
    );
  }
}

/// @nodoc

class _$SpendingErrorImpl implements SpendingError {
  const _$SpendingErrorImpl({
    required this.message,
    final List<TransactionEntity>? previousTransactions,
  }) : _previousTransactions = previousTransactions;

  @override
  final String message;
  final List<TransactionEntity>? _previousTransactions;
  @override
  List<TransactionEntity>? get previousTransactions {
    final value = _previousTransactions;
    if (value == null) return null;
    if (_previousTransactions is EqualUnmodifiableListView)
      return _previousTransactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'SpendingState.error(message: $message, previousTransactions: $previousTransactions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpendingErrorImpl &&
            (identical(other.message, message) || other.message == message) &&
            const DeepCollectionEquality().equals(
              other._previousTransactions,
              _previousTransactions,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    message,
    const DeepCollectionEquality().hash(_previousTransactions),
  );

  /// Create a copy of SpendingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpendingErrorImplCopyWith<_$SpendingErrorImpl> get copyWith =>
      __$$SpendingErrorImplCopyWithImpl<_$SpendingErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<TransactionEntity> transactions,
      MonthlySummaryEntity summary,
      String? filterCategory,
    )
    loaded,
    required TResult Function(
      String message,
      List<TransactionEntity>? previousTransactions,
    )
    error,
  }) {
    return error(message, previousTransactions);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<TransactionEntity> transactions,
      MonthlySummaryEntity summary,
      String? filterCategory,
    )?
    loaded,
    TResult? Function(
      String message,
      List<TransactionEntity>? previousTransactions,
    )?
    error,
  }) {
    return error?.call(message, previousTransactions);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<TransactionEntity> transactions,
      MonthlySummaryEntity summary,
      String? filterCategory,
    )?
    loaded,
    TResult Function(
      String message,
      List<TransactionEntity>? previousTransactions,
    )?
    error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message, previousTransactions);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SpendingInitial value) initial,
    required TResult Function(SpendingLoading value) loading,
    required TResult Function(SpendingLoaded value) loaded,
    required TResult Function(SpendingError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SpendingInitial value)? initial,
    TResult? Function(SpendingLoading value)? loading,
    TResult? Function(SpendingLoaded value)? loaded,
    TResult? Function(SpendingError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SpendingInitial value)? initial,
    TResult Function(SpendingLoading value)? loading,
    TResult Function(SpendingLoaded value)? loaded,
    TResult Function(SpendingError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class SpendingError implements SpendingState {
  const factory SpendingError({
    required final String message,
    final List<TransactionEntity>? previousTransactions,
  }) = _$SpendingErrorImpl;

  String get message;
  List<TransactionEntity>? get previousTransactions;

  /// Create a copy of SpendingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpendingErrorImplCopyWith<_$SpendingErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
