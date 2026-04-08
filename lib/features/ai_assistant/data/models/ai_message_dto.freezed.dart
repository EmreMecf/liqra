// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_message_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AiMessageDto _$AiMessageDtoFromJson(Map<String, dynamic> json) {
  return _AiMessageDto.fromJson(json);
}

/// @nodoc
mixin _$AiMessageDto {
  String get id => throw _privateConstructorUsedError;

  /// 'user' | 'assistant'
  String get role => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  String get timestamp => throw _privateConstructorUsedError;
  String? get mode => throw _privateConstructorUsedError;

  /// Serializes this AiMessageDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AiMessageDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AiMessageDtoCopyWith<AiMessageDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AiMessageDtoCopyWith<$Res> {
  factory $AiMessageDtoCopyWith(
    AiMessageDto value,
    $Res Function(AiMessageDto) then,
  ) = _$AiMessageDtoCopyWithImpl<$Res, AiMessageDto>;
  @useResult
  $Res call({
    String id,
    String role,
    String content,
    String timestamp,
    String? mode,
  });
}

/// @nodoc
class _$AiMessageDtoCopyWithImpl<$Res, $Val extends AiMessageDto>
    implements $AiMessageDtoCopyWith<$Res> {
  _$AiMessageDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AiMessageDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? role = null,
    Object? content = null,
    Object? timestamp = null,
    Object? mode = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as String,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as String,
            mode: freezed == mode
                ? _value.mode
                : mode // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AiMessageDtoImplCopyWith<$Res>
    implements $AiMessageDtoCopyWith<$Res> {
  factory _$$AiMessageDtoImplCopyWith(
    _$AiMessageDtoImpl value,
    $Res Function(_$AiMessageDtoImpl) then,
  ) = __$$AiMessageDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String role,
    String content,
    String timestamp,
    String? mode,
  });
}

/// @nodoc
class __$$AiMessageDtoImplCopyWithImpl<$Res>
    extends _$AiMessageDtoCopyWithImpl<$Res, _$AiMessageDtoImpl>
    implements _$$AiMessageDtoImplCopyWith<$Res> {
  __$$AiMessageDtoImplCopyWithImpl(
    _$AiMessageDtoImpl _value,
    $Res Function(_$AiMessageDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AiMessageDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? role = null,
    Object? content = null,
    Object? timestamp = null,
    Object? mode = freezed,
  }) {
    return _then(
      _$AiMessageDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as String,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as String,
        mode: freezed == mode
            ? _value.mode
            : mode // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AiMessageDtoImpl implements _AiMessageDto {
  const _$AiMessageDtoImpl({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.mode,
  });

  factory _$AiMessageDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$AiMessageDtoImplFromJson(json);

  @override
  final String id;

  /// 'user' | 'assistant'
  @override
  final String role;
  @override
  final String content;
  @override
  final String timestamp;
  @override
  final String? mode;

  @override
  String toString() {
    return 'AiMessageDto(id: $id, role: $role, content: $content, timestamp: $timestamp, mode: $mode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AiMessageDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.mode, mode) || other.mode == mode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, role, content, timestamp, mode);

  /// Create a copy of AiMessageDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AiMessageDtoImplCopyWith<_$AiMessageDtoImpl> get copyWith =>
      __$$AiMessageDtoImplCopyWithImpl<_$AiMessageDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AiMessageDtoImplToJson(this);
  }
}

abstract class _AiMessageDto implements AiMessageDto {
  const factory _AiMessageDto({
    required final String id,
    required final String role,
    required final String content,
    required final String timestamp,
    final String? mode,
  }) = _$AiMessageDtoImpl;

  factory _AiMessageDto.fromJson(Map<String, dynamic> json) =
      _$AiMessageDtoImpl.fromJson;

  @override
  String get id;

  /// 'user' | 'assistant'
  @override
  String get role;
  @override
  String get content;
  @override
  String get timestamp;
  @override
  String? get mode;

  /// Create a copy of AiMessageDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AiMessageDtoImplCopyWith<_$AiMessageDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
