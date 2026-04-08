// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_message_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AiMessageEntity {
  String get id => throw _privateConstructorUsedError;
  AiRole get role => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  String? get mode => throw _privateConstructorUsedError;

  /// Create a copy of AiMessageEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AiMessageEntityCopyWith<AiMessageEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AiMessageEntityCopyWith<$Res> {
  factory $AiMessageEntityCopyWith(
    AiMessageEntity value,
    $Res Function(AiMessageEntity) then,
  ) = _$AiMessageEntityCopyWithImpl<$Res, AiMessageEntity>;
  @useResult
  $Res call({
    String id,
    AiRole role,
    String content,
    DateTime timestamp,
    String? mode,
  });
}

/// @nodoc
class _$AiMessageEntityCopyWithImpl<$Res, $Val extends AiMessageEntity>
    implements $AiMessageEntityCopyWith<$Res> {
  _$AiMessageEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AiMessageEntity
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
                      as AiRole,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
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
abstract class _$$AiMessageEntityImplCopyWith<$Res>
    implements $AiMessageEntityCopyWith<$Res> {
  factory _$$AiMessageEntityImplCopyWith(
    _$AiMessageEntityImpl value,
    $Res Function(_$AiMessageEntityImpl) then,
  ) = __$$AiMessageEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    AiRole role,
    String content,
    DateTime timestamp,
    String? mode,
  });
}

/// @nodoc
class __$$AiMessageEntityImplCopyWithImpl<$Res>
    extends _$AiMessageEntityCopyWithImpl<$Res, _$AiMessageEntityImpl>
    implements _$$AiMessageEntityImplCopyWith<$Res> {
  __$$AiMessageEntityImplCopyWithImpl(
    _$AiMessageEntityImpl _value,
    $Res Function(_$AiMessageEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AiMessageEntity
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
      _$AiMessageEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as AiRole,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        mode: freezed == mode
            ? _value.mode
            : mode // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$AiMessageEntityImpl implements _AiMessageEntity {
  const _$AiMessageEntityImpl({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.mode,
  });

  @override
  final String id;
  @override
  final AiRole role;
  @override
  final String content;
  @override
  final DateTime timestamp;
  @override
  final String? mode;

  @override
  String toString() {
    return 'AiMessageEntity(id: $id, role: $role, content: $content, timestamp: $timestamp, mode: $mode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AiMessageEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.mode, mode) || other.mode == mode));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, role, content, timestamp, mode);

  /// Create a copy of AiMessageEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AiMessageEntityImplCopyWith<_$AiMessageEntityImpl> get copyWith =>
      __$$AiMessageEntityImplCopyWithImpl<_$AiMessageEntityImpl>(
        this,
        _$identity,
      );
}

abstract class _AiMessageEntity implements AiMessageEntity {
  const factory _AiMessageEntity({
    required final String id,
    required final AiRole role,
    required final String content,
    required final DateTime timestamp,
    final String? mode,
  }) = _$AiMessageEntityImpl;

  @override
  String get id;
  @override
  AiRole get role;
  @override
  String get content;
  @override
  DateTime get timestamp;
  @override
  String? get mode;

  /// Create a copy of AiMessageEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AiMessageEntityImplCopyWith<_$AiMessageEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
