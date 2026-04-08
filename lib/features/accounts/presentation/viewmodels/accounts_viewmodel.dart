import 'package:flutter/foundation.dart';

import '../../domain/entities/account_transaction_entity.dart';
import '../../domain/entities/financial_account_entity.dart';
import '../../domain/usecases/add_account_transaction_usecase.dart';
import '../../domain/usecases/add_account_usecase.dart';
import '../../domain/usecases/delete_account_usecase.dart';
import '../../domain/usecases/get_account_transactions_usecase.dart';
import '../../domain/usecases/get_accounts_usecase.dart';
import '../../domain/usecases/import_statement_usecase.dart';
import '../../domain/usecases/update_account_usecase.dart';
import 'accounts_state.dart';

class AccountsViewModel extends ChangeNotifier {
  final GetAccountsUseCase _getAccounts;
  final AddAccountUseCase _addAccount;
  final DeleteAccountUseCase _deleteAccount;
  final UpdateAccountUseCase _updateAccount;
  final GetAccountTransactionsUseCase _getTransactions;
  final AddAccountTransactionUseCase _addTransaction;
  final ImportStatementUseCase _importStatement;

  AccountsState _state = const AccountsState.initial();
  AccountsState get state => _state;

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

    final result = await _getAccounts();
    result.when(
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
}
