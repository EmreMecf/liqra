// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$TransactionEntity {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get source => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;

  /// Create a copy of TransactionEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransactionEntityCopyWith<TransactionEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransactionEntityCopyWith<$Res> {
  factory $TransactionEntityCopyWith(
    TransactionEntity value,
    $Res Function(TransactionEntity) then,
  ) = _$TransactionEntityCopyWithImpl<$Res, TransactionEntity>;
  @useResult
  $Res call({
    String id,
    String userId,
    double amount,
    String category,
    String type,
    String source,
    DateTime date,
    String? note,
  });
}

/// @nodoc
class _$TransactionEntityCopyWithImpl<$Res, $Val extends TransactionEntity>
    implements $TransactionEntityCopyWith<$Res> {
  _$TransactionEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TransactionEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? amount = null,
    Object? category = null,
    Object? type = null,
    Object? source = null,
    Object? date = null,
    Object? note = freezed,
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
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            source: null == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as String,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TransactionEntityImplCopyWith<$Res>
    implements $TransactionEntityCopyWith<$Res> {
  factory _$$TransactionEntityImplCopyWith(
    _$TransactionEntityImpl value,
    $Res Function(_$TransactionEntityImpl) then,
  ) = __$$TransactionEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    double amount,
    String category,
    String type,
    String source,
    DateTime date,
    String? note,
  });
}

/// @nodoc
class __$$TransactionEntityImplCopyWithImpl<$Res>
    extends _$TransactionEntityCopyWithImpl<$Res, _$TransactionEntityImpl>
    implements _$$TransactionEntityImplCopyWith<$Res> {
  __$$TransactionEntityImplCopyWithImpl(
    _$TransactionEntityImpl _value,
    $Res Function(_$TransactionEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TransactionEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? amount = null,
    Object? category = null,
    Object? type = null,
    Object? source = null,
    Object? date = null,
    Object? note = freezed,
  }) {
    return _then(
      _$TransactionEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        source: null == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$TransactionEntityImpl implements _TransactionEntity {
  const _$TransactionEntityImpl({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.type,
    required this.source,
    required this.date,
    this.note,
  });

  @override
  final String id;
  @override
  final String userId;
  @override
  final double amount;
  @override
  final String category;
  @override
  final String type;
  @override
  final String source;
  @override
  final DateTime date;
  @override
  final String? note;

  @override
  String toString() {
    return 'TransactionEntity(id: $id, userId: $userId, amount: $amount, category: $category, type: $type, source: $source, date: $date, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransactionEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.note, note) || other.note == note));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    amount,
    category,
    type,
    source,
    date,
    note,
  );

  /// Create a copy of TransactionEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransactionEntityImplCopyWith<_$TransactionEntityImpl> get copyWith =>
      __$$TransactionEntityImplCopyWithImpl<_$TransactionEntityImpl>(
        this,
        _$identity,
      );
}

abstract class _TransactionEntity implements TransactionEntity {
  const factory _TransactionEntity({
    required final String id,
    required final String userId,
    required final double amount,
    required final String category,
    required final String type,
    required final String source,
    required final DateTime date,
    final String? note,
  }) = _$TransactionEntityImpl;

  @override
  String get id;
  @override
  String get userId;
  @override
  double get amount;
  @override
  String get category;
  @override
  String get type;
  @override
  String get source;
  @override
  DateTime get date;
  @override
  String? get note;

  /// Create a copy of TransactionEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransactionEntityImplCopyWith<_$TransactionEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$MonthlySummaryEntity {
  double get totalIncome => throw _privateConstructorUsedError;
  double get totalExpenses => throw _privateConstructorUsedError;
  double get netCash => throw _privateConstructorUsedError;
  Map<String, double> get byCategory => throw _privateConstructorUsedError;
  int get year => throw _privateConstructorUsedError;
  int get month => throw _privateConstructorUsedError;

  /// Create a copy of MonthlySummaryEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MonthlySummaryEntityCopyWith<MonthlySummaryEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MonthlySummaryEntityCopyWith<$Res> {
  factory $MonthlySummaryEntityCopyWith(
    MonthlySummaryEntity value,
    $Res Function(MonthlySummaryEntity) then,
  ) = _$MonthlySummaryEntityCopyWithImpl<$Res, MonthlySummaryEntity>;
  @useResult
  $Res call({
    double totalIncome,
    double totalExpenses,
    double netCash,
    Map<String, double> byCategory,
    int year,
    int month,
  });
}

/// @nodoc
class _$MonthlySummaryEntityCopyWithImpl<
  $Res,
  $Val extends MonthlySummaryEntity
>
    implements $MonthlySummaryEntityCopyWith<$Res> {
  _$MonthlySummaryEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MonthlySummaryEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalIncome = null,
    Object? totalExpenses = null,
    Object? netCash = null,
    Object? byCategory = null,
    Object? year = null,
    Object? month = null,
  }) {
    return _then(
      _value.copyWith(
            totalIncome: null == totalIncome
                ? _value.totalIncome
                : totalIncome // ignore: cast_nullable_to_non_nullable
                      as double,
            totalExpenses: null == totalExpenses
                ? _value.totalExpenses
                : totalExpenses // ignore: cast_nullable_to_non_nullable
                      as double,
            netCash: null == netCash
                ? _value.netCash
                : netCash // ignore: cast_nullable_to_non_nullable
                      as double,
            byCategory: null == byCategory
                ? _value.byCategory
                : byCategory // ignore: cast_nullable_to_non_nullable
                      as Map<String, double>,
            year: null == year
                ? _value.year
                : year // ignore: cast_nullable_to_non_nullable
                      as int,
            month: null == month
                ? _value.month
                : month // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MonthlySummaryEntityImplCopyWith<$Res>
    implements $MonthlySummaryEntityCopyWith<$Res> {
  factory _$$MonthlySummaryEntityImplCopyWith(
    _$MonthlySummaryEntityImpl value,
    $Res Function(_$MonthlySummaryEntityImpl) then,
  ) = __$$MonthlySummaryEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double totalIncome,
    double totalExpenses,
    double netCash,
    Map<String, double> byCategory,
    int year,
    int month,
  });
}

/// @nodoc
class __$$MonthlySummaryEntityImplCopyWithImpl<$Res>
    extends _$MonthlySummaryEntityCopyWithImpl<$Res, _$MonthlySummaryEntityImpl>
    implements _$$MonthlySummaryEntityImplCopyWith<$Res> {
  __$$MonthlySummaryEntityImplCopyWithImpl(
    _$MonthlySummaryEntityImpl _value,
    $Res Function(_$MonthlySummaryEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MonthlySummaryEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalIncome = null,
    Object? totalExpenses = null,
    Object? netCash = null,
    Object? byCategory = null,
    Object? year = null,
    Object? month = null,
  }) {
    return _then(
      _$MonthlySummaryEntityImpl(
        totalIncome: null == totalIncome
            ? _value.totalIncome
            : totalIncome // ignore: cast_nullable_to_non_nullable
                  as double,
        totalExpenses: null == totalExpenses
            ? _value.totalExpenses
            : totalExpenses // ignore: cast_nullable_to_non_nullable
                  as double,
        netCash: null == netCash
            ? _value.netCash
            : netCash // ignore: cast_nullable_to_non_nullable
                  as double,
        byCategory: null == byCategory
            ? _value._byCategory
            : byCategory // ignore: cast_nullable_to_non_nullable
                  as Map<String, double>,
        year: null == year
            ? _value.year
            : year // ignore: cast_nullable_to_non_nullable
                  as int,
        month: null == month
            ? _value.month
            : month // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$MonthlySummaryEntityImpl implements _MonthlySummaryEntity {
  const _$MonthlySummaryEntityImpl({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netCash,
    required final Map<String, double> byCategory,
    required this.year,
    required this.month,
  }) : _byCategory = byCategory;

  @override
  final double totalIncome;
  @override
  final double totalExpenses;
  @override
  final double netCash;
  final Map<String, double> _byCategory;
  @override
  Map<String, double> get byCategory {
    if (_byCategory is EqualUnmodifiableMapView) return _byCategory;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_byCategory);
  }

  @override
  final int year;
  @override
  final int month;

  @override
  String toString() {
    return 'MonthlySummaryEntity(totalIncome: $totalIncome, totalExpenses: $totalExpenses, netCash: $netCash, byCategory: $byCategory, year: $year, month: $month)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MonthlySummaryEntityImpl &&
            (identical(other.totalIncome, totalIncome) ||
                other.totalIncome == totalIncome) &&
            (identical(other.totalExpenses, totalExpenses) ||
                other.totalExpenses == totalExpenses) &&
            (identical(other.netCash, netCash) || other.netCash == netCash) &&
            const DeepCollectionEquality().equals(
              other._byCategory,
              _byCategory,
            ) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.month, month) || other.month == month));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    totalIncome,
    totalExpenses,
    netCash,
    const DeepCollectionEquality().hash(_byCategory),
    year,
    month,
  );

  /// Create a copy of MonthlySummaryEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MonthlySummaryEntityImplCopyWith<_$MonthlySummaryEntityImpl>
  get copyWith =>
      __$$MonthlySummaryEntityImplCopyWithImpl<_$MonthlySummaryEntityImpl>(
        this,
        _$identity,
      );
}

abstract class _MonthlySummaryEntity implements MonthlySummaryEntity {
  const factory _MonthlySummaryEntity({
    required final double totalIncome,
    required final double totalExpenses,
    required final double netCash,
    required final Map<String, double> byCategory,
    required final int year,
    required final int month,
  }) = _$MonthlySummaryEntityImpl;

  @override
  double get totalIncome;
  @override
  double get totalExpenses;
  @override
  double get netCash;
  @override
  Map<String, double> get byCategory;
  @override
  int get year;
  @override
  int get month;

  /// Create a copy of MonthlySummaryEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MonthlySummaryEntityImplCopyWith<_$MonthlySummaryEntityImpl>
  get copyWith => throw _privateConstructorUsedError;
}
