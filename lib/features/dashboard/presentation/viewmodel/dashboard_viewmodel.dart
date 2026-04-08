import 'package:flutter/foundation.dart';
import '../../../../core/services/auth_service.dart';
import '../../../spending/domain/usecases/get_transactions_usecase.dart';
import '../../../portfolio/domain/usecases/get_portfolio_usecase.dart';
import '../../../spending/domain/entities/transaction_entity.dart';
import '../../../portfolio/domain/entities/asset_entity.dart';

sealed class DashboardState {
  const DashboardState();
}
class DashboardInitial extends DashboardState { const DashboardInitial(); }
class DashboardLoading extends DashboardState { const DashboardLoading(); }
class DashboardLoaded extends DashboardState {
  final List<TransactionEntity> recentTransactions;
  final PortfolioEntity portfolio;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double prevMonthIncome;
  final double prevMonthExpenses;
  final Map<String, double> expensesByCategory;
  final bool hasAiWarning;
  final String? aiWarningMessage;
  const DashboardLoaded({
    required this.recentTransactions,
    required this.portfolio,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    this.prevMonthIncome = 0,
    this.prevMonthExpenses = 0,
    this.expensesByCategory = const {},
    this.hasAiWarning = false,
    this.aiWarningMessage,
  });
  double get netCash => monthlyIncome - monthlyExpenses;

  /// Geçen aya göre net nakit değişim yüzdesi
  double get prevMonthDelta {
    final prevNet  = prevMonthIncome - prevMonthExpenses;
    final currNet  = netCash;
    if (prevNet == 0) return 0;
    return ((currNet - prevNet) / prevNet.abs()) * 100;
  }
}
class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
}

/// Dashboard ViewModel — birden fazla feature'ı birleştirir
class DashboardViewModel extends ChangeNotifier {
  final GetTransactionsUseCase _getTransactions;
  final GetPortfolioUseCase    _getPortfolio;

  DashboardViewModel({
    required GetTransactionsUseCase getTransactions,
    required GetPortfolioUseCase getPortfolio,
  })  : _getTransactions = getTransactions,
        _getPortfolio = getPortfolio;

  DashboardState _state = const DashboardInitial();
  DashboardState get state => _state;

  Future<void> load({double userMonthlyIncome = 0}) async {
    _state = const DashboardLoading();
    notifyListeners();

    final uid = AuthService.instance.userId ?? '';
    final now       = DateTime.now();
    final prevStart = DateTime(now.year, now.month - 1, 1);
    final prevEnd   = DateTime(now.year, now.month, 0);   // son günü

    final txResult   = await _getTransactions.currentMonth();
    final prevResult = await _getTransactions(from: prevStart, to: prevEnd);
    final portResult = await _getPortfolio(userId: uid);

    if (txResult.isFailure) {
      _state = DashboardError(txResult.failure.message);
      notifyListeners();
      return;
    }

    if (portResult.isFailure) {
      _state = DashboardError(portResult.failure.message);
      notifyListeners();
      return;
    }

    final transactions     = txResult.data;
    final prevTransactions = prevResult.isSuccess ? prevResult.data : <TransactionEntity>[];
    final portfolio        = portResult.data;

    double income = 0, expenses = 0;
    final Map<String, double> byCat = {};
    for (final tx in transactions) {
      if (tx.isIncome) {
        income += tx.amount;
      } else {
        expenses += tx.amount;
        byCat[tx.category] = (byCat[tx.category] ?? 0) + tx.amount;
      }
    }

    double prevIncome = 0, prevExpenses = 0;
    for (final tx in prevTransactions) {
      if (tx.isIncome) prevIncome += tx.amount;
      else prevExpenses += tx.amount;
    }

    // ── Uyarı tespiti ─────────────────────────────────────────────────────────
    String? warningMsg;

    // 1. Toplam harcama geliri aştı mı?
    final refIncome = userMonthlyIncome > 0 ? userMonthlyIncome : income;
    if (refIncome > 0 && expenses > refIncome) {
      final over = (expenses - refIncome).toStringAsFixed(0);
      warningMsg = 'Bu ay gelirinizden $over TL fazla harcadınız!';
    }

    // 2. Kategori bazlı bütçe aşımı (kullanıcının gelirinin yüzdesi)
    if (warningMsg == null && refIncome > 0) {
      final budgets = <String, double>{
        'yemeicme': refIncome * 0.20,
        'market':   refIncome * 0.25,
        'eglence':  refIncome * 0.08,
        'ulasim':   refIncome * 0.15,
        'fatura':   refIncome * 0.20,
      };
      for (final entry in budgets.entries) {
        final spent = byCat[entry.key] ?? 0;
        if (spent > 0 && spent > entry.value * 1.2) {
          final overAmount = (spent - entry.value).toStringAsFixed(0);
          warningMsg = 'Bu ay ${_categoryLabel(entry.key)} harcamanız $overAmount TL bütçeyi aştı.';
          break;
        }
      }
    }

    // 3. Gelir bilgisi yokken mutlak eşik kontrolü
    if (warningMsg == null && refIncome <= 0) {
      const fallback = <String, double>{'yemeicme': 3500, 'market': 3000, 'eglence': 800};
      for (final entry in fallback.entries) {
        final spent = byCat[entry.key] ?? 0;
        if (spent > entry.value * 1.2) {
          final overAmount = (spent - entry.value).toStringAsFixed(0);
          warningMsg = 'Bu ay ${_categoryLabel(entry.key)} harcamanız $overAmount TL bütçeyi aştı.';
          break;
        }
      }
    }

    _state = DashboardLoaded(
      recentTransactions: transactions.take(5).toList(),
      portfolio:          portfolio,
      monthlyIncome:      income,
      monthlyExpenses:    expenses,
      prevMonthIncome:    prevIncome,
      prevMonthExpenses:  prevExpenses,
      expensesByCategory: byCat,
      hasAiWarning:       warningMsg != null,
      aiWarningMessage:   warningMsg,
    );
    notifyListeners();
  }

  String _categoryLabel(String cat) => switch (cat) {
    'yemeicme'  => 'yeme-içme',
    'market'    => 'market',
    'eglence'   => 'eğlence',
    'ulasim'    => 'ulaşım',
    'fatura'    => 'fatura',
    'saglik'    => 'sağlık',
    'giyim'     => 'giyim',
    'egitim'    => 'eğitim',
    'teknoloji' => 'teknoloji',
    _           => cat,
  };
}
