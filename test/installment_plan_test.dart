import 'package:flutter_test/flutter_test.dart';
import 'package:muhasebe/data/models/money_flow.dart';
import 'package:muhasebe/features/accounts/domain/installment_plan.dart';

/// Taksitli kart alışverişi: kart limiti satın alma anında toplam tutar kadar
/// bloke olur, gider ise taksitlerin vadelerine dağıtılır.
void main() {
  group('Taksit bölme', () {
    test('taksitlerin toplamı satın alma tutarına eşittir', () {
      final parts = InstallmentPlan.build(
        totalAmount: 12000,
        count: 12,
        firstDate: DateTime(2026, 1, 10),
      );
      expect(parts.length, 12);
      expect(parts.fold(0.0, (s, p) => s + p.amount), 12000);
      expect(parts.every((p) => p.amount == 1000), isTrue);
    });

    test('bölünmeyen kuruşlar ilk taksite eklenir — toplam bozulmaz', () {
      final parts = InstallmentPlan.build(
        totalAmount: 100,
        count: 3,
        firstDate: DateTime(2026, 1, 10),
      );
      expect(parts[0].amount, 33.34);
      expect(parts[1].amount, 33.33);
      expect(parts[2].amount, 33.33);
      expect(parts.fold(0.0, (s, p) => s + p.amount), closeTo(100, 0.0001));
    });

    test('vadeler aya göre kayar', () {
      final parts = InstallmentPlan.build(
        totalAmount: 300,
        count: 3,
        firstDate: DateTime(2026, 1, 10),
      );
      expect(parts[0].date, DateTime(2026, 1, 10));
      expect(parts[1].date, DateTime(2026, 2, 10));
      expect(parts[2].date, DateTime(2026, 3, 10));
    });

    test('31 Ocak + 1 ay 3 Mart değil 28 Şubat olur', () {
      final parts = InstallmentPlan.build(
        totalAmount: 200,
        count: 2,
        firstDate: DateTime(2026, 1, 31),
      );
      expect(parts[1].date, DateTime(2026, 2, 28));
    });

    test('yıl sınırını aşan taksitler doğru tarihlenir', () {
      final parts = InstallmentPlan.build(
        totalAmount: 300,
        count: 3,
        firstDate: DateTime(2026, 11, 15),
      );
      expect(parts[2].date, DateTime(2027, 1, 15));
    });

    test('taksit numaraları 1 ile başlar', () {
      final parts = InstallmentPlan.build(
        totalAmount: 300,
        count: 3,
        firstDate: DateTime(2026, 1, 10),
      );
      expect(parts.map((p) => p.number).toList(), [1, 2, 3]);
    });
  });

  group('Taksitli alışverişin muhasebesi', () {
    test('her taksit kendi ayının gideridir — ay bir kez şişmez', () {
      // Eskiden 12.000 TL tek harcama yazılıyordu: o ayın gideri 12.000
      // görünüyor, sonraki 11 ayın yükü hiç görünmüyordu.
      final parts = InstallmentPlan.build(
        totalAmount: 12000,
        count: 12,
        firstDate: DateTime(2026, 1, 10),
      );

      double giderForMonth(int year, int month) => parts
          .where((p) => p.date.year == year && p.date.month == month)
          .fold(0.0, (s, p) => s + p.amount);

      expect(giderForMonth(2026, 1), 1000);
      expect(giderForMonth(2026, 6), 1000);
      expect(giderForMonth(2026, 12), 1000);
    });

    test('taksitler kart harcamasıdır — nakit çıkışı yaratmaz', () {
      // Tahakkuk esası: gider satın almada, nakit çıkışı ödemede.
      expect(MoneyFlow.cardExpense.countsAsExpense, isTrue);
      expect(MoneyFlow.cardExpense.cashDirection, 0);
    });

    test('ekstre devri sadece vadesi gelen taksiti faturalar', () {
      // Devir formülü: yeniEkstre = toplamBorç − kesim sonrası harcamalar.
      // 10 Ocak'ta 12 taksitli 12.000 TL alışveriş, kesim 15 Ocak.
      const toplamBorc = 12000.0;
      final parts = InstallmentPlan.build(
        totalAmount: toplamBorc,
        count: 12,
        firstDate: DateTime(2026, 1, 10),
      );
      final kesim = DateTime(2026, 1, 15);

      final kesimSonrasi = parts
          .where((p) => p.date.isAfter(kesim))
          .fold(0.0, (s, p) => s + p.amount);

      expect(kesimSonrasi, 11000);
      expect(toplamBorc - kesimSonrasi, 1000,
          reason: 'ocak ekstresine yalnızca ilk taksit girer');
    });
  });
}
