// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TransactionDto _$TransactionDtoFromJson(Map<String, dynamic> json) {
  return _TransactionDto.fromJson(json);
}

/// @nodoc
mixin _$TransactionDto {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get source => throw _privateConstructorUsedError;
  String get date => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;

  /// Serializes this TransactionDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TransactionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransactionDtoCopyWith<TransactionDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransactionDtoCopyWith<$Res> {
  factory $TransactionDtoCopyWith(
    TransactionDto value,
    $Res Function(TransactionDto) then,
  ) = _$TransactionDtoCopyWithImpl<$Res, TransactionDto>;
  @useResult
  $Res call({
    String id,
    String userId,
    double amount,
    String category,
    String type,
    String source,
    String date,
    String? note,
  });
}

/// @nodoc
class _$TransactionDtoCopyWithImpl<$Res, $Val extends TransactionDto>
    implements $TransactionDtoCopyWith<$Res> {
  _$TransactionDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TransactionDto
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
                      as String,
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
abstract class _$$TransactionDtoImplCopyWith<$Res>
    implements $TransactionDtoCopyWith<$Res> {
  factory _$$TransactionDtoImplCopyWith(
    _$TransactionDtoImpl value,
    $Res Function(_$TransactionDtoImpl) then,
  ) = __$$TransactionDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    double amount,
    String category,
    String type,
    String source,
    String date,
    String? note,
  });
}

/// @nodoc
class __$$TransactionDtoImplCopyWithImpl<$Res>
    extends _$TransactionDtoCopyWithImpl<$Res, _$TransactionDtoImpl>
    implements _$$TransactionDtoImplCopyWith<$Res> {
  __$$TransactionDtoImplCopyWithImpl(
    _$TransactionDtoImpl _value,
    $Res Function(_$TransactionDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TransactionDto
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
      _$TransactionDtoImpl(
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
                  as String,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TransactionDtoImpl implements _TransactionDto {
  const _$TransactionDtoImpl({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.type,
    required this.source,
    required this.date,
    this.note,
  });

  factory _$TransactionDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$TransactionDtoImplFromJson(json);

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
  final String date;
  @override
  final String? note;

  @override
  String toString() {
    return 'TransactionDto(id: $id, userId: $userId, amount: $amount, category: $category, type: $type, source: $source, date: $date, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransactionDtoImpl &&
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

  @JsonKey(includeFromJson: false, includeToJson: false)
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

  /// Create a copy of TransactionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransactionDtoImplCopyWith<_$TransactionDtoImpl> get copyWith =>
      __$$TransactionDtoImplCopyWithImpl<_$TransactionDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TransactionDtoImplToJson(this);
  }
}

abstract class _TransactionDto implements TransactionDto {
  const factory _TransactionDto({
    required final String id,
    required final String userId,
    required final double amount,
    required final String category,
    required final String type,
    required final String source,
    required final String date,
    final String? note,
  }) = _$TransactionDtoImpl;

  factory _TransactionDto.fromJson(Map<String, dynamic> json) =
      _$TransactionDtoImpl.fromJson;

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
  String get date;
  @override
  String? get note;

  /// Create a copy of TransactionDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransactionDtoImplCopyWith<_$TransactionDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MonthlySummaryDto _$MonthlySummaryDtoFromJson(Map<String, dynamic> json) {
  return _MonthlySummaryDto.fromJson(json);
}

/// @nodoc
mixin _$MonthlySummaryDto {
  double get totalIncome => throw _privateConstructorUsedError;
  double get totalExpenses => throw _privateConstructorUsedError;
  double get netCash => throw _privateConstructorUsedError;
  Map<String, double> get byCategory => throw _privateConstructorUsedError;
  int get year => throw _privateConstructorUsedError;
  int get month => throw _privateConstructorUsedError;

  /// Serializes this MonthlySummaryDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MonthlySummaryDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MonthlySummaryDtoCopyWith<MonthlySummaryDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MonthlySummaryDtoCopyWith<$Res> {
  factory $MonthlySummaryDtoCopyWith(
    MonthlySummaryDto value,
    $Res Function(MonthlySummaryDto) then,
  ) = _$MonthlySummaryDtoCopyWithImpl<$Res, MonthlySummaryDto>;
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
class _$MonthlySummaryDtoCopyWithImpl<$Res, $Val extends MonthlySummaryDto>
    implements $MonthlySummaryDtoCopyWith<$Res> {
  _$MonthlySummaryDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MonthlySummaryDto
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
abstract class _$$MonthlySummaryDtoImplCopyWith<$Res>
    implements $MonthlySummaryDtoCopyWith<$Res> {
  factory _$$MonthlySummaryDtoImplCopyWith(
    _$MonthlySummaryDtoImpl value,
    $Res Function(_$MonthlySummaryDtoImpl) then,
  ) = __$$MonthlySummaryDtoImplCopyWithImpl<$Res>;
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
class __$$MonthlySummaryDtoImplCopyWithImpl<$Res>
    extends _$MonthlySummaryDtoCopyWithImpl<$Res, _$MonthlySummaryDtoImpl>
    implements _$$MonthlySummaryDtoImplCopyWith<$Res> {
  __$$MonthlySummaryDtoImplCopyWithImpl(
    _$MonthlySummaryDtoImpl _value,
    $Res Function(_$MonthlySummaryDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MonthlySummaryDto
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
      _$MonthlySummaryDtoImpl(
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
@JsonSerializable()
class _$MonthlySummaryDtoImpl implements _MonthlySummaryDto {
  const _$MonthlySummaryDtoImpl({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netCash,
    required final Map<String, double> byCategory,
    required this.year,
    required this.month,
  }) : _byCategory = byCategory;

  factory _$MonthlySummaryDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$MonthlySummaryDtoImplFromJson(json);

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
    return 'MonthlySummaryDto(totalIncome: $totalIncome, totalExpenses: $totalExpenses, netCash: $netCash, byCategory: $byCategory, year: $year, month: $month)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MonthlySummaryDtoImpl &&
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

  @JsonKey(includeFromJson: false, includeToJson: false)
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

  /// Create a copy of MonthlySummaryDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MonthlySummaryDtoImplCopyWith<_$MonthlySummaryDtoImpl> get copyWith =>
      __$$MonthlySummaryDtoImplCopyWithImpl<_$MonthlySummaryDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MonthlySummaryDtoImplToJson(this);
  }
}

abstract class _MonthlySummaryDto implements MonthlySummaryDto {
  const factory _MonthlySummaryDto({
    required final double totalIncome,
    required final double totalExpenses,
    required final double netCash,
    required final Map<String, double> byCategory,
    required final int year,
    required final int month,
  }) = _$MonthlySummaryDtoImpl;

  factory _MonthlySummaryDto.fromJson(Map<String, dynamic> json) =
      _$MonthlySummaryDtoImpl.fromJson;

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

  /// Create a copy of MonthlySummaryDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MonthlySummaryDtoImplCopyWith<_$MonthlySummaryDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
