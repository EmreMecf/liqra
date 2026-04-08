import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Analytics Servisi
/// Firebase Analytics üzerinde tipli olay API'si
///
/// Kullanım:
///   AnalyticsService.instance.logEvent(AnalyticsEvent.aiMessageSent, params: {'mode': 'budget_audit'});
class AnalyticsService {
  AnalyticsService._();
  static final instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;

  Future<void> init() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      // Debug modda analytics olaylarını devre dışı bırak
      await _analytics!.setAnalyticsCollectionEnabled(!kDebugMode);
      debugPrint('[Analytics] Firebase Analytics başlatıldı');
    } catch (e) {
      debugPrint('[Analytics] Başlatılamadı: $e');
    }
  }

  FirebaseAnalyticsObserver get observer {
    _observer ??= FirebaseAnalyticsObserver(
      analytics: _analytics ?? FirebaseAnalytics.instance,
    );
    return _observer!;
  }

  // ── Ekran Takibi ─────────────────────────────────────────────────────────

  Future<void> logScreen(String screenName) async {
    try {
      await _analytics?.logScreenView(screenName: screenName);
    } catch (_) {}
  }

  // ── Özel Olaylar ─────────────────────────────────────────────────────────

  Future<void> logEvent(
    AnalyticsEvent event, {
    Map<String, Object>? params,
  }) async {
    try {
      await _analytics?.logEvent(
        name:       event.name,
        parameters: params,
      );
      if (kDebugMode) {
        debugPrint('[Analytics] ${event.name}: $params');
      }
    } catch (_) {}
  }

  // ── Kullanıcı Özellikleri ─────────────────────────────────────────────────

  Future<void> setUserProperty(String name, String value) async {
    try {
      await _analytics?.setUserProperty(name: name, value: value);
    } catch (_) {}
  }

  Future<void> setUserId(String userId) async {
    try {
      await _analytics?.setUserId(id: userId);
    } catch (_) {}
  }
}

/// Tip güvenli analitik olayları
enum AnalyticsEvent {
  // Genel
  appOpen('app_open'),
  screenView('screen_view'),

  // AI Asistan
  aiMessageSent('ai_message_sent'),
  aiModeChanged('ai_mode_changed'),
  aiSuggestionTapped('ai_suggestion_tapped'),

  // Harcama
  transactionAdded('transaction_added'),
  transactionDeleted('transaction_deleted'),
  ocrScanStarted('ocr_scan_started'),
  ocrScanSuccess('ocr_scan_success'),
  ocrScanFailed('ocr_scan_failed'),

  // Portföy
  assetAdded('asset_added'),
  assetDeleted('asset_deleted'),
  portfolioRefreshed('portfolio_refreshed'),

  // Piyasa
  marketDataRefreshed('market_data_refreshed'),
  tefasSearched('tefas_searched'),

  // Onboarding
  onboardingCompleted('onboarding_completed'),
  riskProfileSelected('risk_profile_selected'),

  // Hata
  apiError('api_error'),
  crashReported('crash_reported');

  const AnalyticsEvent(this.name);
  final String name;
}
