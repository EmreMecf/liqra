import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Feature Flags & A/B Test Servisi
/// Firebase Remote Config tabanlı — kod deploy etmeden özellik aç/kapat
///
/// Kullanım:
///   final showOcr = FeatureFlagService.instance.isEnabled(FeatureFlag.ocrScanning);
class FeatureFlagService {
  FeatureFlagService._();
  static final instance = FeatureFlagService._();

  FirebaseRemoteConfig? _config;

  // ── Varsayılan değerler (Remote Config'den gelmezse bu değerler kullanılır)
  static const _defaults = <String, dynamic>{
    'feature_ocr_scanning':        true,
    'feature_tefas_search':        true,
    'feature_risk_analysis':       true,
    'feature_ai_monthly_report':   true,
    'feature_portfolio_donut':     true,
    'ab_test_dashboard_variant':   'A',       // 'A' veya 'B'
    'ab_test_ai_suggestions':      false,
    'min_app_version':             '1.0.0',
    'maintenance_mode':            false,
    'ai_rate_limit_per_hour':      20,
    // API keys — Firebase Remote Config'den gelir, varsayılan boş
    'gemini_api_key':              '',
    'collectapi_key':              '',
    'gemini_model':                'gemini-2.0-flash',
  };

  Future<void> init() async {
    try {
      _config = FirebaseRemoteConfig.instance;

      await _config!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout:      const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode
            ? const Duration(minutes: 1)
            : const Duration(hours: 1),
      ));

      await _config!.setDefaults(_defaults);
      await _config!.fetchAndActivate();

      debugPrint('[FeatureFlags] Remote Config yüklendi');
    } catch (e) {
      debugPrint('[FeatureFlags] Remote Config yüklenemedi, varsayılanlar kullanılıyor: $e');
    }
  }

  // ── Feature flag sorgulama ────────────────────────────────────────────────

  bool isEnabled(FeatureFlag flag) {
    if (_config == null) return _defaults[flag.key] as bool? ?? false;
    return _config!.getBool(flag.key);
  }

  String getVariant(AbTest test) {
    if (_config == null) return _defaults[test.key] as String? ?? 'A';
    return _config!.getString(test.key);
  }

  bool isVariantB(AbTest test) => getVariant(test) == 'B';

  int getInt(String key) {
    if (_config == null) return _defaults[key] as int? ?? 0;
    return _config!.getInt(key);
  }

  bool getBool(String key) {
    if (_config == null) return _defaults[key] as bool? ?? false;
    return _config!.getBool(key);
  }

  String getString(String key) {
    if (_config == null) return _defaults[key] as String? ?? '';
    return _config!.getString(key);
  }

  // ── Bakım modu kontrolü ──────────────────────────────────────────────────
  bool get isMaintenanceMode => getBool('maintenance_mode');
}

/// Uygulama feature bayrakları
enum FeatureFlag {
  ocrScanning('feature_ocr_scanning'),
  tefasSearch('feature_tefas_search'),
  riskAnalysis('feature_risk_analysis'),
  aiMonthlyReport('feature_ai_monthly_report'),
  portfolioDonut('feature_portfolio_donut');

  const FeatureFlag(this.key);
  final String key;
}

/// A/B test varyantları
enum AbTest {
  dashboardLayout('ab_test_dashboard_variant'),
  aiSuggestions('ab_test_ai_suggestions');

  const AbTest(this.key);
  final String key;
}
