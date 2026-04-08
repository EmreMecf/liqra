import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Crashlytics Servisi
/// Flutter hata akışını Crashlytics'e yönlendirir
///
/// main() içinde CrashService.instance.init() çağrılmalı
class CrashService {
  CrashService._();
  static final instance = CrashService._();

  FirebaseCrashlytics? _crashlytics;

  Future<void> init() async {
    try {
      _crashlytics = FirebaseCrashlytics.instance;

      // Release modda etkinleştir, debug modda devre dışı
      await _crashlytics!.setCrashlyticsCollectionEnabled(!kDebugMode);

      // Flutter framework hatalarını Crashlytics'e gönder
      FlutterError.onError = _crashlytics!.recordFlutterFatalError;

      // Dart async hatalarını yakala (PlatformDispatcher)
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics!.recordError(error, stack, fatal: true);
        return true;
      };

      debugPrint('[Crashlytics] Başlatıldı (koleksiyon: ${!kDebugMode})');
    } catch (e) {
      debugPrint('[Crashlytics] Başlatılamadı: $e');
    }
  }

  // ── Manuel Hata Raporlama ─────────────────────────────────────────────────

  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    if (kDebugMode) {
      debugPrint('[Crashlytics] Hata: $exception\n$stack');
      return;
    }
    try {
      await _crashlytics?.recordError(
        exception, stack,
        reason: reason,
        fatal:  fatal,
      );
    } catch (_) {}
  }

  Future<void> log(String message) async {
    try {
      await _crashlytics?.log(message);
    } catch (_) {}
  }

  Future<void> setUserId(String userId) async {
    try {
      await _crashlytics?.setUserIdentifier(userId);
    } catch (_) {}
  }

  Future<void> setCustomKey(String key, Object value) async {
    try {
      await _crashlytics?.setCustomKey(key, value);
    } catch (_) {}
  }
}
