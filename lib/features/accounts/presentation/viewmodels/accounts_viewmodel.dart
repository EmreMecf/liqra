import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/result.dart';
import '../../data/datasources/loan_firestore_datasource.dart';
import '../../domain/entities/account_transaction_entity.dart';
import '../../domain/entities/financial_account_entity.dart';
import '../../domain/entities/loan_entity.dart';
import '../../domain/usecases/add_account_transaction_usecase.dart';
import '../../domain/usecases/add_account_usecase.dart';
import '../../domain/usecases/delete_account_usecase.dart';
import '../../domain/usecases/get_account_transactions_usecase.dart';
import '../../domain/usecases/get_accounts_usecase.dart';
import '../../domain/usecases/import_statement_usecase.dart';
import '../../domain/usecases/update_account_usecase.dart';
import '../../../spending/presentation/viewmodel/spending_viewmodel.dart';
import 'accounts_state.dart';

class AccountsViewModel extends ChangeNotifier {
  final GetAccountsUseCase _getAccounts;
  final AddAccountUseCase _addAccount;
  final DeleteAccountUseCase _deleteAccount;
  final UpdateAccountUseCase _updateAccount;
  final GetAccountTransactionsUseCase _getTransactions;
  final AddAccountTransactionUseCase _addTransaction;
  final ImportStatementUseCase _importStatement;
  final LoanFirestoreDataSource _loanDs = LoanFirestoreDataSource();

  AccountsState _state = const AccountsState.initial();
  AccountsState get state => _state;

  List<LoanEntity> _loans = [];
  List<LoanEntity> get loans => _loans;

  AccountsViewModel({
    required GetAccountsUseCase getAccounts,
    required AddAccountUseCase addAccount,
    required DeleteAccountUseCase deleteAccount,
    required UpdateAccountUseCase updateAccount,
    required GetAccountTransactionsUseCase getTransactions,
    required AddAccountTransactionUseCase addTransaction,
    required ImportStatementUseCase importStatement,
  })  : _getAccounts = getAccounts,
        _addAccount = addAccount,
        _deleteAccount = deleteAccount,
        _updateAccount = updateAccount,
        _getTransactions = getTransactions,
        _addTransaction = addTransaction,
        _importStatement = importStatement;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<FinancialAccountEntity> get accounts =>
      _state is AccountsLoaded ? (_state as AccountsLoaded).accounts : [];

  List<BankAccountEntity> get bankAccounts =>
      accounts.whereType<BankAccountEntity>().toList();

  List<CreditCardEntity> get creditCards =>
      accounts.whereType<CreditCardEntity>().toList();

  double get totalBankBalance =>
      bankAccounts.fold(0.0, (sum, a) => sum + a.balance);

  double get totalCreditUsed =>
      creditCards.fold(0.0, (sum, c) => sum + c.usedAmount);

  double get totalCreditLimit =>
      creditCards.fold(0.0, (sum, c) => sum + c.creditLimit);

  double get totalStatementDebt =>
      creditCards.fold(0.0, (sum, c) => sum + c.statementBalance);

  List<AccountTransactionEntity> transactionsFor(String accountId) {
    if (_state is AccountsLoaded) {
      return (_state as AccountsLoaded).transactionsByAccount[accountId] ?? [];
    }
    return [];
  }

  List<AccountTransactionEntity> get recentTransactions {
    if (_state is! AccountsLoaded) return [];
    final all = (_state as AccountsLoaded)
        .transactionsByAccount
        .values
        .expand((l) => l)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return all.take(20).toList();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> load() async {
    _state = const AccountsState.loading();
    notifyListeners();

    final uid = AuthService.instance.userId ?? '';

    final accountsFuture = _getAccounts();
    final loansFuture = _loanDs.getLoans(uid);

    final accountResult = await accountsFuture;
    _loans = await loansFuture;

    accountResult.when(
      success: (accounts) {
        _state = AccountsState.loaded(
          accounts: accounts,
          transactionsByAccount: {},
        );
      },
      failure: (f) => _state = AccountsState.error(message: f.message),
    );
    notifyListeners();
  }

  Future<void> loadTransactions(String accountId) async {
    if (_state is! AccountsLoaded) return;
    final loaded = _state as AccountsLoaded;

    final result = await _getTransactions(accountId);
    result.when(
      success: (txs) {
        final updated = Map<String, List<AccountTransactionEntity>>.from(
            loaded.transactionsByAccount);
        updated[accountId] = txs;
        _state = loaded.copyWith(transactionsByAccount: updated);
        notifyListeners();
      },
      failure: (_) {},
    );
  }

  Future<bool> addBankAccount({
    required String name,
    required BankName bank,
    required double balance,
    String? iban,
  }) async {
    final result = await _addAccount.addBankAccount(
      name: name,
      bank: bank,
      balance: balance,
      iban: iban,
    );
    return result.when(
      success: (_) {
        load();
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<bool> addCreditCard({
    required String name,
    required BankName bank,
    required double creditLimit,
    required double usedAmount,
    required double statementBalance,
    required double minimumPayment,
    required int statementClosingDay,
    required int paymentDueDay,
    String? maskedCardNumber,
  }) async {
    final result = await _addAccount.addCreditCard(
      name: name,
      bank: bank,
      creditLimit: creditLimit,
      usedAmount: usedAmount,
      statementBalance: statementBalance,
      minimumPayment: minimumPayment,
      statementClosingDay: statementClosingDay,
      paymentDueDay: paymentDueDay,
      maskedCardNumber: maskedCardNumber,
    );
    return result.when(
      success: (_) {
        load();
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<bool> deleteAccount(String id) async {
    // Optimistic UI — hesabı hemen kaldır
    if (_state is AccountsLoaded) {
      final loaded = _state as AccountsLoaded;
      final updated = loaded.accounts.where((a) {
        return a.when(
          bankAccount: (aid, _, __, ___, ____, _____, ______, _______, ________) => aid != id,
          creditCard: (aid, _, __, ___, ____, _____, ______, _______, ________, _________, __________, ___________, ____________) => aid != id,
        );
      }).toList();
      _state = loaded.copyWith(accounts: updated);
      notifyListeners();
    }

    final result = await _deleteAccount(id);
    return result.when(
      success: (_) => true,
      failure: (_) {
        load(); // hata olursa yenile
        return false;
      },
    );
  }

  Future<bool> updateCreditCardBalance({
    required CreditCardEntity card,
    required double newUsedAmount,
    required double newStatementBalance,
    required double newMinimumPayment,
  }) async {
    final updated = card.copyWith(
      usedAmount: newUsedAmount,
      statementBalance: newStatementBalance,
      minimumPayment: newMinimumPayment,
    );
    final result = await _updateAccount(updated);
    return result.when(
      success: (_) {
        load();
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<bool> addTransaction({
    required String accountId,
    required double amount,
    required String description,
    required String type,
    required String category,
    DateTime? date,
    bool isInstallment = false,
    int installmentCount = 1,
    String? merchantName,
  }) async {
    final result = await _addTransaction(
      accountId: accountId,
      amount: amount,
      description: description,
      type: type,
      category: category,
      date: date,
      isInstallment: isInstallment,
      installmentCount: installmentCount,
      merchantName: merchantName,
    );
    return result.when(
      success: (_) {
        loadTransactions(accountId);
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<bool> importStatement({
    required String accountId,
    required List<AccountTransactionEntity> transactions,
  }) async {
    final result = await _importStatement(
      accountId: accountId,
      transactions: transactions,
    );
    return result.when(
      success: (_) {
        loadTransactions(accountId);
        return true;
      },
      failure: (_) => false,
    );
  }

  void selectAccount(String? id) {
    if (_state is AccountsLoaded) {
      _state = (_state as AccountsLoaded).copyWith(selectedAccountId: id);
      notifyListeners();
    }
  }

  // ── Muhasebe İşlemleri ────────────────────────────────────────────────────

  /// Gelir kaydı — banka hesabına para girer, bakiye güncellenir
  Future<bool> recordIncome({
    required String bankAccountId,
    required double amount,
    required String description,
    required String category,
    DateTime? date,
  }) async {
    final txResult = await _addTransaction(
      accountId: bankAccountId,
      amount: amount,
      description: description,
      type: 'income',
      category: category,
      date: date,
    );
    if (txResult is Failure) return false;

    final banks = bankAccounts.where((a) => a.id == bankAccountId);
    if (banks.isNotEmpty) {
      final bank = banks.first;
      final updated = bank.copyWith(balance: bank.balance + amount);
      await _updateAccount(updated);
    }

    await load();
    return true;
  }

  /// Banka harcaması — banka hesabından para çıkar
  Future<bool> recordBankExpense({
    required String bankAccountId,
    required double amount,
    required String description,
    required String category,
    DateTime? date,
  }) async {
    final txResult = await _addTransaction(
      accountId: bankAccountId,
      amount: amount,
      description: description,
      type: 'expense',
      category: category,
      date: date,
    );
    if (txResult is Failure) return false;

    final banks = bankAccounts.where((a) => a.id == bankAccountId);
    if (banks.isNotEmpty) {
      final bank = banks.first;
      final updated = bank.copyWith(balance: bank.balance - amount);
      await _updateAccount(updated);
    }

    await load();
    return true;
  }

  /// Kredi kartı harcaması — kart kullanım miktarı artar, banka etkilenmez
  Future<bool> recordCreditExpense({
    required String creditCardId,
    required double amount,
    required String description,
    required String category,
    DateTime? date,
  }) async {
    final txResult = await _addTransaction(
      accountId: creditCardId,
      amount: amount,
      description: description,
      type: 'expense',
      category: category,
      date: date,
    );
    if (txResult is Failure) return false;

    final cards = creditCards.where((c) => c.id == creditCardId);
    if (cards.isNotEmpty) {
      final card = cards.first;
      final updated = card.copyWith(usedAmount: card.usedAmount + amount);
      await _updateAccount(updated);
    }

    await load();
    return true;
  }

  /// Kredi kartı ödemesi — bankadan ödeme yapılır, kart borcu düşer
  Future<bool> recordCreditPayment({
    required String bankAccountId,
    required String creditCardId,
    required double amount,
    DateTime? date,
  }) async {
    // 1. Banka hesabında gider işlemi
    await _addTransaction(
      accountId: bankAccountId,
      amount: amount,
      description: 'Kredi Kartı Ödemesi',
      type: 'creditPayment',
      category: creditCardId,
      date: date,
    );

    // 2. Banka bakiyesini güncelle
    final banks = bankAccounts.where((a) => a.id == bankAccountId);
    if (banks.isNotEmpty) {
      final bank = banks.first;
      await _updateAccount(bank.copyWith(balance: bank.balance - amount));
    }

    // 3. Kredi kartında gelir işlemi
    await _addTransaction(
      accountId: creditCardId,
      amount: amount,
      description: 'Ödeme Alındı',
      type: 'income',
      category: 'odeme',
      date: date,
    );

    // 4. Kart borçlarını güncelle
    final cards = creditCards.where((c) => c.id == creditCardId);
    if (cards.isNotEmpty) {
      final card = cards.first;
      final newUsed = (card.usedAmount - amount).clamp(0.0, card.creditLimit);
      final newStmt = (card.statementBalance - amount).clamp(0.0, double.infinity);
      await _updateAccount(card.copyWith(
        usedAmount: newUsed,
        statementBalance: newStmt,
      ));
    }

    await load();
    return true;
  }

  /// Hesaplar arası transfer
  Future<bool> recordTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String description = '',
    DateTime? date,
  }) async {
    // Gönderen hesap gider işlemi
    await _addTransaction(
      accountId: fromAccountId,
      amount: amount,
      description: description.isEmpty ? 'Transfer' : description,
      type: 'transfer',
      category: toAccountId,
      date: date,
    );

    final fromBanks = bankAccounts.where((a) => a.id == fromAccountId);
    if (fromBanks.isNotEmpty) {
      final bank = fromBanks.first;
      await _updateAccount(bank.copyWith(balance: bank.balance - amount));
    }

    // Alıcı hesap gelir işlemi
    await _addTransaction(
      accountId: toAccountId,
      amount: amount,
      description: description.isEmpty ? 'Transfer Alındı' : description,
      type: 'income',
      category: fromAccountId,
      date: date,
    );

    final toBanks = bankAccounts.where((a) => a.id == toAccountId);
    if (toBanks.isNotEmpty) {
      final bank = toBanks.first;
      await _updateAccount(bank.copyWith(balance: bank.balance + amount));
    }

    await load();
    return true;
  }

  /// Ekstre güncelleme — kredi kartı ayıklandığında yeni ekstrenin tutarını gir
  Future<bool> updateStatement({
    required CreditCardEntity card,
    required double statementBalance,
    required double minimumPayment,
  }) async {
    final updated = card.copyWith(
      statementBalance: statementBalance,
      minimumPayment: minimumPayment,
    );
    final result = await _updateAccount(updated);
    return result.when(
      success: (_) {
        load();
        return true;
      },
      failure: (_) => false,
    );
  }

  // ── Kredi İşlemleri ───────────────────────────────────────────────────────

  Future<void> addLoan({
    required String name,
    required BankName bank,
    required double totalAmount,
    required double monthlyPayment,
    required double interestRate,
    required int totalInstallments,
    required int paymentDueDay,
    DateTime? startDate,
    String? note,
  }) async {
    final uid = AuthService.instance.userId ?? '';
    if (uid.isEmpty) return;
    const uuid = Uuid();
    final now = DateTime.now();
    final loan = LoanEntity(
      id: uuid.v4(),
      userId: uid,
      name: name,
      bank: bank,
      totalAmount: totalAmount,
      remainingAmount: totalAmount,
      monthlyPayment: monthlyPayment,
      interestRate: interestRate,
      totalInstallments: totalInstallments,
      remainingInstallments: totalInstallments,
      paymentDueDay: paymentDueDay,
      startDate: startDate ?? now,
      createdAt: now,
      note: note,
    );
    await _loanDs.addLoan(loan);
    _loans = [..._loans, loan];
    notifyListeners();
  }

  Future<void> deleteLoan(String loanId) async {
    final uid = AuthService.instance.userId ?? '';
    if (uid.isEmpty) return;
    _loans = _loans.where((l) => l.id != loanId).toList();
    notifyListeners();
    await _loanDs.deleteLoan(uid, loanId);
  }

  /// Taksit ödemesi yap + harcama kaydı oluştur
  /// Hata varsa mesaj döner, null ise başarılı
  Future<String?> recordLoanPayment({
    required LoanEntity loan,
    required double amount,
    required SpendingViewModel spendingVm,
  }) async {
    final uid = AuthService.instance.userId ?? '';
    if (uid.isEmpty) return 'Oturum bulunamadı';
    try {
      await _loanDs.recordPayment(uid: uid, loan: loan, amount: amount);

      // Lokal listeyi güncelle
      final newRemaining = (loan.remainingInstallments - 1).clamp(0, loan.totalInstallments);
      final newRemainingAmount = (loan.remainingAmount - amount).clamp(0.0, loan.totalAmount);
      final updated = loan.copyWith(
        remainingAmount: newRemainingAmount,
        remainingInstallments: newRemaining,
        status: newRemaining <= 0 ? 'completed' : 'active',
      );
      _loans = _loans.map((l) => l.id == loan.id ? updated : l).toList();
      notifyListeners();

      // Harcama kaydı ekle
      await spendingVm.addTransaction(
        amount: amount,
        category: 'Kredi',
        type: 'gider',
        source: 'loan',
        note: '${loan.name} taksit ödemesi',
        reload: false,
      );
      await spendingVm.reload();

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Net varlık: banka bakiyesi - ekstre borcu
  double get netWorth => totalBankBalance - totalStatementDebt;
}
