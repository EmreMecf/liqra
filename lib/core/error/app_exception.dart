import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_exception.freezed.dart';

/// Uygulama genelinde hata sınıfı — freezed sealed union
@freezed
sealed class AppException with _$AppException implements Exception {
  /// Sunucu 4xx-5xx hataları
  const factory AppException.server({
    required String message,
    int? statusCode,
  }) = ServerException;

  /// Ağ bağlantısı / timeout hataları
  const factory AppException.network({
    required String message,
  }) = NetworkException;

  /// Yerel depolama hataları
  const factory AppException.cache({
    required String message,
  }) = CacheException;

  /// Claude API spesifik hatalar
  const factory AppException.claude({
    required String message,
    String? errorType,
  }) = ClaudeException;

  /// Rate limit aşımı
  const factory AppException.rateLimit({
    @Default('İstek limiti aşıldı. Lütfen bekleyin.') String message,
    int? retryAfterSeconds,
  }) = RateLimitException;

  /// Bilinmeyen / beklenmeyen hatalar
  const factory AppException.unknown({
    @Default('Beklenmeyen bir hata oluştu.') String message,
  }) = UnknownException;
}

extension AppExceptionX on AppException {
  String get userMessage => switch (this) {
    ServerException e   => e.statusCode == 401 ? 'Oturum süresi doldu.' : e.message,
    NetworkException _  => 'İnternet bağlantısı yok. Lütfen kontrol edin.',
    CacheException e    => e.message,
    ClaudeException e   => 'AI asistan hatası: ${e.message}',
    RateLimitException e => e.message,
    UnknownException e  => e.message,
  };
}
