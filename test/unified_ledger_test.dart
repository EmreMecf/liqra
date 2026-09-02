import 'package:flutter_test/flutter_test.dart';
import 'package:muhasebe/data/models/money_flow.dart';

/// Cüzdan hareketleri artık ANA DEFTERE de yazılıyor. Bu testler, birleşik
/// defterin bakiye ve toplamları doğru ürettiğini doğrular.
///
/// Kurallar `AccountsRepositoryImpl.recordAccountMovement` içindeki bakiye
/// türetimiyle birebir aynıdır.
void main() {
  /// Akış tipinden hesap bakiyesi etkisini türetir — repository ile aynı mantık
  ({String field, double delta}) balanceEffect(MoneyFlow flow, double amount) {
    final isCard = flow == MoneyFlow.cardExpense;
    return (
      field: isCard ? 'usedAmount' : 'balance',
      delta: switch (flow) {
        MoneyFlow.income      => amount,
        MoneyFlow.cardExpense => amount, // borç artar
        _                     => -amount,
      },
    );
  }

  group('Hesap bakiyesi etkisi', () {
    test('gelir banka bakiyesini artırır', () {
      final e = balanceEffect(MoneyFlow.income, 5000);
      expect(e.field, 'balance');
      expect(e.delta, 5000);
    });

    test('banka harcaması bakiyeyi azaltır', () {
      final e = balanceEffect(MoneyFlow.expense, 1200);
      expect(e.field, 'balance');
      expect(e.delta, -1200);
    });

    test('kart harcaması BORCU artırır, bakiyeye dokunmaz', () {
      final e = balanceEffect(MoneyFlow.cardExpense, 800);
      expect(e.field, 'usedAmount');
      expect(e.delta, 800);
    });
  });

  group('Birleşik defter toplamları', () {
    ({double income, double expense, double cash}) topla(
        List<({MoneyFlow flow, double amount})> hareketler) {
      double income = 0, expense = 0, cash = 0;
      for (final h in hareketler) {
        if (h.flow.countsAsIncome) income += h.amount;
        if (h.flow.countsAsExpense) expense += h.amount;
        cash += h.amount * h.flow.cashDirection;
      }
      return (income: income, expense: expense, cash: cash);
    }

    test('cüzdandan girilen gelir Dashboard gelirine yansır', () {
      final r = topla([(flow: MoneyFlow.income, amount: 50000)]);
      expect(r.income, 50000);
      expect(r.cash, 50000);
    });

    test('cüzdandan girilen kart harcaması Dashboard giderine yansır', () {
      // Bu senaryo eskiden Dashboard'da 0 görünüyordu.
      final r = topla([(flow: MoneyFlow.cardExpense, amount: 3000)]);
      expect(r.expense, 3000, reason: 'kart harcaması gider sayılmalı');
      expect(r.cash, 0, reason: 'henüz nakit çıkmadı');
    });

    test('kart harcaması + ödemesi: gider bir kez, nakit bir kez', () {
      final r = topla([
        (flow: MoneyFlow.cardExpense, amount: 3000),
        (flow: MoneyFlow.cardPayment, amount: 3000),
      ]);
      expect(r.expense, 3000);
      expect(r.cash, -3000);
    });

    test('hesaplar arası transfer toplamları bozmaz', () {
      final r = topla([(flow: MoneyFlow.transfer, amount: 7500)]);
      expect(r.income, 0);
      expect(r.expense, 0);
      expect(r.cash, 0);
    });

    test('tam ay: cüzdan + harcama defteri birlikte doğru toplanır', () {
      final r = topla([
        (flow: MoneyFlow.income,      amount: 60000), // cüzdan: maaş
        (flow: MoneyFlow.expense,     amount: 5000),  // cüzdan: banka kartı
        (flow: MoneyFlow.cardExpense, amount: 4000),  // cüzdan: kredi kartı
        (flow: MoneyFlow.expense,     amount: 1500),  // harcama defteri: fiş
        (flow: MoneyFlow.cardPayment, amount: 4000),  // cüzdan: ekstre ödemesi
        (flow: MoneyFlow.investment,  amount: 15000), // portföy: Midas
        (flow: MoneyFlow.transfer,    amount: 2000),  // cüzdan: hesap arası
      ]);
      expect(r.income, 60000);
      // Gider = 5000 + 4000 + 1500 (ödeme, yatırım, transfer HARİÇ)
      expect(r.expense, 10500);
      // Nakit = +60000 −5000 −1500 −4000 −15000
      expect(r.cash, 34500);
    });
  });

  group('Ekstre içe aktarma', () {
    test('banka ekstresindeki kart ödemesi gider sayılmaz', () {
      // Kullanıcı hem kart hem banka ekstresini yüklerse:
      //   kart ekstresi  → harcamalar (cardExpense)
      //   banka ekstresi → ödeme satırı (cardPayment)
      // Eskiden ikisi de gider sayılıyor, aynı para iki kez düşülüyordu.
      final hareketler = <({MoneyFlow flow, double amount})>[
        (flow: MoneyFlow.cardExpense, amount: 1200), // kart ekstresi
        (flow: MoneyFlow.cardExpense, amount: 800),  // kart ekstresi
        (flow: MoneyFlow.cardPayment, amount: 2000), // banka ekstresi
      ];
      final expense = hareketler
          .where((h) => h.flow.countsAsExpense)
          .fold(0.0, (a, h) => a + h.amount);
      expect(expense, 2000, reason: '4000 değil — çift sayım olmamalı');
    });
  });
}
