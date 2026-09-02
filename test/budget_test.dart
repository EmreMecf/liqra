import 'package:flutter_test/flutter_test.dart';
import 'package:muhasebe/data/models/budget_model.dart';
import 'package:muhasebe/data/models/transaction_model.dart';
import 'package:muhasebe/features/ai_assistant/domain/assistant_context.dart';
import 'package:muhasebe/features/ai_assistant/domain/assistant_insight.dart';
import 'package:muhasebe/presentation/widgets/status_banners.dart';

/// Bütçe limiti özelliği. Uygulamada `notifyBudgetOverrun` yazılmıştı ve
/// profil ekranı "kategori limiti aşıldığında" diyordu, ama limit koyulacak
/// hiçbir yer yoktu — bu testler o boşluğun kapandığını kayda geçirir.
void main() {
  group('BudgetModel', () {
    test('limit ekleme ve kaldırma', () {
      var b = BudgetModel.empty;
      expect(b.isEmpty, isTrue);

      b = b.withLimit(TransactionCategory.market, 5000);
      expect(b.limitFor(TransactionCategory.market), 5000);
      expect(b.hasLimit(TransactionCategory.market), isTrue);

      // 0 veya null limiti kaldırır — "sınırsız" demektir
      b = b.withLimit(TransactionCategory.market, null);
      expect(b.limitFor(TransactionCategory.market), isNull);
      expect(b.isEmpty, isTrue);
    });

    test('sıfır limit kaydedilmez', () {
      final b = BudgetModel.empty.withLimit(TransactionCategory.yemeicme, 0);
      expect(b.isEmpty, isTrue);
    });

    test('toplam limit yalnızca tanımlı kategorileri sayar', () {
      final b = BudgetModel.empty
          .withLimit(TransactionCategory.market, 5000)
          .withLimit(TransactionCategory.yemeicme, 3000);
      expect(b.totalLimit, 8000);
    });

    test('Firestore anahtarları kanonik slug olarak okunur', () {
      // Eski kayıtta Türkçe etiket bulunabilir; slug'a çevrilmeli ki
      // kategori sözleşmesi bozulmasın.
      final b = BudgetModel.fromMap({
        'limits': {'Yeme-İçme': 3000, 'market': 5000}
      });
      expect(b.limitFor(TransactionCategory.yemeicme), 3000);
      expect(b.limitFor(TransactionCategory.market), 5000);
    });

    test('bozuk veri çökertmez', () {
      expect(BudgetModel.fromMap(null).isEmpty, isTrue);
      expect(BudgetModel.fromMap({}).isEmpty, isTrue);
      expect(BudgetModel.fromMap({'limits': 'saçma'}).isEmpty, isTrue);
    });

    test('yazma ve okuma simetrik', () {
      final b = BudgetModel.empty.withLimit(TransactionCategory.ulasim, 1500);
      expect(BudgetModel.fromMap(b.toMap()).limits, b.limits);
    });
  });

  group('BudgetStatus', () {
    BudgetStatus status(double limit, double spent) => BudgetStatus(
          category: TransactionCategory.market,
          limit: limit,
          spent: spent,
        );

    test('limit içinde kalan harcama', () {
      final s = status(5000, 3000);
      expect(s.isOver, isFalse);
      expect(s.isNear, isFalse);
      expect(s.remaining, 2000);
      expect(s.ratio, closeTo(0.6, 0.001));
    });

    test('%80 ve üzeri "yaklaşıldı" sayılır', () {
      expect(status(5000, 4000).isNear, isTrue);
      expect(status(5000, 3900).isNear, isFalse);
    });

    test('aşım gizlenmez ama gösterge çubuğu kırpılır', () {
      final s = status(5000, 7500);
      expect(s.isOver, isTrue);
      expect(s.isNear, isFalse, reason: 'aşılmışsa "yaklaşıldı" denmez');
      expect(s.overspend, 2500);
      expect(s.rawRatio, closeTo(1.5, 0.001));
      expect(s.ratio, 1.0);
    });

    test('limit sıfırsa bölme hatası olmaz', () {
      expect(status(0, 100).ratio, 0);
    });
  });

  group('Bütçe içgörüleri', () {
    AssistantContext ctx(List<BudgetLine> budgets) => AssistantContext(
          now: DateTime(2026, 3, 15),
          spending: SpendingSnapshot(
            income: 40000,
            expenses: 20000,
            budgets: budgets,
          ),
        );

    test('aşılan bütçe bildirilir', () {
      final insights = InsightEngine.analyze(ctx([
        const BudgetLine(category: 'Market', limit: 5000, spent: 6200),
      ]));
      final over = insights.firstWhere((i) => i.id == 'budget_over_Market');
      expect(over.severity, InsightSeverity.warning);
      expect(over.notify, isTrue);
      expect(over.body, contains('1.200'));
      expect(over.route, '/spending');
    });

    test('limite yaklaşınca uyarı verir ama bildirim göndermez', () {
      final insights = InsightEngine.analyze(ctx([
        const BudgetLine(category: 'Yeme-İçme', limit: 5000, spent: 4200),
      ]));
      final near =
          insights.firstWhere((i) => i.id == 'budget_near_Yeme-İçme');
      expect(near.notify, isFalse, reason: 'henüz aşılmadı, rahatsız etme');
      expect(near.title, contains('%84'));
    });

    test('limit içindeki kategori hiç uyarı üretmez', () {
      final insights = InsightEngine.analyze(ctx([
        const BudgetLine(category: 'Market', limit: 5000, spent: 1000),
      ]));
      expect(insights.map((i) => i.id).where((id) => id.startsWith('budget_')),
          isEmpty);
    });

    test('limit koymayan kullanıcı bütçeden hiç söz duymaz', () {
      final insights = InsightEngine.analyze(ctx(const []));
      expect(insights.map((i) => i.id).where((id) => id.startsWith('budget_')),
          isEmpty);
    });

    test('bütçe satırları prompt bloğuna girer', () {
      final block = ctx([
        const BudgetLine(category: 'Market', limit: 5000, spent: 6200),
      ]).toPromptBlock();
      expect(block, contains('Aylık bütçe limitleri'));
      expect(block, contains('AŞILDI'));
      expect(block, contains('6.200 ₺ / 5.000 ₺'));
    });
  });

  group('Bayat veri eşiği', () {
    // Piyasa verisi 2 dakikada bir güncelleniyor; 30 dakika sessizlik
    // bağlantı sorununa işaret eder.
    bool isStale(Duration age) => age >= StaleDataBanner.staleAfter;

    test('taze veri için band gösterilmez', () {
      expect(isStale(const Duration(minutes: 5)), isFalse);
      expect(isStale(const Duration(minutes: 29)), isFalse);
    });

    test('30 dakika ve üzeri bayat sayılır', () {
      expect(isStale(const Duration(minutes: 30)), isTrue);
      expect(isStale(const Duration(hours: 6)), isTrue);
    });
  });
}
