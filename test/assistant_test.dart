import 'package:flutter_test/flutter_test.dart';
import 'package:muhasebe/features/ai_assistant/domain/assistant_context.dart';
import 'package:muhasebe/features/ai_assistant/domain/assistant_insight.dart';
import 'package:muhasebe/features/ai_assistant/domain/campaign_matcher.dart';
import 'package:muhasebe/features/ai_assistant/domain/savings_plan.dart';

/// Asistanın **tespit** katmanı test edilir. Modelin *yorumu* test edilemez
/// ama hangi rakamı gördüğü ve neyi uyarı saydığı edilebilir — kullanıcı bu
/// rakamlara göre para harcadığı için asıl kritik kısım burasıdır.
void main() {
  final now = DateTime(2026, 3, 15);

  AssistantContext ctx({
    CashSnapshot cash = const CashSnapshot(),
    List<CardDue> cards = const [],
    SpendingSnapshot spending = const SpendingSnapshot(),
    PortfolioSnapshot portfolio = const PortfolioSnapshot(),
    GoalSnapshot? goal,
    List<CampaignOffer> campaigns = const [],
  }) =>
      AssistantContext(
        now: now,
        cash: cash,
        cardDues: cards,
        spending: spending,
        portfolio: portfolio,
        goal: goal,
        campaigns: campaigns,
      );

  List<String> idsOf(List<AssistantInsight> list) =>
      list.map((i) => i.id).toList();

  group('Serbest nakit', () {
    test('yaklaşan ekstre banka bakiyesinden düşülür', () {
      // Asistan "20.000 ₺ yatırım yapabilirsin" dememeli — 12.000'i ekstreye
      // gidecek.
      final c = ctx(
        cash: const CashSnapshot(bankBalance: 20000, statementDebt: 12000),
      );
      expect(c.freeCash, 8000);
    });

    test('ekstre bakiyeden büyükse serbest nakit negatife inmez', () {
      final c = ctx(
        cash: const CashSnapshot(bankBalance: 3000, statementDebt: 9000),
      );
      expect(c.freeCash, 0);
    });
  });

  group('Net servet ve kullanım', () {
    test('kredi kalanı da net servetten düşülür', () {
      final c = ctx(
        cash: const CashSnapshot(
          bankBalance: 50000,
          cardDebt: 12000,
          loanRemaining: 80000,
        ),
      );
      expect(c.cash.netWorth, -42000);
    });

    test('kullanım oranı toplam borç / toplam limit', () {
      final c = ctx(
        cash: const CashSnapshot(cardDebt: 9000, creditLimit: 30000),
      );
      expect(c.cash.utilization, closeTo(0.3, 0.0001));
    });
  });

  group('İçgörü: kart', () {
    test('gecikmiş kart en yüksek öncelikle gelir ve bildirilir', () {
      final insights = InsightEngine.analyze(ctx(cards: [
        CardDue(
          name: 'Bonus',
          statementBalance: 4500,
          minimumPayment: 900,
          dueDate: DateTime(2026, 3, 5),
          daysUntilDue: 21,
          isOverdue: true,
          daysPastDue: 10,
        ),
      ]));

      final overdue = insights.first;
      expect(overdue.id, 'card_overdue_Bonus');
      expect(overdue.severity, InsightSeverity.critical);
      expect(overdue.notify, isTrue);
      expect(overdue.title, contains('10 gün'));
    });

    test('bugün son gün olan kart uyarı verir', () {
      final insights = InsightEngine.analyze(ctx(cards: [
        CardDue(
          name: 'Maximum',
          statementBalance: 2000,
          minimumPayment: 400,
          dueDate: now,
          daysUntilDue: 0,
          isOverdue: false,
          daysPastDue: 0,
        ),
      ]));
      final due = insights.firstWhere((i) => i.id == 'card_due_Maximum');
      expect(due.title, contains('bugün son gün'));
      expect(due.notify, isTrue);
    });

    test('ödeme gücü yetmiyorsa ayrı bir kritik uyarı çıkar', () {
      final insights = InsightEngine.analyze(ctx(
        cash: const CashSnapshot(bankBalance: 1000),
        cards: [
          CardDue(
            name: 'Bonus',
            statementBalance: 5000,
            minimumPayment: 1000,
            dueDate: DateTime(2026, 3, 18),
            daysUntilDue: 3,
            isOverdue: false,
            daysPastDue: 0,
          ),
        ],
      ));
      final short = insights.firstWhere((i) => i.id == 'cash_short');
      expect(short.severity, InsightSeverity.critical);
      expect(short.body, contains('4.000'));
    });

    test('borcu olmayan kart hiç uyarı üretmez', () {
      final insights = InsightEngine.analyze(ctx(cards: const []));
      expect(idsOf(insights).where((id) => id.startsWith('card_')), isEmpty);
    });
  });

  group('İçgörü: harcama', () {
    test('gelirden fazla harcama kritik sayılır', () {
      final insights = InsightEngine.analyze(ctx(
        spending: const SpendingSnapshot(income: 40000, expenses: 47000),
      ));
      final over = insights.firstWhere((i) => i.id == 'overspend_month');
      expect(over.severity, InsightSeverity.critical);
      expect(over.body, contains('7.000'));
    });

    test('kategori sıçraması eşiği geçince uyarı verir', () {
      final insights = InsightEngine.analyze(ctx(
        spending: const SpendingSnapshot(
          income: 50000,
          expenses: 30000,
          byCategory: {'Yeme-İçme': 6000},
          previousByCategory: {'Yeme-İçme': 3000},
        ),
      ));
      final jump = insights.firstWhere((i) => i.id == 'category_jump_Yeme-İçme');
      expect(jump.title, contains('%100'));
    });

    test('küçük artış uyarı üretmez', () {
      // 3.000 → 3.200: hem oran hem tutar eşiğin altında
      final insights = InsightEngine.analyze(ctx(
        spending: const SpendingSnapshot(
          income: 50000,
          expenses: 30000,
          byCategory: {'Market': 3200},
          previousByCategory: {'Market': 3000},
        ),
      ));
      expect(idsOf(insights), isNot(contains('category_jump_Market')));
    });

    test('abonelik yükü gelirin %15\'ini aşınca uyarır', () {
      final insights = InsightEngine.analyze(ctx(
        spending: const SpendingSnapshot(
          income: 20000,
          expenses: 15000,
          subscriptionBurden: 3500,
          subscriptionCount: 9,
        ),
      ));
      final sub = insights.firstWhere((i) => i.id == 'subscription_burden');
      expect(sub.body, contains('42.000'), reason: 'yıllık karşılığı');
    });

    test('iyi giden ay da söylenir — asistan sadece kötü haber vermez', () {
      final insights = InsightEngine.analyze(ctx(
        spending: const SpendingSnapshot(income: 50000, expenses: 35000),
      ));
      expect(idsOf(insights), contains('savings_good'));
    });
  });

  group('İçgörü: portföy', () {
    test('tek varlık %40 üstündeyse yoğunlaşma uyarısı verir', () {
      final insights = InsightEngine.analyze(ctx(
        portfolio: const PortfolioSnapshot(holdings: [
          HoldingSnapshot(
              name: 'THYAO',
              type: 'Hisse',
              quantity: 100,
              buyPrice: 250,
              currentPrice: 300),
          HoldingSnapshot(
              name: 'Gram Altın',
              type: 'Altın',
              quantity: 10,
              buyPrice: 2000,
              currentPrice: 2200),
        ]),
      ));
      // THYAO 30.000, altın 22.000 → %57
      final conc = insights.firstWhere((i) => i.id == 'concentration_THYAO');
      expect(conc.title, contains('%58'));
    });

    test('dengeli portföyde yoğunlaşma uyarısı çıkmaz', () {
      final insights = InsightEngine.analyze(ctx(
        portfolio: const PortfolioSnapshot(holdings: [
          HoldingSnapshot(
              name: 'A', type: 'Hisse', quantity: 1, buyPrice: 100, currentPrice: 100),
          HoldingSnapshot(
              name: 'B', type: 'Fon', quantity: 1, buyPrice: 100, currentPrice: 100),
          HoldingSnapshot(
              name: 'C', type: 'Altın', quantity: 1, buyPrice: 100, currentPrice: 100),
        ]),
      ));
      expect(idsOf(insights).where((id) => id.startsWith('concentration_')),
          isEmpty);
    });

    test('sert günlük hareket bildirime dönüşür', () {
      final insights = InsightEngine.analyze(ctx(
        portfolio: const PortfolioSnapshot(holdings: [
          HoldingSnapshot(
            name: 'ASELS',
            type: 'Hisse',
            quantity: 10,
            buyPrice: 50,
            currentPrice: 60,
            dayChangePercent: -9.4,
          ),
        ]),
      ));
      final move = insights.firstWhere((i) => i.id == 'move_ASELS');
      expect(move.notify, isTrue, reason: '%8 üstü hareket bildirilir');
    });
  });

  group('İçgörü: fırsat', () {
    test('acil fon yoksa yatırım değil tampon önerilir', () {
      final insights = InsightEngine.analyze(ctx(
        cash: const CashSnapshot(bankBalance: 3000),
        spending: const SpendingSnapshot(income: 30000, expenses: 20000),
      ));
      expect(idsOf(insights), contains('no_emergency_fund'));
      expect(idsOf(insights), isNot(contains('idle_cash')));
    });

    test('3 aylık giderin çok üstünde nakit atıl sayılır', () {
      final insights = InsightEngine.analyze(ctx(
        cash: const CashSnapshot(bankBalance: 200000),
        spending: const SpendingSnapshot(income: 30000, expenses: 20000),
      ));
      final idle = insights.firstWhere((i) => i.id == 'idle_cash');
      expect(idle.severity, InsightSeverity.opportunity);
      // 200.000 − 60.000 (3 aylık tampon)
      expect(idle.title, contains('140.000'));
    });
  });

  group('Kampanya eşleştirme', () {
    const marketCampaign = CampaignOffer(
      id: 'c1',
      bank: 'Garanti BBVA',
      title: 'Markette %10 indirim',
      description: '',
      category: 'market',
    );
    const travelCampaign = CampaignOffer(
      id: 'c2',
      bank: 'Akbank',
      title: 'Uçak biletinde taksit',
      description: '',
      category: 'seyahat',
    );

    test('harcadığın kategorinin kampanyası öne çıkar', () {
      final matches = CampaignMatcher.match(
        ctx(
          spending: const SpendingSnapshot(
            income: 40000,
            expenses: 20000,
            byCategory: {'Market': 6000, 'Yeme-İçme': 1200},
          ),
          campaigns: [marketCampaign, travelCampaign],
        ),
        userBanks: {'Garanti BBVA'},
      );

      expect(matches.first.offer.id, 'c1');
      expect(matches.first.hasBankCard, isTrue);
      expect(matches.first.monthlySpend, 6000);
      expect(matches.first.reason, contains('Garanti BBVA kartın zaten var'));
    });

    test('hiç harcamadığın kategori elenir', () {
      final matches = CampaignMatcher.match(
        ctx(
          spending: const SpendingSnapshot(
            income: 40000,
            expenses: 20000,
            byCategory: {'Market': 6000},
          ),
          campaigns: [travelCampaign],
        ),
      );
      expect(matches, isEmpty);
    });

    test('kartı olmayan banka yine önerilir ama daha düşük puanla', () {
      final withCard = CampaignMatcher.match(
        ctx(
          spending: const SpendingSnapshot(
            income: 40000,
            expenses: 20000,
            byCategory: {'Market': 6000},
          ),
          campaigns: [marketCampaign],
        ),
        userBanks: {'Garanti BBVA'},
      ).first;

      final withoutCard = CampaignMatcher.match(
        ctx(
          spending: const SpendingSnapshot(
            income: 40000,
            expenses: 20000,
            byCategory: {'Market': 6000},
          ),
          campaigns: [marketCampaign],
        ),
      ).first;

      expect(withCard.score, greaterThan(withoutCard.score));
    });

    test('güçlü eşleşme bildirime dönüşür', () {
      final insights = CampaignMatcher.toInsights(
        CampaignMatcher.match(
          ctx(
            spending: const SpendingSnapshot(
              income: 40000,
              expenses: 20000,
              byCategory: {'Market': 6000},
            ),
            campaigns: [marketCampaign],
          ),
          userBanks: {'Garanti BBVA'},
        ),
      );
      expect(insights, hasLength(1));
      expect(insights.first.notify, isTrue);
      expect(insights.first.body, contains('çünkü'));
    });
  });

  group('Birikim planı', () {
    test('yetişen hedef rahat sayılır, kısıntı önerilmez', () {
      final plan = SavingsPlanBuilder.build(
        ctx: ctx(
          spending: const SpendingSnapshot(income: 50000, expenses: 30000),
        ),
        goalTitle: 'Tatil',
        targetAmount: 60000,
        currentAmount: 0,
        deadline: DateTime(2026, 9, 15),
      );

      expect(plan.monthsLeft, 6);
      expect(plan.requiredMonthly, 10000);
      expect(plan.currentMonthly, 20000);
      expect(plan.gap, 0);
      expect(plan.feasibility, PlanFeasibility.comfortable);
      expect(plan.cuts, isEmpty);
    });

    test('açık varsa esnek kalemlerden kısıntı önerilir', () {
      final plan = SavingsPlanBuilder.build(
        ctx: ctx(
          spending: const SpendingSnapshot(
            income: 40000,
            expenses: 37000,
            byCategory: {
              'Kira': 15000,
              'Yeme-İçme': 8000,
              'Eğlence': 4000,
              'Market': 6000,
            },
          ),
        ),
        goalTitle: 'Ev peşinatı',
        targetAmount: 60000,
        currentAmount: 0,
        deadline: DateTime(2026, 9, 15),
      );

      expect(plan.requiredMonthly, 10000);
      expect(plan.currentMonthly, 3000);
      expect(plan.gap, 7000);

      // Kira ZORUNLU — asistan kirayı kısmayı önermemeli
      expect(plan.cuts.map((c) => c.category), isNot(contains('Kira')));
      expect(plan.cuts.map((c) => c.category), contains('Yeme-İçme'));
    });

    test('kısıntı açığı kapatamıyorsa plan gerçekçi değil denir', () {
      final plan = SavingsPlanBuilder.build(
        ctx: ctx(
          spending: const SpendingSnapshot(
            income: 20000,
            expenses: 19000,
            byCategory: {'Kira': 12000, 'Market': 5000, 'Ulaşım': 2000},
          ),
        ),
        goalTitle: 'Araba',
        targetAmount: 300000,
        currentAmount: 0,
        deadline: DateTime(2026, 9, 15),
      );

      expect(plan.feasibility, PlanFeasibility.unrealistic);
      expect(plan.residualGap, greaterThan(0));
      // Gerçekçi tarih hesaplanmış olmalı
      expect(plan.projectedDate, isNotNull);
    });

    test('gereğinden fazla kısıntı önerilmez', () {
      final plan = SavingsPlanBuilder.build(
        ctx: ctx(
          spending: const SpendingSnapshot(
            income: 40000,
            expenses: 30000,
            byCategory: {'Yeme-İçme': 10000, 'Eğlence': 6000},
          ),
        ),
        goalTitle: 'Kısa hedef',
        targetAmount: 66000,
        currentAmount: 0,
        deadline: DateTime(2026, 9, 15),
      );

      // Gereken 11.000, mevcut 10.000 → açık yalnızca 1.000
      expect(plan.gap, 1000);
      expect(plan.totalCuts, closeTo(1000, 0.01),
          reason: 'açık kadar kısıntı, fazlası değil');
    });

    test('süresi dolmuş hedefte kalan tutar tek seferde istenir', () {
      final plan = SavingsPlanBuilder.build(
        ctx: ctx(spending: const SpendingSnapshot(income: 30000, expenses: 25000)),
        goalTitle: 'Geçmiş hedef',
        targetAmount: 10000,
        currentAmount: 4000,
        deadline: DateTime(2026, 1, 1),
      );
      expect(plan.monthsLeft, 0);
      expect(plan.requiredMonthly, 6000);
    });
  });

  group('Prompt bloğu', () {
    test('bağlam bloğu kullanıcının kendi rakamlarını taşır', () {
      final block = ctx(
        cash: const CashSnapshot(
          bankBalance: 25000,
          cardDebt: 8000,
          statementDebt: 5000,
          unbilled: 3000,
          creditLimit: 40000,
        ),
        spending: const SpendingSnapshot(
          income: 45000,
          expenses: 28000,
          byCategory: {'Market': 6000},
          previousByCategory: {'Market': 4000},
        ),
      ).toPromptBlock();

      expect(block, contains('25.000 ₺'));
      expect(block, contains('ekstre dışı 3.000 ₺'));
      expect(block, contains('Serbest nakit'));
      expect(block, contains('geçen aya göre +2.000 ₺'));
      expect(block, contains('Tasarruf oranı: %38'));
    });

    test('boş portföy açıkça belirtilir — model uydurmasın', () {
      expect(ctx().toPromptBlock(), contains('Portföy boş.'));
    });
  });

  group('Abonelik hatırlatması', () {
    AssistantContext withCharges(
      List<UpcomingCharge> charges, {
      double bankBalance = 10000,
    }) =>
        AssistantContext(
          now: now,
          cash: CashSnapshot(bankBalance: bankBalance),
          spending: SpendingSnapshot(
            income: 40000,
            expenses: 25000,
            subscriptionCount: charges.length,
            upcomingCharges: charges,
          ),
        );

    test('3 gün içindeki yenileme bildirilir', () {
      final insights = InsightEngine.analyze(withCharges([
        UpcomingCharge(
            label: 'Spotify', amount: 150, dueDate: DateTime(2026, 3, 17)),
      ]));
      final sub = insights.firstWhere((i) => i.id == 'sub_due_Spotify');
      expect(sub.title, contains('2 gün sonra'));
      expect(sub.notify, isTrue);
      expect(sub.route, '/subscriptions');
    });

    test('bugün yenilenen abonelik ayrı metin gösterir', () {
      final insights = InsightEngine.analyze(withCharges([
        UpcomingCharge(label: 'Netflix', amount: 300, dueDate: now),
      ]));
      expect(insights.firstWhere((i) => i.id == 'sub_due_Netflix').title,
          contains('bugün yenileniyor'));
    });

    test('bakiye yetmiyorsa uyarı seviyesine çıkar', () {
      final insights = InsightEngine.analyze(withCharges(
        [UpcomingCharge(label: 'iCloud', amount: 500, dueDate: now)],
        bankBalance: 200,
      ));
      final sub = insights.firstWhere((i) => i.id == 'sub_due_iCloud');
      expect(sub.severity, InsightSeverity.warning);
      expect(sub.body, contains('banka bakiyen'));
    });

    test('uzaktaki yenileme rahatsız etmez', () {
      final insights = InsightEngine.analyze(withCharges([
        UpcomingCharge(
            label: 'YouTube', amount: 100, dueDate: DateTime(2026, 3, 25)),
      ]));
      expect(insights.map((i) => i.id), isNot(contains('sub_due_YouTube')));
    });

    test('yaklaşan çekimler prompt bloğunda görünür', () {
      final block = withCharges([
        UpcomingCharge(
            label: 'Spotify', amount: 150, dueDate: DateTime(2026, 3, 17)),
      ]).toPromptBlock();
      expect(block, contains('Yakında yenilenecekler'));
      expect(block, contains('Spotify'));
    });
  });
}
