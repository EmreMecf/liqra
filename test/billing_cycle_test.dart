import 'package:flutter_test/flutter_test.dart';
import 'package:muhasebe/features/accounts/domain/billing_cycle.dart';
import 'package:muhasebe/features/accounts/domain/entities/financial_account_entity.dart';
import 'package:muhasebe/features/accounts/domain/statement_rollover.dart';

/// Bu testler cüzdan denetiminde bulunan tarih hatalarını kayda geçirir.
/// Her grup, düzeltilmeden önce YANLIŞ davranan bir senaryoyu tutar.
void main() {
  CreditCardEntity card({
    double limit = 50000,
    double used = 0,
    double statement = 0,
    double minimum = 0,
    int closingDay = 15,
    int dueDay = 5,
    DateTime? closedAt,
    DateTime? createdAt,
  }) =>
      CreditCardEntity(
        id: 'c1',
        userId: 'u1',
        name: 'Test Kart',
        bank: BankName.garanti,
        creditLimit: limit,
        usedAmount: used,
        statementBalance: statement,
        minimumPayment: minimum,
        statementClosingDay: closingDay,
        paymentDueDay: dueDay,
        statementClosedAt: closedAt,
        createdAt: createdAt ?? DateTime(2020, 1, 1),
      );

  group('Ay taşması', () {
    test("31 çekmeyen ayda son güne sabitlenir — 3 Mart'a taşmaz", () {
      // DateTime(2026, 2, 31) sessizce 3 Mart üretir; kullanıcı yanlış tarih görür.
      expect(BillingCycle.dayInMonth(2026, 2, 31), DateTime(2026, 2, 28));
    });

    test('artık yılda 29 Şubat verir', () {
      expect(BillingCycle.dayInMonth(2028, 2, 31), DateTime(2028, 2, 29));
    });

    test('30 çeken ayda 31 → ayın son günü', () {
      expect(BillingCycle.dayInMonth(2026, 4, 31), DateTime(2026, 4, 30));
    });

    test('yıl taşması doğru hesaplanır', () {
      expect(BillingCycle.dayInMonth(2026, 13, 10), DateTime(2027, 1, 10));
    });
  });

  group('Son ödeme günü', () {
    test('ödeme günü BUGÜN ise bir ay ileri atlamaz', () {
      // Eski kod gece yarısını saat 14:00 ile karşılaştırıp "geçmiş" sayıyor,
      // tarihi bir ay ileri atıyor ve son gün uyarısı tamamen kayboluyordu.
      final c = BillingCycle(
        closingDay: 25,
        dueDay: 10,
        now: DateTime(2026, 3, 10, 14, 30),
      );
      expect(c.nextDueDate, DateTime(2026, 3, 10));
      expect(c.daysUntilDue, 0);
    });

    test('yarın dolacak ödeme 1 gün gösterir — 0 değil', () {
      // .inDays kırpması yüzünden 10 saatlik fark 0 gün görünüyordu.
      final c = BillingCycle(
        closingDay: 25,
        dueDay: 10,
        now: DateTime(2026, 3, 9, 14, 0),
      );
      expect(c.daysUntilDue, 1);
    });

    test('kesim gününden büyük ödeme günü AYNI ay içindedir', () {
      final c =
          BillingCycle(closingDay: 1, dueDay: 10, now: DateTime(2026, 3, 5));
      expect(c.currentDueDate, DateTime(2026, 3, 10));
    });

    test('kesim gününden küçük ödeme günü SONRAKİ aya sarkar', () {
      final c =
          BillingCycle(closingDay: 15, dueDay: 5, now: DateTime(2026, 3, 20));
      expect(c.lastClosingDate, DateTime(2026, 3, 15));
      expect(c.currentDueDate, DateTime(2026, 4, 5));
    });
  });

  group('Gecikme tespiti', () {
    test('son ödeme tarihi geçmişse isPastDue true olur', () {
      // Eski tanım (daysUntilDue < 0) hiçbir zaman sağlanamıyordu.
      final c =
          BillingCycle(closingDay: 15, dueDay: 5, now: DateTime(2026, 3, 10));
      expect(c.currentDueDate, DateTime(2026, 3, 5));
      expect(c.isPastDue, isTrue);
      expect(c.daysPastDue, 5);
      // Bir sonraki ödeme yine de ileriye bakar
      expect(c.nextDueDate, DateTime(2026, 4, 5));
    });

    test('borç yoksa kart gecikmiş sayılmaz', () {
      expect(card(used: 0, statement: 0).isOverdue, isFalse);
    });

    test('ödeme günü henüz gelmemişse gecikme yoktur', () {
      final c =
          BillingCycle(closingDay: 15, dueDay: 5, now: DateTime(2026, 3, 3));
      expect(c.isPastDue, isFalse);
      expect(c.daysPastDue, 0);
    });
  });

  group('Kesim tarihleri', () {
    test('kesim günü henüz gelmediyse geçen ayın kesimi geçerlidir', () {
      final c =
          BillingCycle(closingDay: 15, dueDay: 5, now: DateTime(2026, 3, 10));
      expect(c.lastClosingDate, DateTime(2026, 2, 15));
      expect(c.nextClosingDate, DateTime(2026, 3, 15));
    });

    test('kesim günü bugünse ekstre BUGÜN kapanmıştır', () {
      final c =
          BillingCycle(closingDay: 15, dueDay: 5, now: DateTime(2026, 3, 15));
      expect(c.lastClosingDate, DateTime(2026, 3, 15));
    });

    test('kesim günü 31 iken şubatta son güne düşer', () {
      final c =
          BillingCycle(closingDay: 31, dueDay: 20, now: DateTime(2026, 2, 28));
      expect(c.lastClosingDate, DateTime(2026, 2, 28));
    });

    test('harcamanın hangi ekstreye gireceği bulunur', () {
      final c =
          BillingCycle(closingDay: 15, dueDay: 5, now: DateTime(2026, 3, 20));
      // Kesimden önceki harcama bu ayın ekstresine girer
      expect(
          c.closingDateForPurchase(DateTime(2026, 3, 10)), DateTime(2026, 3, 15));
      // Kesimden sonraki harcama gelecek ekstreye kalır
      expect(
          c.closingDateForPurchase(DateTime(2026, 3, 18)), DateTime(2026, 4, 15));
    });
  });

  group('Ekstre devri', () {
    test('kesimde tüm borç ekstreye yazılır, sonraki harcamalar kalır', () {
      final c = card(used: 12000, statement: 0);
      final rolled = StatementRollover.apply(c, unbilledSinceClosing: 11000);

      expect(rolled, isNotNull);
      expect(rolled!.statementBalance, 1000);
      expect(rolled.unbilledAmount, 11000);
      expect(rolled.minimumPayment, 200); // %20
      expect(rolled.statementClosedAt, c.lastClosingDate);
    });

    test('devir idempotenttir — ikinci çağrıda hiçbir şey yapmaz', () {
      // Uygulama günde on kez açılsa da ekstre bir kez kesilmeli.
      final first = StatementRollover.apply(
        card(used: 5000),
        unbilledSinceClosing: 0,
      )!;
      expect(StatementRollover.isDue(first), isFalse);
      expect(StatementRollover.apply(first, unbilledSinceClosing: 0), isNull);
    });

    test('elle girilen açılış bakiyesi ilk kesimde ekstreye geçer', () {
      // Kart eklenirken 10.000 borç / 3.000 ekstre girildi; 7.000'in arkasında
      // hiçbir işlem kaydı yok. Devir bu tutarı yine de faturalar.
      final c = card(used: 10000, statement: 3000);
      final rolled = StatementRollover.apply(c, unbilledSinceClosing: 0)!;
      expect(rolled.statementBalance, 10000);
      expect(rolled.unbilledAmount, 0);
    });

    test('son kesimden sonra eklenen kartın tutarlarına dokunulmaz', () {
      final c = card(
        used: 4000,
        statement: 1500,
        minimum: 300,
        createdAt: DateTime(2026, 3, 20),
      );
      final rolled = StatementRollover.apply(
        c,
        unbilledSinceClosing: 0,
        now: DateTime(2026, 3, 25), // son kesim 15 Mart, karttan önce
      )!;
      expect(rolled.statementBalance, 1500,
          reason: 'kullanıcının girdiği korunur');
      expect(rolled.minimumPayment, 300);
      expect(rolled.statementClosedAt, DateTime(2026, 3, 15));
    });

    test('ödeme borcu düşürdüyse ekstre negatife inmez', () {
      final c = card(used: 500, statement: 0);
      final rolled = StatementRollover.apply(c, unbilledSinceClosing: 900)!;
      expect(rolled.statementBalance, 0);
    });
  });

  group('Limit ve kullanım', () {
    test('limit aşımı gizlenmez', () {
      final c = card(limit: 10000, used: 12000);
      expect(c.isOverLimit, isTrue);
      expect(c.availableLimit, -2000);
      expect(c.rawUsagePercent, closeTo(1.2, 0.001));
      expect(c.usagePercent, 1.0, reason: 'gösterge çubuğu için kırpılır');
    });

    test('ekstreye girmemiş tutar toplam borçtan türetilir', () {
      expect(card(used: 8000, statement: 3000).unbilledAmount, 5000);
    });

    test('limit sıfırsa kullanım oranı sıfırdır — bölme hatası olmaz', () {
      expect(card(limit: 0, used: 100).usagePercent, 0.0);
    });
  });

  group('Çoklu kart kullanım oranı', () {
    // Skor ağırlıklı olmalı: küçük limitli dolu bir kart, büyük limitli boş
    // bir kartla eşit sayılmamalı.
    double utilization(List<CreditCardEntity> cards) {
      final limit = cards.fold(0.0, (s, c) => s + c.creditLimit);
      final used = cards.fold(0.0, (s, c) => s + c.usedAmount);
      return limit > 0 ? used / limit : 0.0;
    }

    test('büyük limitli boş kart oranı aşağı çeker', () {
      final cards = [
        card(limit: 100000, used: 0),
        card(limit: 1000, used: 900),
      ];
      expect(utilization(cards), closeTo(0.0089, 0.0001));

      // Eski hesap: kullanım oranlarının ağırlıksız ortalaması
      final naiveAverage =
          cards.fold(0.0, (s, c) => s + c.usagePercent) / cards.length;
      expect(naiveAverage, closeTo(0.45, 0.001),
          reason: 'eski yöntem %45 diyordu — gerçeğin 50 katı');
    });
  });
}
