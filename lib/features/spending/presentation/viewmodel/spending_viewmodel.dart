import 'package:flutter/foundation.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/usecases/add_transaction_usecase.dart';
import '../../domain/usecases/delete_transaction_usecase.dart';
import '../../domain/usecases/get_transactions_usecase.dart';
import '../../domain/usecases/get_monthly_summary_usecase.dart';
import 'spending_state.dart';

/// Harcama ekranı ViewModel
class SpendingViewModel extends ChangeNotifier {
  final GetTransactionsUseCase _getTransactions;
  final AddTransactionUseCase _addTransaction;
  final DeleteTransactionUseCase _deleteTransaction;
  final GetMonthlySummaryUseCase _getMonthlySummary;

  SpendingViewModel({
    required GetTransactionsUseCase getTransactions,
    required AddTransactionUseCase addTransaction,
    required DeleteTransactionUseCase deleteTransaction,
    required GetMonthlySummaryUseCase getMonthlySummary,
  })  : _getTransactions = getTransactions,
        _addTransaction = addTransaction,
        _deleteTransaction = deleteTransaction,
        _getMonthlySummary = getMonthlySummary;

  // ── State ─────────────────────────────────────────────────────────────────

  SpendingState _state = const SpendingState.initial();
  SpendingState get state => _state;

  String? _filterCategory;
  DateTime? _lastLoaded;

  // ── Veri Yükleme ─────────────────────────────────────────────────────────

  /// Auth sonrası cache'i sıfırlayarak yeniden yükler
  Future<void> reload() async {
    _lastLoaded = null;
    await loadCurrentMonth();
  }

  Future<void> loadCurrentMonth() async {
    // Cache: 60 saniye içinde zaten yüklendiyse tekrar sorgu yapma
    final now = DateTime.now();
    if (_lastLoaded != null &&
        now.difference(_lastLoaded!) < const Duration(seconds: 60) &&
        _state is SpendingLoaded) {
      return;
    }
    _state = const SpendingState.loading();
    notifyListeners();

    final txResult = await _getTransactions.currentMonth();
    final summaryResult = await _getMonthlySummary();

    txResult.when(
      success: (transactions) {
        summaryResult.when(
          success: (summary) {
            _state = SpendingState.loaded(
              transactions: transactions,
              summary: summary,
              filterCategory: _filterCategory,
            );
          },
          failure: (f) {
            _state = SpendingState.error(
              message: f.message,
              previousTransactions: transactions,
            );
          },
        );
      },
      failure: (f) {
        _state = SpendingState.error(message: f.message);
      },
    );

    _lastLoaded = DateTime.now();
    notifyListeners();
  }

  /// Belirli bir tarih aralığını yükler (örn. OCR import sonrası)
  Future<void> loadPeriod(DateTime from, DateTime to) async {
    _state = const SpendingState.loading();
    notifyListeners();

    final txResult = await _getTransactions(from: from, to: to);
    final now = DateTime.now();
    final summaryResult = await _getMonthlySummary(year: now.year, month: now.month);

    txResult.when(
      success: (transactions) {
        summaryResult.when(
          success: (summary) {
            _state = SpendingState.loaded(
              transactions: transactions,
              summary: summary,
              filterCategory: _filterCategory,
            );
          },
          failure: (_) {
            _state = SpendingState.loaded(
              transactions: transactions,
              summary: MonthlySummaryEntity(
                totalIncome: 0, totalExpenses: 0, netCash: 0,
                byCategory: {}, year: now.year, month: now.month,
              ),
              filterCategory: _filterCategory,
            );
          },
        );
      },
      failure: (f) {
        _state = SpendingState.error(message: f.message);
      },
    );

    notifyListeners();
  }

  // ── Filtre ────────────────────────────────────────────────────────────────

  void setFilter(String? category) {
    _filterCategory = category;
    if (_state is SpendingLoaded) {
      final s = _state as SpendingLoaded;
      _state = s.copyWith(filterCategory: category);
      notifyListeners();
    }
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  /// Başarıyla kaydedildiyse true, hata oluştuysa false döner.
  /// [reload] false olunca loadCurrentMonth çağrılmaz — toplu kayıtta kullan.
  Future<bool> addTransaction({
    required double amount,
    required String category,
    required String type,
    String source = 'manual',
    String? note,
    DateTime? date,
    bool reload = true,
  }) async {
    final result = await _addTransaction(
      amount: amount,
      category: category,
      type: type,
      source: source,
      note: note,
      date: date,
    );

    return result.when(
      success: (_) { if (reload) this.reload(); return true; },
      failure: (f) {
        _state = SpendingState.error(
          message: f.message,
          previousTransactions: _state.transactions,
        );
        notifyListeners();
        return false;
      },
    );
  }

  Future<void> deleteTransaction(String id) async {
    // Optimistic update — önce UI'dan kaldır
    if (_state is SpendingLoaded) {
      final s = _state as SpendingLoaded;
      final updated = s.transactions.where((t) => t.id != id).toList();
      _state = s.copyWith(transactions: updated);
      notifyListeners();
    }

    final result = await _deleteTransaction(id);
    result.onFailure((_) => loadCurrentMonth()); // hata varsa yenile
  }

  // ── Bağlam Özeti (AI için) ────────────────────────────────────────────────

  String buildTransactionsSummary() {
    if (_state is! SpendingLoaded) return 'Veri yükleniyor...';
    final s = _state as SpendingLoaded;
    final summary = s.summary;

    final topCategories = summary.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final categoryLines = topCategories.take(5).map((e) {
      return '${e.key}: ${e.value.toStringAsFixed(0)} TL';
    }).join(', ');

    return 'Gelir: ${summary.totalIncome.toStringAsFixed(0)} TL, '
        'Gider: ${summary.totalExpenses.toStringAsFixed(0)} TL, '
        'Net: ${summary.netCash.toStringAsFixed(0)} TL. '
        'Kategoriler: $categoryLines';
  }
}
