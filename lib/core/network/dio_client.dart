import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../error/app_exception.dart';

/// Uygulama genelinde Dio HTTP istemcisi
/// Interceptor zinciri: Auth → Logger → Error Handler
class DioClient {
  DioClient._();

  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      if (kDebugMode) _LogInterceptor(),
      _AuthInterceptor(),
      _ErrorInterceptor(),
    ]);

    return dio;
  }

  /// Test veya farklı base URL için yeni instance
  static Dio createWithBaseUrl(String baseUrl) {
    return Dio(BaseOptions(baseUrl: baseUrl))
      ..interceptors.addAll([
        if (kDebugMode) _LogInterceptor(),
        _AuthInterceptor(),
        _ErrorInterceptor(),
      ]);
  }
}

/// Uygulama konfigürasyonu
class AppConfig {
  // dart-define ile override edilebilir:
  //   flutter run --dart-define=API_BASE_URL=https://api.example.com
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  // Rate limit — kullanıcı başı saatte 20 istek (ücretsiz tier)
  static const int aiRateLimitPerHour = 20;
}

// ── Interceptors ──────────────────────────────────────────────────────────────

/// Firebase Auth ID token'ını her isteğe ekler
class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
    } catch (_) {
      // Auth hatası isteği durdurmasın
    }
    handler.next(options);
  }
}

/// Debug loglar
class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[DIO] → ${options.method} ${options.path}');
    if (options.data != null) debugPrint('[DIO] Body: ${options.data}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('[DIO] ← ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('[DIO] ✗ ${err.type}: ${err.message}');
    handler.next(err);
  }
}

/// DioException → AppException dönüşümü
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appEx = switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        const AppException.network(message: 'Bağlantı zaman aşımına uğradı.'),

      DioExceptionType.connectionError =>
        const AppException.network(message: 'Sunucuya bağlanılamıyor.'),

      DioExceptionType.badResponse => _parseServerError(err.response),

      _ => AppException.unknown(message: err.message ?? 'Bilinmeyen hata'),
    };

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: appEx,
        type: err.type,
        response: err.response,
      ),
    );
  }

  AppException _parseServerError(Response? response) {
    final statusCode = response?.statusCode ?? 0;
    final message = response?.data?['error'] as String? ??
        response?.data?['message'] as String? ??
        'Sunucu hatası ($statusCode)';

    return switch (statusCode) {
      429 => AppException.rateLimit(
          message: message,
          retryAfterSeconds: int.tryParse(
              response?.headers.value('retry-after') ?? ''),
        ),
      401 => AppException.server(message: 'Yetkisiz erişim.', statusCode: 401),
      _ => AppException.server(message: message, statusCode: statusCode),
    };
  }
}

/// Dio hatasından AppException çekme yardımcısı
extension DioExceptionX on DioException {
  AppException get appException =>
      error is AppException ? error as AppException : const AppException.unknown();
}
