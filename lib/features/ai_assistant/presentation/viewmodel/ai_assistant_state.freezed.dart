// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_assistant_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AiAssistantState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<AiMessageEntity> messages) loading,
    required TResult Function(List<AiMessageEntity> messages) loaded,
    required TResult Function(
      String message,
      List<AiMessageEntity> previousMessages,
    )
    error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(List<AiMessageEntity> messages)? loading,
    TResult? Function(List<AiMessageEntity> messages)? loaded,
    TResult? Function(String message, List<AiMessageEntity> previousMessages)?
    error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<AiMessageEntity> messages)? loading,
    TResult Function(List<AiMessageEntity> messages)? loaded,
    TResult Function(String message, List<AiMessageEntity> previousMessages)?
    error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AiInitial value) initial,
    required TResult Function(AiLoading value) loading,
    required TResult Function(AiLoaded value) loaded,
    required TResult Function(AiError value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AiInitial value)? initial,
    TResult? Function(AiLoading value)? loading,
    TResult? Function(AiLoaded value)? loaded,
    TResult? Function(AiError value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AiInitial value)? initial,
    TResult Function(AiLoading value)? loading,
    TResult Function(AiLoaded value)? loaded,
    TResult Function(AiError value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AiAssistantStateCopyWith<$Res> {
  factory $AiAssistantStateCopyWith(
    AiAssistantState value,
    $Res Function(AiAssistantState) then,
  ) = _$AiAssistantStateCopyWithImpl<$Res, AiAssistantState>;
}

/// @nodoc
class _$AiAssistantStateCopyWithImpl<$Res, $Val extends AiAssistantState>
    implements $AiAssistantStateCopyWith<$Res> {
  _$AiAssistantStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AiAssistantState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$AiInitialImplCopyWith<$Res> {
  factory _$$AiInitialImplCopyWith(
    _$AiInitialImpl value,
    $Res Function(_$AiInitialImpl) then,
  ) = __$$AiInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$AiInitialImplCopyWithImpl<$Res>
    extends _$AiAssistantStateCopyWithImpl<$Res, _$AiInitialImpl>
    implements _$$AiInitialImplCopyWith<$Res> {
  __$$AiInitialImplCopyWithImpl(
    _$AiInitialImpl _value,
    $Res Function(_$AiInitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AiAssistantState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$AiInitialImpl implements AiInitial {
  const _$AiInitialImpl();

  @override
  String toString() {
    return 'AiAssistantState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$AiInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<AiMessageEntity> messages) loading,
    required TResult Function(List<AiMessageEntity> messages) loaded,
    required TResult Function(
      String message,
      List<AiMessageEntity> previousMessages,
    )
    error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(List<AiMessageEntity> messages)? loading,
    TResult? Function(List<AiMessageEntity> messages)? loaded,
    TResult? Function(String message, List<AiMessageEntity> previousMessages)?
    error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<AiMessageEntity> messages)? loading,
    TResult Function(List<AiMessageEntity> messages)? loaded,
    TResult Function(String message, List<AiMessageEntity> previousMessages)?
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
    required TResult Function(AiInitial value) initial,
    required TResult Function(AiLoading value) loading,
    required TResult Function(AiLoaded value) loaded,
    required TResult Function(AiError value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AiInitial value)? initial,
    TResult? Function(AiLoading value)? loading,
    TResult? Function(AiLoaded value)? loaded,
    TResult? Function(AiError value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AiInitial value)? initial,
    TResult Function(AiLoading value)? loading,
    TResult Function(AiLoaded value)? loaded,
    TResult Function(AiError value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class AiInitial implements AiAssistantState {
  const factory AiInitial() = _$AiInitialImpl;
}

/// @nodoc
abstract class _$$AiLoadingImplCopyWith<$Res> {
  factory _$$AiLoadingImplCopyWith(
    _$AiLoadingImpl value,
    $Res Function(_$AiLoadingImpl) then,
  ) = __$$AiLoadingImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<AiMessageEntity> messages});
}

/// @nodoc
class __$$AiLoadingImplCopyWithImpl<$Res>
    extends _$AiAssistantStateCopyWithImpl<$Res, _$AiLoadingImpl>
    implements _$$AiLoadingImplCopyWith<$Res> {
  __$$AiLoadingImplCopyWithImpl(
    _$AiLoadingImpl _value,
    $Res Function(_$AiLoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AiAssistantState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? messages = null}) {
    return _then(
      _$AiLoadingImpl(
        messages: null == messages
            ? _value._messages
            : messages // ignore: cast_nullable_to_non_nullable
                  as List<AiMessageEntity>,
      ),
    );
  }
}

/// @nodoc

class _$AiLoadingImpl implements AiLoading {
  const _$AiLoadingImpl({required final List<AiMessageEntity> messages})
    : _messages = messages;

  final List<AiMessageEntity> _messages;
  @override
  List<AiMessageEntity> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  @override
  String toString() {
    return 'AiAssistantState.loading(messages: $messages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AiLoadingImpl &&
            const DeepCollectionEquality().equals(other._messages, _messages));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_messages));

  /// Create a copy of AiAssistantState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AiLoadingImplCopyWith<_$AiLoadingImpl> get copyWith =>
      __$$AiLoadingImplCopyWithImpl<_$AiLoadingImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<AiMessageEntity> messages) loading,
    required TResult Function(List<AiMessageEntity> messages) loaded,
    required TResult Function(
      String message,
      List<AiMessageEntity> previousMessages,
    )
    error,
  }) {
    return loading(messages);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(List<AiMessageEntity> messages)? loading,
    TResult? Function(List<AiMessageEntity> messages)? loaded,
    TResult? Function(String message, List<AiMessageEntity> previousMessages)?
    error,
  }) {
    return loading?.call(messages);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<AiMessageEntity> messages)? loading,
    TResult Function(List<AiMessageEntity> messages)? loaded,
    TResult Function(String message, List<AiMessageEntity> previousMessages)?
    error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(messages);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AiInitial value) initial,
    required TResult Function(AiLoading value) loading,
    required TResult Function(AiLoaded value) loaded,
    required TResult Function(AiError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AiInitial value)? initial,
    TResult? Function(AiLoading value)? loading,
    TResult? Function(AiLoaded value)? loaded,
    TResult? Function(AiError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AiInitial value)? initial,
    TResult Function(AiLoading value)? loading,
    TResult Function(AiLoaded value)? loaded,
    TResult Function(AiError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class AiLoading implements AiAssistantState {
  const factory AiLoading({required final List<AiMessageEntity> messages}) =
      _$AiLoadingImpl;

  List<AiMessageEntity> get messages;

  /// Create a copy of AiAssistantState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AiLoadingImplCopyWith<_$AiLoadingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AiLoadedImplCopyWith<$Res> {
  factory _$$AiLoadedImplCopyWith(
    _$AiLoadedImpl value,
    $Res Function(_$AiLoadedImpl) then,
  ) = __$$AiLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<AiMessageEntity> messages});
}

/// @nodoc
class __$$AiLoadedImplCopyWithImpl<$Res>
    extends _$AiAssistantStateCopyWithImpl<$Res, _$AiLoadedImpl>
    implements _$$AiLoadedImplCopyWith<$Res> {
  __$$AiLoadedImplCopyWithImpl(
    _$AiLoadedImpl _value,
    $Res Function(_$AiLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AiAssistantState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? messages = null}) {
    return _then(
      _$AiLoadedImpl(
        messages: null == messages
            ? _value._messages
            : messages // ignore: cast_nullable_to_non_nullable
                  as List<AiMessageEntity>,
      ),
    );
  }
}

/// @nodoc

class _$AiLoadedImpl implements AiLoaded {
  const _$AiLoadedImpl({required final List<AiMessageEntity> messages})
    : _messages = messages;

  final List<AiMessageEntity> _messages;
  @override
  List<AiMessageEntity> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  @override
  String toString() {
    return 'AiAssistantState.loaded(messages: $messages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AiLoadedImpl &&
            const DeepCollectionEquality().equals(other._messages, _messages));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_messages));

  /// Create a copy of AiAssistantState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AiLoadedImplCopyWith<_$AiLoadedImpl> get copyWith =>
      __$$AiLoadedImplCopyWithImpl<_$AiLoadedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<AiMessageEntity> messages) loading,
    required TResult Function(List<AiMessageEntity> messages) loaded,
    required TResult Function(
      String message,
      List<AiMessageEntity> previousMessages,
    )
    error,
  }) {
    return loaded(messages);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(List<AiMessageEntity> messages)? loading,
    TResult? Function(List<AiMessageEntity> messages)? loaded,
    TResult? Function(String message, List<AiMessageEntity> previousMessages)?
    error,
  }) {
    return loaded?.call(messages);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<AiMessageEntity> messages)? loading,
    TResult Function(List<AiMessageEntity> messages)? loaded,
    TResult Function(String message, List<AiMessageEntity> previousMessages)?
    error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(messages);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AiInitial value) initial,
    required TResult Function(AiLoading value) loading,
    required TResult Function(AiLoaded value) loaded,
    required TResult Function(AiError value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AiInitial value)? initial,
    TResult? Function(AiLoading value)? loading,
    TResult? Function(AiLoaded value)? loaded,
    TResult? Function(AiError value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AiInitial value)? initial,
    TResult Function(AiLoading value)? loading,
    TResult Function(AiLoaded value)? loaded,
    TResult Function(AiError value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class AiLoaded implements AiAssistantState {
  const factory AiLoaded({required final List<AiMessageEntity> messages}) =
      _$AiLoadedImpl;

  List<AiMessageEntity> get messages;

  /// Create a copy of AiAssistantState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AiLoadedImplCopyWith<_$AiLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AiErrorImplCopyWith<$Res> {
  factory _$$AiErrorImplCopyWith(
    _$AiErrorImpl value,
    $Res Function(_$AiErrorImpl) then,
  ) = __$$AiErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message, List<AiMessageEntity> previousMessages});
}

/// @nodoc
class __$$AiErrorImplCopyWithImpl<$Res>
    extends _$AiAssistantStateCopyWithImpl<$Res, _$AiErrorImpl>
    implements _$$AiErrorImplCopyWith<$Res> {
  __$$AiErrorImplCopyWithImpl(
    _$AiErrorImpl _value,
    $Res Function(_$AiErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AiAssistantState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null, Object? previousMessages = null}) {
    return _then(
      _$AiErrorImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        previousMessages: null == previousMessages
            ? _value._previousMessages
            : previousMessages // ignore: cast_nullable_to_non_nullable
                  as List<AiMessageEntity>,
      ),
    );
  }
}

/// @nodoc

class _$AiErrorImpl implements AiError {
  const _$AiErrorImpl({
    required this.message,
    required final List<AiMessageEntity> previousMessages,
  }) : _previousMessages = previousMessages;

  @override
  final String message;
  final List<AiMessageEntity> _previousMessages;
  @override
  List<AiMessageEntity> get previousMessages {
    if (_previousMessages is EqualUnmodifiableListView)
      return _previousMessages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_previousMessages);
  }

  @override
  String toString() {
    return 'AiAssistantState.error(message: $message, previousMessages: $previousMessages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AiErrorImpl &&
            (identical(other.message, message) || other.message == message) &&
            const DeepCollectionEquality().equals(
              other._previousMessages,
              _previousMessages,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    message,
    const DeepCollectionEquality().hash(_previousMessages),
  );

  /// Create a copy of AiAssistantState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AiErrorImplCopyWith<_$AiErrorImpl> get copyWith =>
      __$$AiErrorImplCopyWithImpl<_$AiErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<AiMessageEntity> messages) loading,
    required TResult Function(List<AiMessageEntity> messages) loaded,
    required TResult Function(
      String message,
      List<AiMessageEntity> previousMessages,
    )
    error,
  }) {
    return error(message, previousMessages);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(List<AiMessageEntity> messages)? loading,
    TResult? Function(List<AiMessageEntity> messages)? loaded,
    TResult? Function(String message, List<AiMessageEntity> previousMessages)?
    error,
  }) {
    return error?.call(message, previousMessages);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<AiMessageEntity> messages)? loading,
    TResult Function(List<AiMessageEntity> messages)? loaded,
    TResult Function(String message, List<AiMessageEntity> previousMessages)?
    error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message, previousMessages);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AiInitial value) initial,
    required TResult Function(AiLoading value) loading,
    required TResult Function(AiLoaded value) loaded,
    required TResult Function(AiError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AiInitial value)? initial,
    TResult? Function(AiLoading value)? loading,
    TResult? Function(AiLoaded value)? loaded,
    TResult? Function(AiError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AiInitial value)? initial,
    TResult Function(AiLoading value)? loading,
    TResult Function(AiLoaded value)? loaded,
    TResult Function(AiError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class AiError implements AiAssistantState {
  const factory AiError({
    required final String message,
    required final List<AiMessageEntity> previousMessages,
  }) = _$AiErrorImpl;

  String get message;
  List<AiMessageEntity> get previousMessages;

  /// Create a copy of AiAssistantState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AiErrorImplCopyWith<_$AiErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
