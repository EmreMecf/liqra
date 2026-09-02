import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../data/models/recurring_item_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/providers/app_provider.dart';
import '../../accounts/domain/entities/financial_account_entity.dart';
import '../../accounts/presentation/viewmodels/accounts_viewmodel.dart';
import '../../campaigns/presentation/viewmodel/campaign_viewmodel.dart';
import '../../news/presentation/viewmodel/news_viewmodel.dart';
import '../../portfolio/presentation/viewmodel/market_viewmodel.dart';
import '../../portfolio/presentation/viewmodel/portfolio_state.dart';
import '../../portfolio/presentation/viewmodel/portfolio_viewmodel.dart';
import '../domain/assistant_context.dart';

/// Uygulamanın dağınık durumunu tek bir [AssistantContext]'e toplar.
///
/// ── Neden burada ────────────────────────────────────────────────────────────
/// Asistanın "her yerde yardımcı" olabilmesi için cüzdanı, harcamayı,
/// portföyü, piyasayı, haberleri ve kampanyaları AYNI ANDA görmesi gerekir.
/// Bu bilgiler altı ayrı ViewModel'de duruyor; onları domain katmanına
/// sızdırmadan birleştirmenin yeri presentation katmanıdır.
///
/// Hiçbir ViewModel'i yüklemeye zorlamaz — yüklenmemiş olan bölüm bağlamda
/// boş kalır, asistan da "bu veri yok" der.
class AssistantContextBuilder {
  const AssistantContextBuilder._();

  /// Widget ağacındaki sağlayıcılardan bağlamı kurar.
  static AssistantContext fromContext(BuildContext context) {
    final app = context.read<AppProvider>();
    final accounts = _tryRead<AccountsViewModel>(context);
    final portfolio = _tryRead<PortfolioViewModel>(context);
    final market = _tryRead<MarketViewModel>(context);
    final news = _tryRead<NewsViewModel>(context);
    final campaigns = _tryRead<CampaignViewModel>(context);

    return build(
      app: app,
      accounts: accounts,
      portfolio: portfolio,
      market: market,
      news: news,
      campaigns: campaigns,
    );
  }

  static AssistantContext build({
    required AppProvider app,
    AccountsViewModel? accounts,
    PortfolioViewModel? portfolio,
    MarketViewModel? market,
    NewsViewModel? news,
    CampaignViewModel? campaigns,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();

    return AssistantContext(
      userName: app.user.name,
      riskProfile: app.user.riskLabel,
      now: today,
      cash: _cash(accounts),
      cardDues: _cardDues(accounts),
      spending: _spending(app, today),
      portfolio: _portfolio(portfolio, market),
      goal: _goal(app),
      market: _market(market, portfolio),
      news: _news(news),
      campaigns: _campaigns(campaigns),
    );
  }

  /// Kullanıcının banka/kartlarının banka adları — kampanya eşleştirmesi için.
  static Set<String> userBanks(AccountsViewModel? accounts) {
    if (accounts == null) return const {};
    return {
      ...accounts.bankAccounts.map((a) => a.bank.displayName),
      ...accounts.creditCards.map((c) => c.bank.displayName),
    };
  }

  // ── Parçalar ───────────────────────────────────────────────────────────────

  static CashSnapshot _cash(AccountsViewModel? vm) {
    if (vm == null) return const CashSnapshot();
    final activeLoans = vm.loans.where((l) => l.status == 'active');
    return CashSnapshot(
      bankBalance: vm.totalBankBalance,
      cardDebt: vm.totalCreditUsed,
      statementDebt: vm.totalStatementDebt,
      unbilled: vm.totalUnbilled,
      creditLimit: vm.totalCreditLimit,
      loanRemaining: activeLoans.fold(0.0, (a, l) => a + l.remainingAmount),
      loanMonthly: activeLoans.fold(0.0, (a, l) => a + l.monthlyPayment),
    );
  }

  static List<CardDue> _cardDues(AccountsViewModel? vm) {
    if (vm == null) return const [];
    return vm.creditCards
        .where((c) => c.statementBalance > 0)
        .map((c) => CardDue(
              name: c.name,
              statementBalance: c.statementBalance,
              minimumPayment: c.minimumPayment,
              dueDate: c.isOverdue ? c.cycle.currentDueDate : c.nextPaymentDueDate,
              daysUntilDue: c.daysUntilDue,
              isOverdue: c.isOverdue,
              daysPastDue: c.daysPastDue,
            ))
        .toList()
      ..sort((a, b) {
        if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
        return a.daysUntilDue.compareTo(b.daysUntilDue);
      });
  }

  static SpendingSnapshot _spending(AppProvider app, DateTime today) {
    final previous = DateTime(today.year, today.month - 1);

    Map<String, double> labelled(int year, int month) => {
          for (final e in app.expensesByCategoryForMonth(year, month).entries)
            e.key.label: e.value,
        };

    final subs = app.recurringItems.where(
      (r) => r.isActive && r.type == 'expense',
    );

    return SpendingSnapshot(
      income: app.incomeForMonth(today.year, today.month),
      expenses: app.expensesForMonth(today.year, today.month),
      invested: app.investedForMonth(today.year, today.month),
      byCategory: labelled(today.year, today.month),
      previousByCategory: labelled(previous.year, previous.month),
      subscriptionBurden: subs.fold(0.0, (a, r) => a + _monthlyAmount(r)),
      subscriptionCount: subs.length,
      upcomingCharges: _upcomingCharges(subs, today),
      budgets: app
          .budgetStatusForMonth(today.year, today.month)
          .map((b) => BudgetLine(
                category: b.category.label,
                limit: b.limit,
                spent: b.spent,
              ))
          .toList(),
    );
  }

  /// Önümüzdeki 7 gün içinde yenilenecek abonelikler, tarihe göre sıralı.
  static List<UpcomingCharge> _upcomingCharges(
      Iterable<RecurringItemModel> subs, DateTime today) {
    final limit = today.add(const Duration(days: 7));
    final list = subs
        .where((r) =>
            !r.nextDueDate.isBefore(DateTime(today.year, today.month, today.day)) &&
            r.nextDueDate.isBefore(limit))
        .map((r) => UpcomingCharge(
              label: r.label,
              amount: r.amount,
              dueDate: r.nextDueDate,
            ))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  /// Farklı frekanstaki sabit kalemleri aylık karşılığına çevirir.
  static double _monthlyAmount(RecurringItemModel item) => switch (item.frequency) {
        'annual' => item.amount / 12,
        'weekly' => item.amount * 52 / 12,
        _ => item.amount,
      };

  static PortfolioSnapshot _portfolio(
    PortfolioViewModel? vm,
    MarketViewModel? market,
  ) {
    if (vm == null) return const PortfolioSnapshot();

    final quotes = _quoteIndex(market);

    return PortfolioSnapshot(
      holdings: vm.assets
          .map((a) => HoldingSnapshot(
                name: a.name,
                type: _typeLabel(a.type),
                quantity: a.quantity,
                buyPrice: a.buyPrice,
                currentPrice: a.currentPrice,
                dayChangePercent: quotes[a.name.toUpperCase()]?.changePercent ??
                    quotes[(a.priceKey ?? '').toUpperCase()]?.changePercent,
              ))
          .toList(),
    );
  }

  static String _typeLabel(String type) => switch (type.toLowerCase()) {
        'stock' || 'hisse' => 'Hisse',
        'crypto' || 'kripto' => 'Kripto',
        'gold' || 'altin' || 'altın' => 'Altın',
        'fund' || 'fon' => 'Fon',
        'currency' || 'doviz' || 'döviz' => 'Döviz',
        _ => type,
      };

  /// Piyasa verisini sembole göre indeksler.
  static Map<String, MarketQuote> _quoteIndex(MarketViewModel? vm) {
    final state = vm?.state;
    if (state is! MarketLoaded) return const {};
    return {
      for (final d in state.data)
        d.symbol.toUpperCase(): MarketQuote(
          symbol: d.symbol,
          name: d.name,
          price: d.price,
          changePercent: d.changePercent,
          dayLow: d.dayLow,
          dayHigh: d.dayHigh,
          volume: d.volume,
        ),
    };
  }

  /// Bağlama giren piyasa satırları: kullanıcının tuttuğu varlıklar önce,
  /// ardından ana göstergeler. Tüm piyasayı göndermek token israfı olur.
  static List<MarketQuote> _market(
    MarketViewModel? market,
    PortfolioViewModel? portfolio,
  ) {
    final index = _quoteIndex(market);
    if (index.isEmpty) return const [];

    final held = <MarketQuote>[];
    final heldKeys = <String>{};
    for (final a in portfolio?.assets ?? const []) {
      final q = index[a.name.toUpperCase()] ??
          index[(a.priceKey ?? '').toUpperCase()];
      if (q != null && heldKeys.add(q.symbol)) held.add(q);
    }

    // Ana göstergeler — portföyde olmasa da makro yorum için gerekli
    const benchmarks = ['USDTRY', 'EURTRY', 'XAUUSD', 'GRAM', 'BTC', 'XU100'];
    final extra = index.entries
        .where((e) =>
            !heldKeys.contains(e.value.symbol) &&
            benchmarks.any((b) => e.key.contains(b)))
        .map((e) => e.value);

    return [...held, ...extra];
  }

  static GoalSnapshot? _goal(AppProvider app) {
    final g = app.primaryGoal;
    if (g == null) return null;
    return GoalSnapshot(
      title: g.title,
      target: g.targetAmount,
      current: g.currentAmount,
      deadline: g.deadline,
    );
  }

  static List<NewsHeadline> _news(NewsViewModel? vm) {
    if (vm == null) return const [];
    return vm.allNews
        .take(25)
        .map((n) => NewsHeadline(
              title: n.title,
              source: n.source,
              category: n.category.label,
              date: n.pubDate,
            ))
        .toList();
  }

  static List<CampaignOffer> _campaigns(CampaignViewModel? vm) {
    if (vm == null) return const [];
    return vm.allCampaigns
        .map((c) => CampaignOffer(
              id: c.id,
              bank: c.bank,
              title: c.title,
              description: c.description,
              category: c.category.name,
              endDate: c.endDate,
              isSample: c.isSample,
            ))
        .toList();
  }

  /// Sağlayıcı ağaçta yoksa null döner — asistan o bölümü boş görür.
  static T? _tryRead<T>(BuildContext context) {
    try {
      return Provider.of<T>(context, listen: false);
    } catch (_) {
      return null;
    }
  }
}

/// [TransactionModel] listesi elde varken bağlam kurmak için kısayol —
/// arka plan işlerinde (bildirim üretimi) ViewModel bulunmaz.
extension AssistantContextTransactions on List<TransactionModel> {
  double sumWhere(bool Function(TransactionModel) test) =>
      where(test).fold(0.0, (a, t) => a + t.amount);
}
