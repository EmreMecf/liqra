// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_request_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AiRequestDto _$AiRequestDtoFromJson(Map<String, dynamic> json) {
  return _AiRequestDto.fromJson(json);
}

/// @nodoc
mixin _$AiRequestDto {
  String get message => throw _privateConstructorUsedError;
  String get mode => throw _privateConstructorUsedError;
  AiContextDto get context => throw _privateConstructorUsedError;
  List<Map<String, String>> get history => throw _privateConstructorUsedError;

  /// Serializes this AiRequestDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AiRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AiRequestDtoCopyWith<AiRequestDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AiRequestDtoCopyWith<$Res> {
  factory $AiRequestDtoCopyWith(
    AiRequestDto value,
    $Res Function(AiRequestDto) then,
  ) = _$AiRequestDtoCopyWithImpl<$Res, AiRequestDto>;
  @useResult
  $Res call({
    String message,
    String mode,
    AiContextDto context,
    List<Map<String, String>> history,
  });

  $AiContextDtoCopyWith<$Res> get context;
}

/// @nodoc
class _$AiRequestDtoCopyWithImpl<$Res, $Val extends AiRequestDto>
    implements $AiRequestDtoCopyWith<$Res> {
  _$AiRequestDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AiRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? mode = null,
    Object? context = null,
    Object? history = null,
  }) {
    return _then(
      _value.copyWith(
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            mode: null == mode
                ? _value.mode
                : mode // ignore: cast_nullable_to_non_nullable
                      as String,
            context: null == context
                ? _value.context
                : context // ignore: cast_nullable_to_non_nullable
                      as AiContextDto,
            history: null == history
                ? _value.history
                : history // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, String>>,
          )
          as $Val,
    );
  }

  /// Create a copy of AiRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AiContextDtoCopyWith<$Res> get context {
    return $AiContextDtoCopyWith<$Res>(_value.context, (value) {
      return _then(_value.copyWith(context: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AiRequestDtoImplCopyWith<$Res>
    implements $AiRequestDtoCopyWith<$Res> {
  factory _$$AiRequestDtoImplCopyWith(
    _$AiRequestDtoImpl value,
    $Res Function(_$AiRequestDtoImpl) then,
  ) = __$$AiRequestDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String message,
    String mode,
    AiContextDto context,
    List<Map<String, String>> history,
  });

  @override
  $AiContextDtoCopyWith<$Res> get context;
}

/// @nodoc
class __$$AiRequestDtoImplCopyWithImpl<$Res>
    extends _$AiRequestDtoCopyWithImpl<$Res, _$AiRequestDtoImpl>
    implements _$$AiRequestDtoImplCopyWith<$Res> {
  __$$AiRequestDtoImplCopyWithImpl(
    _$AiRequestDtoImpl _value,
    $Res Function(_$AiRequestDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AiRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? mode = null,
    Object? context = null,
    Object? history = null,
  }) {
    return _then(
      _$AiRequestDtoImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        mode: null == mode
            ? _value.mode
            : mode // ignore: cast_nullable_to_non_nullable
                  as String,
        context: null == context
            ? _value.context
            : context // ignore: cast_nullable_to_non_nullable
                  as AiContextDto,
        history: null == history
            ? _value._history
            : history // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, String>>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AiRequestDtoImpl implements _AiRequestDto {
  const _$AiRequestDtoImpl({
    required this.message,
    required this.mode,
    required this.context,
    final List<Map<String, String>> history = const [],
  }) : _history = history;

  factory _$AiRequestDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$AiRequestDtoImplFromJson(json);

  @override
  final String message;
  @override
  final String mode;
  @override
  final AiContextDto context;
  final List<Map<String, String>> _history;
  @override
  @JsonKey()
  List<Map<String, String>> get history {
    if (_history is EqualUnmodifiableListView) return _history;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_history);
  }

  @override
  String toString() {
    return 'AiRequestDto(message: $message, mode: $mode, context: $context, history: $history)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AiRequestDtoImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.context, context) || other.context == context) &&
            const DeepCollectionEquality().equals(other._history, _history));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    message,
    mode,
    context,
    const DeepCollectionEquality().hash(_history),
  );

  /// Create a copy of AiRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AiRequestDtoImplCopyWith<_$AiRequestDtoImpl> get copyWith =>
      __$$AiRequestDtoImplCopyWithImpl<_$AiRequestDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AiRequestDtoImplToJson(this);
  }
}

abstract class _AiRequestDto implements AiRequestDto {
  const factory _AiRequestDto({
    required final String message,
    required final String mode,
    required final AiContextDto context,
    final List<Map<String, String>> history,
  }) = _$AiRequestDtoImpl;

  factory _AiRequestDto.fromJson(Map<String, dynamic> json) =
      _$AiRequestDtoImpl.fromJson;

  @override
  String get message;
  @override
  String get mode;
  @override
  AiContextDto get context;
  @override
  List<Map<String, String>> get history;

  /// Create a copy of AiRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AiRequestDtoImplCopyWith<_$AiRequestDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AiContextDto _$AiContextDtoFromJson(Map<String, dynamic> json) {
  return _AiContextDto.fromJson(json);
}

/// @nodoc
mixin _$AiContextDto {
  String get riskProfile => throw _privateConstructorUsedError;
  double get monthlyIncome => throw _privateConstructorUsedError;
  double get monthlyExpenses => throw _privateConstructorUsedError;
  double get netCash => throw _privateConstructorUsedError;
  String get portfolioSummary => throw _privateConstructorUsedError;
  String get transactionsSummary => throw _privateConstructorUsedError;
  String? get goalTitle => throw _privateConstructorUsedError;
  double? get goalProgress => throw _privateConstructorUsedError;
  String? get goalDeadline => throw _privateConstructorUsedError;

  /// Serializes this AiContextDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AiContextDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AiContextDtoCopyWith<AiContextDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AiContextDtoCopyWith<$Res> {
  factory $AiContextDtoCopyWith(
    AiContextDto value,
    $Res Function(AiContextDto) then,
  ) = _$AiContextDtoCopyWithImpl<$Res, AiContextDto>;
  @useResult
  $Res call({
    String riskProfile,
    double monthlyIncome,
    double monthlyExpenses,
    double netCash,
    String portfolioSummary,
    String transactionsSummary,
    String? goalTitle,
    double? goalProgress,
    String? goalDeadline,
  });
}

/// @nodoc
class _$AiContextDtoCopyWithImpl<$Res, $Val extends AiContextDto>
    implements $AiContextDtoCopyWith<$Res> {
  _$AiContextDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AiContextDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? riskProfile = null,
    Object? monthlyIncome = null,
    Object? monthlyExpenses = null,
    Object? netCash = null,
    Object? portfolioSummary = null,
    Object? transactionsSummary = null,
    Object? goalTitle = freezed,
    Object? goalProgress = freezed,
    Object? goalDeadline = freezed,
  }) {
    return _then(
      _value.copyWith(
            riskProfile: null == riskProfile
                ? _value.riskProfile
                : riskProfile // ignore: cast_nullable_to_non_nullable
                      as String,
            monthlyIncome: null == monthlyIncome
                ? _value.monthlyIncome
                : monthlyIncome // ignore: cast_nullable_to_non_nullable
                      as double,
            monthlyExpenses: null == monthlyExpenses
                ? _value.monthlyExpenses
                : monthlyExpenses // ignore: cast_nullable_to_non_nullable
                      as double,
            netCash: null == netCash
                ? _value.netCash
                : netCash // ignore: cast_nullable_to_non_nullable
                      as double,
            portfolioSummary: null == portfolioSummary
                ? _value.portfolioSummary
                : portfolioSummary // ignore: cast_nullable_to_non_nullable
                      as String,
            transactionsSummary: null == transactionsSummary
                ? _value.transactionsSummary
                : transactionsSummary // ignore: cast_nullable_to_non_nullable
                      as String,
            goalTitle: freezed == goalTitle
                ? _value.goalTitle
                : goalTitle // ignore: cast_nullable_to_non_nullable
                      as String?,
            goalProgress: freezed == goalProgress
                ? _value.goalProgress
                : goalProgress // ignore: cast_nullable_to_non_nullable
                      as double?,
            goalDeadline: freezed == goalDeadline
                ? _value.goalDeadline
                : goalDeadline // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AiContextDtoImplCopyWith<$Res>
    implements $AiContextDtoCopyWith<$Res> {
  factory _$$AiContextDtoImplCopyWith(
    _$AiContextDtoImpl value,
    $Res Function(_$AiContextDtoImpl) then,
  ) = __$$AiContextDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String riskProfile,
    double monthlyIncome,
    double monthlyExpenses,
    double netCash,
    String portfolioSummary,
    String transactionsSummary,
    String? goalTitle,
    double? goalProgress,
    String? goalDeadline,
  });
}

/// @nodoc
class __$$AiContextDtoImplCopyWithImpl<$Res>
    extends _$AiContextDtoCopyWithImpl<$Res, _$AiContextDtoImpl>
    implements _$$AiContextDtoImplCopyWith<$Res> {
  __$$AiContextDtoImplCopyWithImpl(
    _$AiContextDtoImpl _value,
    $Res Function(_$AiContextDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AiContextDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? riskProfile = null,
    Object? monthlyIncome = null,
    Object? monthlyExpenses = null,
    Object? netCash = null,
    Object? portfolioSummary = null,
    Object? transactionsSummary = null,
    Object? goalTitle = freezed,
    Object? goalProgress = freezed,
    Object? goalDeadline = freezed,
  }) {
    return _then(
      _$AiContextDtoImpl(
        riskProfile: null == riskProfile
            ? _value.riskProfile
            : riskProfile // ignore: cast_nullable_to_non_nullable
                  as String,
        monthlyIncome: null == monthlyIncome
            ? _value.monthlyIncome
            : monthlyIncome // ignore: cast_nullable_to_non_nullable
                  as double,
        monthlyExpenses: null == monthlyExpenses
            ? _value.monthlyExpenses
            : monthlyExpenses // ignore: cast_nullable_to_non_nullable
                  as double,
        netCash: null == netCash
            ? _value.netCash
            : netCash // ignore: cast_nullable_to_non_nullable
                  as double,
        portfolioSummary: null == portfolioSummary
            ? _value.portfolioSummary
            : portfolioSummary // ignore: cast_nullable_to_non_nullable
                  as String,
        transactionsSummary: null == transactionsSummary
            ? _value.transactionsSummary
            : transactionsSummary // ignore: cast_nullable_to_non_nullable
                  as String,
        goalTitle: freezed == goalTitle
            ? _value.goalTitle
            : goalTitle // ignore: cast_nullable_to_non_nullable
                  as String?,
        goalProgress: freezed == goalProgress
            ? _value.goalProgress
            : goalProgress // ignore: cast_nullable_to_non_nullable
                  as double?,
        goalDeadline: freezed == goalDeadline
            ? _value.goalDeadline
            : goalDeadline // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AiContextDtoImpl implements _AiContextDto {
  const _$AiContextDtoImpl({
    required this.riskProfile,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.netCash,
    required this.portfolioSummary,
    required this.transactionsSummary,
    this.goalTitle,
    this.goalProgress,
    this.goalDeadline,
  });

  factory _$AiContextDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$AiContextDtoImplFromJson(json);

  @override
  final String riskProfile;
  @override
  final double monthlyIncome;
  @override
  final double monthlyExpenses;
  @override
  final double netCash;
  @override
  final String portfolioSummary;
  @override
  final String transactionsSummary;
  @override
  final String? goalTitle;
  @override
  final double? goalProgress;
  @override
  final String? goalDeadline;

  @override
  String toString() {
    return 'AiContextDto(riskProfile: $riskProfile, monthlyIncome: $monthlyIncome, monthlyExpenses: $monthlyExpenses, netCash: $netCash, portfolioSummary: $portfolioSummary, transactionsSummary: $transactionsSummary, goalTitle: $goalTitle, goalProgress: $goalProgress, goalDeadline: $goalDeadline)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AiContextDtoImpl &&
            (identical(other.riskProfile, riskProfile) ||
                other.riskProfile == riskProfile) &&
            (identical(other.monthlyIncome, monthlyIncome) ||
                other.monthlyIncome == monthlyIncome) &&
            (identical(other.monthlyExpenses, monthlyExpenses) ||
                other.monthlyExpenses == monthlyExpenses) &&
            (identical(other.netCash, netCash) || other.netCash == netCash) &&
            (identical(other.portfolioSummary, portfolioSummary) ||
                other.portfolioSummary == portfolioSummary) &&
            (identical(other.transactionsSummary, transactionsSummary) ||
                other.transactionsSummary == transactionsSummary) &&
            (identical(other.goalTitle, goalTitle) ||
                other.goalTitle == goalTitle) &&
            (identical(other.goalProgress, goalProgress) ||
                other.goalProgress == goalProgress) &&
            (identical(other.goalDeadline, goalDeadline) ||
                other.goalDeadline == goalDeadline));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    riskProfile,
    monthlyIncome,
    monthlyExpenses,
    netCash,
    portfolioSummary,
    transactionsSummary,
    goalTitle,
    goalProgress,
    goalDeadline,
  );

  /// Create a copy of AiContextDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AiContextDtoImplCopyWith<_$AiContextDtoImpl> get copyWith =>
      __$$AiContextDtoImplCopyWithImpl<_$AiContextDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AiContextDtoImplToJson(this);
  }
}

abstract class _AiContextDto implements AiContextDto {
  const factory _AiContextDto({
    required final String riskProfile,
    required final double monthlyIncome,
    required final double monthlyExpenses,
    required final double netCash,
    required final String portfolioSummary,
    required final String transactionsSummary,
    final String? goalTitle,
    final double? goalProgress,
    final String? goalDeadline,
  }) = _$AiContextDtoImpl;

  factory _AiContextDto.fromJson(Map<String, dynamic> json) =
      _$AiContextDtoImpl.fromJson;

  @override
  String get riskProfile;
  @override
  double get monthlyIncome;
  @override
  double get monthlyExpenses;
  @override
  double get netCash;
  @override
  String get portfolioSummary;
  @override
  String get transactionsSummary;
  @override
  String? get goalTitle;
  @override
  double? get goalProgress;
  @override
  String? get goalDeadline;

  /// Create a copy of AiContextDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AiContextDtoImplCopyWith<_$AiContextDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AiResponseDto _$AiResponseDtoFromJson(Map<String, dynamic> json) {
  return _AiResponseDto.fromJson(json);
}

/// @nodoc
mixin _$AiResponseDto {
  String get id => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  String get timestamp => throw _privateConstructorUsedError;
  int? get inputTokens => throw _privateConstructorUsedError;
  int? get outputTokens => throw _privateConstructorUsedError;

  /// Serializes this AiResponseDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AiResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AiResponseDtoCopyWith<AiResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AiResponseDtoCopyWith<$Res> {
  factory $AiResponseDtoCopyWith(
    AiResponseDto value,
    $Res Function(AiResponseDto) then,
  ) = _$AiResponseDtoCopyWithImpl<$Res, AiResponseDto>;
  @useResult
  $Res call({
    String id,
    String content,
    String timestamp,
    int? inputTokens,
    int? outputTokens,
  });
}

/// @nodoc
class _$AiResponseDtoCopyWithImpl<$Res, $Val extends AiResponseDto>
    implements $AiResponseDtoCopyWith<$Res> {
  _$AiResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AiResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? timestamp = null,
    Object? inputTokens = freezed,
    Object? outputTokens = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as String,
            inputTokens: freezed == inputTokens
                ? _value.inputTokens
                : inputTokens // ignore: cast_nullable_to_non_nullable
                      as int?,
            outputTokens: freezed == outputTokens
                ? _value.outputTokens
                : outputTokens // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AiResponseDtoImplCopyWith<$Res>
    implements $AiResponseDtoCopyWith<$Res> {
  factory _$$AiResponseDtoImplCopyWith(
    _$AiResponseDtoImpl value,
    $Res Function(_$AiResponseDtoImpl) then,
  ) = __$$AiResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String content,
    String timestamp,
    int? inputTokens,
    int? outputTokens,
  });
}

/// @nodoc
class __$$AiResponseDtoImplCopyWithImpl<$Res>
    extends _$AiResponseDtoCopyWithImpl<$Res, _$AiResponseDtoImpl>
    implements _$$AiResponseDtoImplCopyWith<$Res> {
  __$$AiResponseDtoImplCopyWithImpl(
    _$AiResponseDtoImpl _value,
    $Res Function(_$AiResponseDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AiResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? timestamp = null,
    Object? inputTokens = freezed,
    Object? outputTokens = freezed,
  }) {
    return _then(
      _$AiResponseDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as String,
        inputTokens: freezed == inputTokens
            ? _value.inputTokens
            : inputTokens // ignore: cast_nullable_to_non_nullable
                  as int?,
        outputTokens: freezed == outputTokens
            ? _value.outputTokens
            : outputTokens // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AiResponseDtoImpl implements _AiResponseDto {
  const _$AiResponseDtoImpl({
    required this.id,
    required this.content,
    required this.timestamp,
    this.inputTokens,
    this.outputTokens,
  });

  factory _$AiResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$AiResponseDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String content;
  @override
  final String timestamp;
  @override
  final int? inputTokens;
  @override
  final int? outputTokens;

  @override
  String toString() {
    return 'AiResponseDto(id: $id, content: $content, timestamp: $timestamp, inputTokens: $inputTokens, outputTokens: $outputTokens)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AiResponseDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.inputTokens, inputTokens) ||
                other.inputTokens == inputTokens) &&
            (identical(other.outputTokens, outputTokens) ||
                other.outputTokens == outputTokens));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    content,
    timestamp,
    inputTokens,
    outputTokens,
  );

  /// Create a copy of AiResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AiResponseDtoImplCopyWith<_$AiResponseDtoImpl> get copyWith =>
      __$$AiResponseDtoImplCopyWithImpl<_$AiResponseDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AiResponseDtoImplToJson(this);
  }
}

abstract class _AiResponseDto implements AiResponseDto {
  const factory _AiResponseDto({
    required final String id,
    required final String content,
    required final String timestamp,
    final int? inputTokens,
    final int? outputTokens,
  }) = _$AiResponseDtoImpl;

  factory _AiResponseDto.fromJson(Map<String, dynamic> json) =
      _$AiResponseDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get content;
  @override
  String get timestamp;
  @override
  int? get inputTokens;
  @override
  int? get outputTokens;

  /// Create a copy of AiResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AiResponseDtoImplCopyWith<_$AiResponseDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
