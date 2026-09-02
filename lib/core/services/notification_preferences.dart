import 'package:shared_preferences/shared_preferences.dart';

import '../../features/ai_assistant/domain/assistant_insight.dart';

/// Kullanıcının bildirim tercihleri.
///
/// ── Neden gerekli ───────────────────────────────────────────────────────────
/// Profil ekranındaki anahtarlar SharedPreferences'a yazıyordu ama bu değerleri
/// **hiç kimse okumuyordu**. "Bütçe Aşımı Uyarısı"nı kapatan kullanıcı yine
/// bildirim alıyordu — ayar kullanıcıya yalan söylüyordu.
///
/// Anahtar adları profil ekranındaki `prefKey` değerleriyle birebir aynıdır.
class NotificationPreferences {
  NotificationPreferences._();
  static final instance = NotificationPreferences._();

  /// Aylık AI raporu / genel asistan özetleri.
  static const monthlyReport = 'notif_monthly_ai';

  /// Bütçe ve harcama uyarıları (kart ödemesi, kategori sıçraması, açık).
  static const budgetWarning = 'notif_budget_warn';

  /// Piyasa ve portföy hareketleri.
  static const marketAlert = 'notif_market_alarm';

  /// Varsayılanlar — profil ekranındaki başlangıç değerleriyle aynı.
  static const _defaults = <String, bool>{
    monthlyReport: true,
    budgetWarning: true,
    marketAlert: false,
  };

  Future<bool> isEnabled(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? _defaults[key] ?? true;
  }

  /// Bir içgörünün bildirilmesine izin var mı?
  ///
  /// İçgörü kimliğinden hangi tercihe ait olduğu türetilir; böylece yeni bir
  /// içgörü eklendiğinde burayı güncellemek gerekmez.
  Future<bool> allows(AssistantInsight insight) =>
      isEnabled(categoryOf(insight.id));

  /// İçgörü kimliği → tercih anahtarı.
  static String categoryOf(String insightId) {
    if (insightId.startsWith('move_') ||
        insightId.startsWith('concentration_') ||
        insightId == 'idle_cash') {
      return marketAlert;
    }
    if (insightId.startsWith('campaign_')) return monthlyReport;
    // Kart, nakit, harcama ve hedef uyarılarının tamamı bütçe başlığındadır.
    return budgetWarning;
  }
}
