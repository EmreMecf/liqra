import 'billing_cycle.dart';
import 'entities/financial_account_entity.dart';

/// Ekstre kesimini otomatikleştirir.
///
/// ── Neden gerekli ───────────────────────────────────────────────────────────
/// `statementClosingDay` eskiden yalnızca bir rozetti: hiçbir hesaplamada
/// kullanılmıyordu. Kart harcaması yapılınca `usedAmount` artıyor, ekstre borcu
/// olduğu yerde kalıyordu; kullanıcı her ay ekstre tutarını elle girmek
/// zorundaydı.
///
/// ── Kural ───────────────────────────────────────────────────────────────────
/// Kesim gününde, o ana kadar birikmiş TÜM borç ekstreye yazılır. Kesimden
/// sonraki harcamalar bir sonraki ekstreye kalır:
///
/// ```
/// yeniEkstre = toplamBorç − kesimden sonraki harcamalar
/// ```
///
/// Bu formül elle girilen açılış bakiyesiyle de doğru çalışır: kart eklenirken
/// yazılan borcun arkasında işlem kaydı olmasa bile `usedAmount` içinde durur
/// ve ilk kesimde ekstreye geçer.
///
/// ── Neden güvenli ───────────────────────────────────────────────────────────
/// Karta yazılan `statementClosedAt`, kayıtlı ekstrenin hangi kesime ait
/// olduğunu söyler. Devir yalnızca daha yeni bir kesim geçmişse çalışır, bu
/// yüzden **idempotenttir** — uygulama günde on kez açılsa da ekstre bir kez
/// kesilir.
class StatementRollover {
  /// Asgari ödeme oranı. Türkiye'de yaygın uygulama ekstre borcunun %20'sidir;
  /// bankaya göre değişebildiği için kullanıcı ekstre ekranından düzeltebilir.
  static const minimumPaymentRatio = 0.20;

  const StatementRollover._();

  /// Kartın ekstresi kesilmeli mi?
  /// [now] yalnızca test için verilir; üretimde bugünün tarihi kullanılır.
  static bool isDue(CreditCardEntity card, {DateTime? now}) =>
      _pendingClosing(card, now) != null;

  /// Devri uygulanmış kartı döner; gerek yoksa `null`.
  ///
  /// [unbilledSinceClosing] kesim tarihinden SONRA yapılan kart harcamalarının
  /// toplamıdır — geleceğe tarihli taksitler dahil. Devir uygulama açılışında
  /// tembel çalıştığı için kesim ile bugün arasında yapılmış harcamaların
  /// yanlışlıkla faturalanmasını bu tutar engeller.
  static CreditCardEntity? apply(
    CreditCardEntity card, {
    required double unbilledSinceClosing,
    DateTime? now,
  }) {
    final closing = _pendingClosing(card, now);
    if (closing == null) return null;

    // Kart, son kesimden sonra eklendiyse kullanıcının girdiği ekstre
    // geçerlidir — sadece tarihi damgala, tutarlara dokunma.
    if (closing.isBefore(BillingCycle.dateOnly(card.createdAt))) {
      return card.copyWith(statementClosedAt: closing);
    }

    final billed =
        (card.usedAmount - unbilledSinceClosing).clamp(0.0, double.infinity);

    return card.copyWith(
      statementBalance: _round2(billed),
      minimumPayment: _round2(billed * minimumPaymentRatio),
      statementClosedAt: closing,
    );
  }

  /// Henüz işlenmemiş kesim tarihi (yoksa null).
  static DateTime? _pendingClosing(CreditCardEntity card, DateTime? now) {
    final closing = BillingCycle(
      closingDay: card.statementClosingDay,
      dueDay:     card.paymentDueDay,
      now:        now,
    ).lastClosingDate;
    final processed = card.statementClosedAt;
    if (processed != null &&
        !BillingCycle.dateOnly(processed).isBefore(closing)) {
      return null; // bu kesim zaten işlendi
    }
    return closing;
  }

  static double _round2(double v) => (v * 100).roundToDouble() / 100;
}
