import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/notification_preferences.dart';
import '../../../core/services/notification_service.dart';
import 'assistant_context.dart';
import 'assistant_insight.dart';
import 'campaign_matcher.dart';

/// İçgörüleri ve kampanya eşleşmelerini bildirime dönüştürür.
///
/// ── Tasarım kararları ───────────────────────────────────────────────────────
/// • **Aynı gün aynı bildirim gönderilmez.** Her içgörünün sabit bir `id`si
///   var; gönderilen id + tarih SharedPreferences'a yazılır. Uygulama günde on
///   kez açılsa da kullanıcı aynı uyarıyı bir kez görür.
/// • **Günlük tavan var.** En fazla [maxPerDay] bildirim gönderilir; aciliyeti
///   yüksek olanlar önce gider. Bildirim yağmuru uygulamayı sessize aldırır.
/// • **Her içgörü bildirilmez.** Yalnızca `notify: true` olanlar telefona
///   düşer; kalanlar uygulama içinde kart olarak görünür.
/// • **Kullanıcının bildirim tercihlerine uyulur** (bkz.
///   [NotificationPreferences]). Profil ekranındaki anahtarlar eskiden
///   yalnızca kaydediliyor, hiç okunmuyordu.
class AssistantNotifier {
  AssistantNotifier._();
  static final instance = AssistantNotifier._();

  static const _prefix = 'assistant_notified_';
  static const maxPerDay = 3;

  /// Bildirimleri değerlendirir ve gönderir. Gönderilen içgörüleri döner.
  Future<List<AssistantInsight>> run({
    required AssistantContext context,
    Set<String> userBanks = const {},
  }) async {
    final insights = InsightEngine.analyze(context);
    final campaigns = CampaignMatcher.toInsights(
      CampaignMatcher.match(context, userBanks: userBanks),
    );

    final candidates = [...insights, ...campaigns].where((i) => i.notify);

    final prefs = await SharedPreferences.getInstance();
    final today = _dayKey(context.now);
    final sent = <AssistantInsight>[];

    for (final insight in candidates) {
      if (sent.length >= maxPerDay) break;

      // Kullanıcı bu türü kapattıysa gönderme
      if (!await NotificationPreferences.instance.allows(insight)) continue;

      final key = '$_prefix${insight.id}';
      if (prefs.getString(key) == today) continue; // bugün zaten gönderildi

      try {
        await NotificationService.instance.showLocalNotification(
          title: '${insight.emoji} ${insight.title}',
          body: insight.body,
          payload: insight.route,
        );
        await prefs.setString(key, today);
        sent.add(insight);
      } catch (e) {
        // Bildirim izni yoksa sessizce geç — uygulama içi kartlar yine görünür.
        debugPrint('[AssistantNotifier] gönderilemedi: $e');
      }
    }

    if (sent.isNotEmpty) {
      debugPrint('[AssistantNotifier] ${sent.length} bildirim gönderildi.');
    }
    return sent;
  }

  /// Test veya "bildirimleri sıfırla" ayarı için.
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where((k) => k.startsWith(_prefix))) {
      await prefs.remove(key);
    }
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
