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
  String get systemPrompt => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  List<Map<String, String>> get history => throw _privateConstructorUsedError;

  /// Uzun analiz görevleri daha yüksek limit ister.
  int get maxTokens => throw _privateConstructorUsedError;

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
    String systemPrompt,
    String message,
    List<Map<String, String>> history,
    int maxTokens,
  });
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
    Object? systemPrompt = null,
    Object? message = null,
    Object? history = null,
    Object? maxTokens = null,
  }) {
    return _then(
      _value.copyWith(
            systemPrompt: null == systemPrompt
                ? _value.systemPrompt
                : systemPrompt // ignore: cast_nullable_to_non_nullable
                      as String,
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            history: null == history
                ? _value.history
                : history // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, String>>,
            maxTokens: null == maxTokens
                ? _value.maxTokens
                : maxTokens // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
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
    String systemPrompt,
    String message,
    List<Map<String, String>> history,
    int maxTokens,
  });
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
    Object? systemPrompt = null,
    Object? message = null,
    Object? history = null,
    Object? maxTokens = null,
  }) {
    return _then(
      _$AiRequestDtoImpl(
        systemPrompt: null == systemPrompt
            ? _value.systemPrompt
            : systemPrompt // ignore: cast_nullable_to_non_nullable
                  as String,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        history: null == history
            ? _value._history
            : history // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, String>>,
        maxTokens: null == maxTokens
            ? _value.maxTokens
            : maxTokens // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AiRequestDtoImpl implements _AiRequestDto {
  const _$AiRequestDtoImpl({
    required this.systemPrompt,
    required this.message,
    final List<Map<String, String>> history = const [],
    this.maxTokens = 2048,
  }) : _history = history;

  factory _$AiRequestDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$AiRequestDtoImplFromJson(json);

  @override
  final String systemPrompt;
  @override
  final String message;
  final List<Map<String, String>> _history;
  @override
  @JsonKey()
  List<Map<String, String>> get history {
    if (_history is EqualUnmodifiableListView) return _history;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_history);
  }

  /// Uzun analiz görevleri daha yüksek limit ister.
  @override
  @JsonKey()
  final int maxTokens;

  @override
  String toString() {
    return 'AiRequestDto(systemPrompt: $systemPrompt, message: $message, history: $history, maxTokens: $maxTokens)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AiRequestDtoImpl &&
            (identical(other.systemPrompt, systemPrompt) ||
                other.systemPrompt == systemPrompt) &&
            (identical(other.message, message) || other.message == message) &&
            const DeepCollectionEquality().equals(other._history, _history) &&
            (identical(other.maxTokens, maxTokens) ||
                other.maxTokens == maxTokens));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    systemPrompt,
    message,
    const DeepCollectionEquality().hash(_history),
    maxTokens,
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
    required final String systemPrompt,
    required final String message,
    final List<Map<String, String>> history,
    final int maxTokens,
  }) = _$AiRequestDtoImpl;

  factory _AiRequestDto.fromJson(Map<String, dynamic> json) =
      _$AiRequestDtoImpl.fromJson;

  @override
  String get systemPrompt;
  @override
  String get message;
  @override
  List<Map<String, String>> get history;

  /// Uzun analiz görevleri daha yüksek limit ister.
  @override
  int get maxTokens;

  /// Create a copy of AiRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AiRequestDtoImplCopyWith<_$AiRequestDtoImpl> get copyWith =>
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
