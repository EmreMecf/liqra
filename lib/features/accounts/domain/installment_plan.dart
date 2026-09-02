import 'billing_cycle.dart';

/// Bir taksitin tutarı ve vadesi.
class InstallmentPart {
  final int number;
  final double amount;
  final DateTime date;

  const InstallmentPart({
    required this.number,
    required this.amount,
    required this.date,
  });
}

/// Taksitli alışverişi aylara böler.
///
/// ── Neden ayrı ──────────────────────────────────────────────────────────────
/// `isInstallment` / `installmentCount` alanları veri modelinde vardı ve işlem
/// satırında "3/12" rozeti olarak gösteriliyordu, ama bu değerleri girecek bir
/// ekran yoktu: 12 taksitli bir alışveriş tek seferlik harcama gibi
/// kaydediliyor, o ayın gideri şişiyor, sonraki 11 ayın yükü hiç görünmüyordu.
///
/// ── Kurallar ────────────────────────────────────────────────────────────────
/// • Taksitlerin toplamı **daima** satın alma tutarına eşittir — bölünmeden
///   artan kuruşlar ilk taksite eklenir.
/// • Vadeler aya göre kaydırılır; ayın gün sayısını aşan günler ayın son
///   gününe sabitlenir (31 Ocak + 1 ay → 28 Şubat).
class InstallmentPlan {
  const InstallmentPlan._();

  /// Yaygın taksit adetleri — arayüzdeki seçici bu listeyi kullanır.
  static const commonCounts = [1, 2, 3, 6, 9, 12, 18, 24];

  static List<InstallmentPart> build({
    required double totalAmount,
    required int count,
    required DateTime firstDate,
  }) {
    if (count < 1) return const [];

    // Kuruş cinsinden böl — çift hassasiyet kaybı toplamı bozmasın.
    final cents = (totalAmount * 100).round();
    final base = cents ~/ count;
    final remainder = cents - base * count;

    return List.generate(count, (i) {
      final amountCents = base + (i == 0 ? remainder : 0);
      return InstallmentPart(
        number: i + 1,
        amount: amountCents / 100,
        date: BillingCycle.dayInMonth(
          firstDate.year,
          firstDate.month + i,
          firstDate.day,
        ),
      );
    });
  }
}
