import 'package:flutter_test/flutter_test.dart';
import 'package:muhasebe/data/models/money_flow.dart';

void main() {
  // ── Akış semantiği ─────────────────────────────────────────────────────────

  group('MoneyFlow semantiği', () {
    test('yatırım gider DEĞİLDİR ama nakdi azaltır', () {
      expect(MoneyFlow.investment.countsAsExpense, isFalse);
      expect(MoneyFlow.investment.countsAsIncome, isFalse);
      expect(MoneyFlow.investment.cashDirection, -1);
    });

    test('kart ödemesi gider DEĞİLDİR ama nakdi azaltır', () {
      expect(MoneyFlow.cardPayment.countsAsExpense, isFalse);
      expect(MoneyFlow.cardPayment.cashDirection, -1);
    });

    test('kart harcaması giderdir ama nakdi ETKİLEMEZ (tahakkuk)', () {
      expect(MoneyFlow.cardExpense.countsAsExpense, isTrue);
      expect(MoneyFlow.cardExpense.cashDirection, 0);
    });

    test('transfer hiçbir toplamı etkilemez', () {
      expect(MoneyFlow.transfer.countsAsExpense, isFalse);
      expect(MoneyFlow.transfer.countsAsIncome, isFalse);
      expect(MoneyFlow.transfer.cashDirection, 0);
    });

    test('gelir yalnızca gelir sayılır', () {
      expect(MoneyFlow.income.countsAsIncome, isTrue);
      expect(MoneyFlow.income.countsAsExpense, isFalse);
      expect(MoneyFlow.income.cashDirection, 1);
    });

    test('kredi taksidi hem gider hem nakit çıkışıdır', () {
      expect(MoneyFlow.loanPayment.countsAsExpense, isTrue);
      expect(MoneyFlow.loanPayment.cashDirection, -1);
    });

    test('kategori dağılımı yalnızca gider sayılanları içerir', () {
      for (final f in MoneyFlow.values) {
        expect(f.showInCategoryBreakdown, f.countsAsExpense,
            reason: '${f.name} için dağılım ve gider tanımı ayrışmamalı');
      }
    });
  });

  // ── Eski kayıt uyumluluğu ──────────────────────────────────────────────────

  group('MoneyFlowParser — eski kayıtlar', () {
    test('flow alanı varsa doğrudan kullanılır', () {
      expect(
        MoneyFlowParser.parse(rawFlow: 'cardPayment', rawType: 'expense'),
        MoneyFlow.cardPayment,
      );
    });

    test('eski gelir kayıtları (income / gelir)', () {
      expect(MoneyFlowParser.parse(rawType: 'income'), MoneyFlow.income);
      expect(MoneyFlowParser.parse(rawType: 'gelir'), MoneyFlow.income);
    });

    test('eski kart ödemesi ve transfer tipleri', () {
      expect(MoneyFlowParser.parse(rawType: 'creditPayment'),
          MoneyFlow.cardPayment);
      expect(MoneyFlowParser.parse(rawType: 'transfer'), MoneyFlow.transfer);
    });

    test('eski yatırım kaydı kategoriden yakalanır', () {
      // Eski sürüm portföye varlık eklerken bunu "expense" olarak yazıyordu;
      // yatırım olarak tanınmazsa gider sayılır ve çift sayım geri gelir.
      expect(
        MoneyFlowParser.parse(rawType: 'expense', categorySlug: 'yatirim'),
        MoneyFlow.investment,
      );
      expect(
        MoneyFlowParser.parse(rawType: 'gider', categorySlug: 'yatirim'),
        MoneyFlow.investment,
      );
    });

    test('sıradan gider kaydı gider kalır', () {
      expect(
        MoneyFlowParser.parse(rawType: 'expense', categorySlug: 'market'),
        MoneyFlow.expense,
      );
    });

    test('hiçbir bilgi yoksa gidere düşer', () {
      expect(MoneyFlowParser.parse(), MoneyFlow.expense);
      expect(MoneyFlowParser.parse(rawFlow: '', rawType: ''), MoneyFlow.expense);
    });

    test('geçersiz flow değeri type üzerinden çözülür', () {
      expect(
        MoneyFlowParser.parse(rawFlow: 'saçmasapan', rawType: 'income'),
        MoneyFlow.income,
      );
    });
  });

  // ── Kullanıcının bildirdiği çift sayım senaryoları ────────────────────────

  group('Çift sayım senaryoları', () {
    /// Bir hareket listesinin gider ve nakit toplamını hesaplar —
    /// uygulamadaki tek gider tanımının birebir aynısı.
    ({double expense, double cash}) topla(
        List<({MoneyFlow flow, double amount})> hareketler) {
      double expense = 0, cash = 0;
      for (final h in hareketler) {
        if (h.flow.countsAsExpense) expense += h.amount;
        cash += h.amount * h.flow.cashDirection;
      }
      return (expense: expense, cash: cash);
    }

    test('Midas: EFT + hisse ekleme tek kez sayılır', () {
      // 1) Bankadan Midas'a 10.000 ₺ (yatırım hesabına aktarım)
      // 2) Portföye 10.000 ₺'lik hisse eklenir — nakit çıkışı kaydedilmez
      final r = topla([
        (flow: MoneyFlow.investment, amount: 10000),
      ]);
      expect(r.expense, 0, reason: 'yatırım gider sayılmamalı');
      expect(r.cash, -10000, reason: 'nakit bir kez azalmalı');
    });

    test('Midas: kullanıcı hem EFT hem varlık kaydederse gider yine 0', () {
      // En kötü durum: kullanıcı iki kayıt da oluşturdu.
      // Gider hâlâ 0 — eski davranışta 20.000 ₺ gider görünüyordu.
      final r = topla([
        (flow: MoneyFlow.investment, amount: 10000), // EFT
        (flow: MoneyFlow.investment, amount: 10000), // varlık ekleme
      ]);
      expect(r.expense, 0);
      expect(r.cash, -20000);
    });

    test('IBAN ile altın alımı gider sayılmaz', () {
      final r = topla([
        (flow: MoneyFlow.investment, amount: 25000),
      ]);
      expect(r.expense, 0);
      expect(r.cash, -25000);
    });

    test('Kredi kartı: harcama gider, ödeme değil — çift sayım yok', () {
      // Kartla 3.000 ₺ harcandı, ay sonu 3.000 ₺ ödendi.
      final r = topla([
        (flow: MoneyFlow.cardExpense, amount: 3000),
        (flow: MoneyFlow.cardPayment, amount: 3000),
      ]);
      expect(r.expense, 3000, reason: 'harcama bir kez gider sayılmalı');
      expect(r.cash, -3000, reason: 'nakit yalnızca ödeme anında azalmalı');
    });

    test('Kart harcaması ödenmeden önce de gider sayılır (tahakkuk)', () {
      final r = topla([
        (flow: MoneyFlow.cardExpense, amount: 1500),
      ]);
      expect(r.expense, 1500, reason: 'gider satın alma anında görünmeli');
      expect(r.cash, 0, reason: 'henüz nakit çıkmadı');
    });

    test('Hesaplar arası transfer hiçbir toplamı bozmaz', () {
      final r = topla([
        (flow: MoneyFlow.transfer, amount: 5000),
        (flow: MoneyFlow.transfer, amount: 5000),
      ]);
      expect(r.expense, 0);
      expect(r.cash, 0);
    });

    test('Karışık ay: yalnızca gerçek tüketim gider sayılır', () {
      final r = topla([
        (flow: MoneyFlow.income,      amount: 50000), // maaş
        (flow: MoneyFlow.expense,     amount: 4000),  // market
        (flow: MoneyFlow.cardExpense, amount: 2000),  // kartla yemek
        (flow: MoneyFlow.investment,  amount: 10000), // Midas'a EFT
        (flow: MoneyFlow.cardPayment, amount: 2000),  // geçen ayın kartı
        (flow: MoneyFlow.transfer,    amount: 3000),  // hesaplar arası
      ]);
      // Gider = market + kart harcaması
      expect(r.expense, 6000);
      // Nakit = +50000 -4000 -10000 -2000 (kart harcaması ve transfer nötr)
      expect(r.cash, 34000);
    });
  });
}
