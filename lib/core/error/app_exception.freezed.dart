// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_exception.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AppException {
  String get message => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message, int? statusCode) server,
    required TResult Function(String message) network,
    required TResult Function(String message) cache,
    required TResult Function(String message, String? errorType) claude,
    required TResult Function(String message, int? retryAfterSeconds) rateLimit,
    required TResult Function(String message) unknown,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message, int? statusCode)? server,
    TResult? Function(String message)? network,
    TResult? Function(String message)? cache,
    TResult? Function(String message, String? errorType)? claude,
    TResult? Function(String message, int? retryAfterSeconds)? rateLimit,
    TResult? Function(String message)? unknown,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message, int? statusCode)? server,
    TResult Function(String message)? network,
    TResult Function(String message)? cache,
    TResult Function(String message, String? errorType)? claude,
    TResult Function(String message, int? retryAfterSeconds)? rateLimit,
    TResult Function(String message)? unknown,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ServerException value) server,
    required TResult Function(NetworkException value) network,
    required TResult Function(CacheException value) cache,
    required TResult Function(ClaudeException value) claude,
    required TResult Function(RateLimitException value) rateLimit,
    required TResult Function(UnknownException value) unknown,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ServerException value)? server,
    TResult? Function(NetworkException value)? network,
    TResult? Function(CacheException value)? cache,
    TResult? Function(ClaudeException value)? claude,
    TResult? Function(RateLimitException value)? rateLimit,
    TResult? Function(UnknownException value)? unknown,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ServerException value)? server,
    TResult Function(NetworkException value)? network,
    TResult Function(CacheException value)? cache,
    TResult Function(ClaudeException value)? claude,
    TResult Function(RateLimitException value)? rateLimit,
    TResult Function(UnknownException value)? unknown,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppExceptionCopyWith<AppException> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppExceptionCopyWith<$Res> {
  factory $AppExceptionCopyWith(
    AppException value,
    $Res Function(AppException) then,
  ) = _$AppExceptionCopyWithImpl<$Res, AppException>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$AppExceptionCopyWithImpl<$Res, $Val extends AppException>
    implements $AppExceptionCopyWith<$Res> {
  _$AppExceptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _value.copyWith(
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ServerExceptionImplCopyWith<$Res>
    implements $AppExceptionCopyWith<$Res> {
  factory _$$ServerExceptionImplCopyWith(
    _$ServerExceptionImpl value,
    $Res Function(_$ServerExceptionImpl) then,
  ) = __$$ServerExceptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message, int? statusCode});
}

/// @nodoc
class __$$ServerExceptionImplCopyWithImpl<$Res>
    extends _$AppExceptionCopyWithImpl<$Res, _$ServerExceptionImpl>
    implements _$$ServerExceptionImplCopyWith<$Res> {
  __$$ServerExceptionImplCopyWithImpl(
    _$ServerExceptionImpl _value,
    $Res Function(_$ServerExceptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null, Object? statusCode = freezed}) {
    return _then(
      _$ServerExceptionImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        statusCode: freezed == statusCode
            ? _value.statusCode
            : statusCode // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc

class _$ServerExceptionImpl implements ServerException {
  const _$ServerExceptionImpl({required this.message, this.statusCode});

  @override
  final String message;
  @override
  final int? statusCode;

  @override
  String toString() {
    return 'AppException.server(message: $message, statusCode: $statusCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServerExceptionImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.statusCode, statusCode) ||
                other.statusCode == statusCode));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, statusCode);

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ServerExceptionImplCopyWith<_$ServerExceptionImpl> get copyWith =>
      __$$ServerExceptionImplCopyWithImpl<_$ServerExceptionImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message, int? statusCode) server,
    required TResult Function(String message) network,
    required TResult Function(String message) cache,
    required TResult Function(String message, String? errorType) claude,
    required TResult Function(String message, int? retryAfterSeconds) rateLimit,
    required TResult Function(String message) unknown,
  }) {
    return server(message, statusCode);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message, int? statusCode)? server,
    TResult? Function(String message)? network,
    TResult? Function(String message)? cache,
    TResult? Function(String message, String? errorType)? claude,
    TResult? Function(String message, int? retryAfterSeconds)? rateLimit,
    TResult? Function(String message)? unknown,
  }) {
    return server?.call(message, statusCode);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message, int? statusCode)? server,
    TResult Function(String message)? network,
    TResult Function(String message)? cache,
    TResult Function(String message, String? errorType)? claude,
    TResult Function(String message, int? retryAfterSeconds)? rateLimit,
    TResult Function(String message)? unknown,
    required TResult orElse(),
  }) {
    if (server != null) {
      return server(message, statusCode);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ServerException value) server,
    required TResult Function(NetworkException value) network,
    required TResult Function(CacheException value) cache,
    required TResult Function(ClaudeException value) claude,
    required TResult Function(RateLimitException value) rateLimit,
    required TResult Function(UnknownException value) unknown,
  }) {
    return server(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ServerException value)? server,
    TResult? Function(NetworkException value)? network,
    TResult? Function(CacheException value)? cache,
    TResult? Function(ClaudeException value)? claude,
    TResult? Function(RateLimitException value)? rateLimit,
    TResult? Function(UnknownException value)? unknown,
  }) {
    return server?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ServerException value)? server,
    TResult Function(NetworkException value)? network,
    TResult Function(CacheException value)? cache,
    TResult Function(ClaudeException value)? claude,
    TResult Function(RateLimitException value)? rateLimit,
    TResult Function(UnknownException value)? unknown,
    required TResult orElse(),
  }) {
    if (server != null) {
      return server(this);
    }
    return orElse();
  }
}

abstract class ServerException implements AppException {
  const factory ServerException({
    required final String message,
    final int? statusCode,
  }) = _$ServerExceptionImpl;

  @override
  String get message;
  int? get statusCode;

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ServerExceptionImplCopyWith<_$ServerExceptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NetworkExceptionImplCopyWith<$Res>
    implements $AppExceptionCopyWith<$Res> {
  factory _$$NetworkExceptionImplCopyWith(
    _$NetworkExceptionImpl value,
    $Res Function(_$NetworkExceptionImpl) then,
  ) = __$$NetworkExceptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$NetworkExceptionImplCopyWithImpl<$Res>
    extends _$AppExceptionCopyWithImpl<$Res, _$NetworkExceptionImpl>
    implements _$$NetworkExceptionImplCopyWith<$Res> {
  __$$NetworkExceptionImplCopyWithImpl(
    _$NetworkExceptionImpl _value,
    $Res Function(_$NetworkExceptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$NetworkExceptionImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$NetworkExceptionImpl implements NetworkException {
  const _$NetworkExceptionImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'AppException.network(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NetworkExceptionImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NetworkExceptionImplCopyWith<_$NetworkExceptionImpl> get copyWith =>
      __$$NetworkExceptionImplCopyWithImpl<_$NetworkExceptionImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message, int? statusCode) server,
    required TResult Function(String message) network,
    required TResult Function(String message) cache,
    required TResult Function(String message, String? errorType) claude,
    required TResult Function(String message, int? retryAfterSeconds) rateLimit,
    required TResult Function(String message) unknown,
  }) {
    return network(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message, int? statusCode)? server,
    TResult? Function(String message)? network,
    TResult? Function(String message)? cache,
    TResult? Function(String message, String? errorType)? claude,
    TResult? Function(String message, int? retryAfterSeconds)? rateLimit,
    TResult? Function(String message)? unknown,
  }) {
    return network?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message, int? statusCode)? server,
    TResult Function(String message)? network,
    TResult Function(String message)? cache,
    TResult Function(String message, String? errorType)? claude,
    TResult Function(String message, int? retryAfterSeconds)? rateLimit,
    TResult Function(String message)? unknown,
    required TResult orElse(),
  }) {
    if (network != null) {
      return network(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ServerException value) server,
    required TResult Function(NetworkException value) network,
    required TResult Function(CacheException value) cache,
    required TResult Function(ClaudeException value) claude,
    required TResult Function(RateLimitException value) rateLimit,
    required TResult Function(UnknownException value) unknown,
  }) {
    return network(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ServerException value)? server,
    TResult? Function(NetworkException value)? network,
    TResult? Function(CacheException value)? cache,
    TResult? Function(ClaudeException value)? claude,
    TResult? Function(RateLimitException value)? rateLimit,
    TResult? Function(UnknownException value)? unknown,
  }) {
    return network?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ServerException value)? server,
    TResult Function(NetworkException value)? network,
    TResult Function(CacheException value)? cache,
    TResult Function(ClaudeException value)? claude,
    TResult Function(RateLimitException value)? rateLimit,
    TResult Function(UnknownException value)? unknown,
    required TResult orElse(),
  }) {
    if (network != null) {
      return network(this);
    }
    return orElse();
  }
}

abstract class NetworkException implements AppException {
  const factory NetworkException({required final String message}) =
      _$NetworkExceptionImpl;

  @override
  String get message;

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NetworkExceptionImplCopyWith<_$NetworkExceptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CacheExceptionImplCopyWith<$Res>
    implements $AppExceptionCopyWith<$Res> {
  factory _$$CacheExceptionImplCopyWith(
    _$CacheExceptionImpl value,
    $Res Function(_$CacheExceptionImpl) then,
  ) = __$$CacheExceptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$CacheExceptionImplCopyWithImpl<$Res>
    extends _$AppExceptionCopyWithImpl<$Res, _$CacheExceptionImpl>
    implements _$$CacheExceptionImplCopyWith<$Res> {
  __$$CacheExceptionImplCopyWithImpl(
    _$CacheExceptionImpl _value,
    $Res Function(_$CacheExceptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$CacheExceptionImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$CacheExceptionImpl implements CacheException {
  const _$CacheExceptionImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'AppException.cache(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CacheExceptionImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CacheExceptionImplCopyWith<_$CacheExceptionImpl> get copyWith =>
      __$$CacheExceptionImplCopyWithImpl<_$CacheExceptionImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message, int? statusCode) server,
    required TResult Function(String message) network,
    required TResult Function(String message) cache,
    required TResult Function(String message, String? errorType) claude,
    required TResult Function(String message, int? retryAfterSeconds) rateLimit,
    required TResult Function(String message) unknown,
  }) {
    return cache(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message, int? statusCode)? server,
    TResult? Function(String message)? network,
    TResult? Function(String message)? cache,
    TResult? Function(String message, String? errorType)? claude,
    TResult? Function(String message, int? retryAfterSeconds)? rateLimit,
    TResult? Function(String message)? unknown,
  }) {
    return cache?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message, int? statusCode)? server,
    TResult Function(String message)? network,
    TResult Function(String message)? cache,
    TResult Function(String message, String? errorType)? claude,
    TResult Function(String message, int? retryAfterSeconds)? rateLimit,
    TResult Function(String message)? unknown,
    required TResult orElse(),
  }) {
    if (cache != null) {
      return cache(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ServerException value) server,
    required TResult Function(NetworkException value) network,
    required TResult Function(CacheException value) cache,
    required TResult Function(ClaudeException value) claude,
    required TResult Function(RateLimitException value) rateLimit,
    required TResult Function(UnknownException value) unknown,
  }) {
    return cache(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ServerException value)? server,
    TResult? Function(NetworkException value)? network,
    TResult? Function(CacheException value)? cache,
    TResult? Function(ClaudeException value)? claude,
    TResult? Function(RateLimitException value)? rateLimit,
    TResult? Function(UnknownException value)? unknown,
  }) {
    return cache?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ServerException value)? server,
    TResult Function(NetworkException value)? network,
    TResult Function(CacheException value)? cache,
    TResult Function(ClaudeException value)? claude,
    TResult Function(RateLimitException value)? rateLimit,
    TResult Function(UnknownException value)? unknown,
    required TResult orElse(),
  }) {
    if (cache != null) {
      return cache(this);
    }
    return orElse();
  }
}

abstract class CacheException implements AppException {
  const factory CacheException({required final String message}) =
      _$CacheExceptionImpl;

  @override
  String get message;

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CacheExceptionImplCopyWith<_$CacheExceptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ClaudeExceptionImplCopyWith<$Res>
    implements $AppExceptionCopyWith<$Res> {
  factory _$$ClaudeExceptionImplCopyWith(
    _$ClaudeExceptionImpl value,
    $Res Function(_$ClaudeExceptionImpl) then,
  ) = __$$ClaudeExceptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message, String? errorType});
}

/// @nodoc
class __$$ClaudeExceptionImplCopyWithImpl<$Res>
    extends _$AppExceptionCopyWithImpl<$Res, _$ClaudeExceptionImpl>
    implements _$$ClaudeExceptionImplCopyWith<$Res> {
  __$$ClaudeExceptionImplCopyWithImpl(
    _$ClaudeExceptionImpl _value,
    $Res Function(_$ClaudeExceptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null, Object? errorType = freezed}) {
    return _then(
      _$ClaudeExceptionImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        errorType: freezed == errorType
            ? _value.errorType
            : errorType // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$ClaudeExceptionImpl implements ClaudeException {
  const _$ClaudeExceptionImpl({required this.message, this.errorType});

  @override
  final String message;
  @override
  final String? errorType;

  @override
  String toString() {
    return 'AppException.claude(message: $message, errorType: $errorType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClaudeExceptionImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.errorType, errorType) ||
                other.errorType == errorType));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, errorType);

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClaudeExceptionImplCopyWith<_$ClaudeExceptionImpl> get copyWith =>
      __$$ClaudeExceptionImplCopyWithImpl<_$ClaudeExceptionImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message, int? statusCode) server,
    required TResult Function(String message) network,
    required TResult Function(String message) cache,
    required TResult Function(String message, String? errorType) claude,
    required TResult Function(String message, int? retryAfterSeconds) rateLimit,
    required TResult Function(String message) unknown,
  }) {
    return claude(message, errorType);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message, int? statusCode)? server,
    TResult? Function(String message)? network,
    TResult? Function(String message)? cache,
    TResult? Function(String message, String? errorType)? claude,
    TResult? Function(String message, int? retryAfterSeconds)? rateLimit,
    TResult? Function(String message)? unknown,
  }) {
    return claude?.call(message, errorType);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message, int? statusCode)? server,
    TResult Function(String message)? network,
    TResult Function(String message)? cache,
    TResult Function(String message, String? errorType)? claude,
    TResult Function(String message, int? retryAfterSeconds)? rateLimit,
    TResult Function(String message)? unknown,
    required TResult orElse(),
  }) {
    if (claude != null) {
      return claude(message, errorType);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ServerException value) server,
    required TResult Function(NetworkException value) network,
    required TResult Function(CacheException value) cache,
    required TResult Function(ClaudeException value) claude,
    required TResult Function(RateLimitException value) rateLimit,
    required TResult Function(UnknownException value) unknown,
  }) {
    return claude(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ServerException value)? server,
    TResult? Function(NetworkException value)? network,
    TResult? Function(CacheException value)? cache,
    TResult? Function(ClaudeException value)? claude,
    TResult? Function(RateLimitException value)? rateLimit,
    TResult? Function(UnknownException value)? unknown,
  }) {
    return claude?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ServerException value)? server,
    TResult Function(NetworkException value)? network,
    TResult Function(CacheException value)? cache,
    TResult Function(ClaudeException value)? claude,
    TResult Function(RateLimitException value)? rateLimit,
    TResult Function(UnknownException value)? unknown,
    required TResult orElse(),
  }) {
    if (claude != null) {
      return claude(this);
    }
    return orElse();
  }
}

abstract class ClaudeException implements AppException {
  const factory ClaudeException({
    required final String message,
    final String? errorType,
  }) = _$ClaudeExceptionImpl;

  @override
  String get message;
  String? get errorType;

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClaudeExceptionImplCopyWith<_$ClaudeExceptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RateLimitExceptionImplCopyWith<$Res>
    implements $AppExceptionCopyWith<$Res> {
  factory _$$RateLimitExceptionImplCopyWith(
    _$RateLimitExceptionImpl value,
    $Res Function(_$RateLimitExceptionImpl) then,
  ) = __$$RateLimitExceptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message, int? retryAfterSeconds});
}

/// @nodoc
class __$$RateLimitExceptionImplCopyWithImpl<$Res>
    extends _$AppExceptionCopyWithImpl<$Res, _$RateLimitExceptionImpl>
    implements _$$RateLimitExceptionImplCopyWith<$Res> {
  __$$RateLimitExceptionImplCopyWithImpl(
    _$RateLimitExceptionImpl _value,
    $Res Function(_$RateLimitExceptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null, Object? retryAfterSeconds = freezed}) {
    return _then(
      _$RateLimitExceptionImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        retryAfterSeconds: freezed == retryAfterSeconds
            ? _value.retryAfterSeconds
            : retryAfterSeconds // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc

class _$RateLimitExceptionImpl implements RateLimitException {
  const _$RateLimitExceptionImpl({
    this.message = 'İstek limiti aşıldı. Lütfen bekleyin.',
    this.retryAfterSeconds,
  });

  @override
  @JsonKey()
  final String message;
  @override
  final int? retryAfterSeconds;

  @override
  String toString() {
    return 'AppException.rateLimit(message: $message, retryAfterSeconds: $retryAfterSeconds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RateLimitExceptionImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.retryAfterSeconds, retryAfterSeconds) ||
                other.retryAfterSeconds == retryAfterSeconds));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, retryAfterSeconds);

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RateLimitExceptionImplCopyWith<_$RateLimitExceptionImpl> get copyWith =>
      __$$RateLimitExceptionImplCopyWithImpl<_$RateLimitExceptionImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message, int? statusCode) server,
    required TResult Function(String message) network,
    required TResult Function(String message) cache,
    required TResult Function(String message, String? errorType) claude,
    required TResult Function(String message, int? retryAfterSeconds) rateLimit,
    required TResult Function(String message) unknown,
  }) {
    return rateLimit(message, retryAfterSeconds);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message, int? statusCode)? server,
    TResult? Function(String message)? network,
    TResult? Function(String message)? cache,
    TResult? Function(String message, String? errorType)? claude,
    TResult? Function(String message, int? retryAfterSeconds)? rateLimit,
    TResult? Function(String message)? unknown,
  }) {
    return rateLimit?.call(message, retryAfterSeconds);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message, int? statusCode)? server,
    TResult Function(String message)? network,
    TResult Function(String message)? cache,
    TResult Function(String message, String? errorType)? claude,
    TResult Function(String message, int? retryAfterSeconds)? rateLimit,
    TResult Function(String message)? unknown,
    required TResult orElse(),
  }) {
    if (rateLimit != null) {
      return rateLimit(message, retryAfterSeconds);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ServerException value) server,
    required TResult Function(NetworkException value) network,
    required TResult Function(CacheException value) cache,
    required TResult Function(ClaudeException value) claude,
    required TResult Function(RateLimitException value) rateLimit,
    required TResult Function(UnknownException value) unknown,
  }) {
    return rateLimit(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ServerException value)? server,
    TResult? Function(NetworkException value)? network,
    TResult? Function(CacheException value)? cache,
    TResult? Function(ClaudeException value)? claude,
    TResult? Function(RateLimitException value)? rateLimit,
    TResult? Function(UnknownException value)? unknown,
  }) {
    return rateLimit?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ServerException value)? server,
    TResult Function(NetworkException value)? network,
    TResult Function(CacheException value)? cache,
    TResult Function(ClaudeException value)? claude,
    TResult Function(RateLimitException value)? rateLimit,
    TResult Function(UnknownException value)? unknown,
    required TResult orElse(),
  }) {
    if (rateLimit != null) {
      return rateLimit(this);
    }
    return orElse();
  }
}

abstract class RateLimitException implements AppException {
  const factory RateLimitException({
    final String message,
    final int? retryAfterSeconds,
  }) = _$RateLimitExceptionImpl;

  @override
  String get message;
  int? get retryAfterSeconds;

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RateLimitExceptionImplCopyWith<_$RateLimitExceptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UnknownExceptionImplCopyWith<$Res>
    implements $AppExceptionCopyWith<$Res> {
  factory _$$UnknownExceptionImplCopyWith(
    _$UnknownExceptionImpl value,
    $Res Function(_$UnknownExceptionImpl) then,
  ) = __$$UnknownExceptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$UnknownExceptionImplCopyWithImpl<$Res>
    extends _$AppExceptionCopyWithImpl<$Res, _$UnknownExceptionImpl>
    implements _$$UnknownExceptionImplCopyWith<$Res> {
  __$$UnknownExceptionImplCopyWithImpl(
    _$UnknownExceptionImpl _value,
    $Res Function(_$UnknownExceptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$UnknownExceptionImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$UnknownExceptionImpl implements UnknownException {
  const _$UnknownExceptionImpl({this.message = 'Beklenmeyen bir hata oluştu.'});

  @override
  @JsonKey()
  final String message;

  @override
  String toString() {
    return 'AppException.unknown(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnknownExceptionImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnknownExceptionImplCopyWith<_$UnknownExceptionImpl> get copyWith =>
      __$$UnknownExceptionImplCopyWithImpl<_$UnknownExceptionImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message, int? statusCode) server,
    required TResult Function(String message) network,
    required TResult Function(String message) cache,
    required TResult Function(String message, String? errorType) claude,
    required TResult Function(String message, int? retryAfterSeconds) rateLimit,
    required TResult Function(String message) unknown,
  }) {
    return unknown(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message, int? statusCode)? server,
    TResult? Function(String message)? network,
    TResult? Function(String message)? cache,
    TResult? Function(String message, String? errorType)? claude,
    TResult? Function(String message, int? retryAfterSeconds)? rateLimit,
    TResult? Function(String message)? unknown,
  }) {
    return unknown?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message, int? statusCode)? server,
    TResult Function(String message)? network,
    TResult Function(String message)? cache,
    TResult Function(String message, String? errorType)? claude,
    TResult Function(String message, int? retryAfterSeconds)? rateLimit,
    TResult Function(String message)? unknown,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ServerException value) server,
    required TResult Function(NetworkException value) network,
    required TResult Function(CacheException value) cache,
    required TResult Function(ClaudeException value) claude,
    required TResult Function(RateLimitException value) rateLimit,
    required TResult Function(UnknownException value) unknown,
  }) {
    return unknown(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ServerException value)? server,
    TResult? Function(NetworkException value)? network,
    TResult? Function(CacheException value)? cache,
    TResult? Function(ClaudeException value)? claude,
    TResult? Function(RateLimitException value)? rateLimit,
    TResult? Function(UnknownException value)? unknown,
  }) {
    return unknown?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ServerException value)? server,
    TResult Function(NetworkException value)? network,
    TResult Function(CacheException value)? cache,
    TResult Function(ClaudeException value)? claude,
    TResult Function(RateLimitException value)? rateLimit,
    TResult Function(UnknownException value)? unknown,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown(this);
    }
    return orElse();
  }
}

abstract class UnknownException implements AppException {
  const factory UnknownException({final String message}) =
      _$UnknownExceptionImpl;

  @override
  String get message;

  /// Create a copy of AppException
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnknownExceptionImplCopyWith<_$UnknownExceptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
