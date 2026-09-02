import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../data/models/money_flow.dart';
import '../../../../data/models/transaction_model.dart';
import '../../data/datasources/loan_firestore_datasource.dart';
import '../../domain/entities/account_transaction_entity.dart';
import '../../domain/entities/financial_account_entity.dart';
import '../../domain/entities/loan_entity.dart';
import '../../domain/statement_rollover.dart';
import '../../domain/usecases/add_account_transaction_usecase.dart';
import '../../domain/usecases/add_account_usecase.dart';
import '../../domain/usecases/delete_account_usecase.dart';
import '../../domain/usecases/get_account_transactions_usecase.dart';
import '../../domain/usecases/get_accounts_usecase.dart';
import '../../domain/usecases/import_statement_usecase.dart';
import '../../domain/usecases/record_money_movement_usecase.dart';
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
  final RecordCreditPaymentUseCase _recordCreditPayment;
  final RecordTransferUseCase _recordTransfer;
  final RecordAccountMovementUseCase _recordMovement;
  final RecordInstallmentPurchaseUseCase _recordInstallment;
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
    required RecordCreditPaymentUseCase recordCreditPayment,
    required RecordTransferUseCase recordTransfer,
    required RecordAccountMovementUseCase recordMovement,
    required RecordInstallmentPurchaseUseCase recordInstallment,
  })  : _getAccounts = getAccounts,
        _addAccount = addAccount,
        _deleteAccount = deleteAccount,
        _updateAccount = updateAccount,
        _getTransactions = getTransactions,
        _addTransaction = addTransaction,
        _importStatement = importStatement,
        _recordCreditPayment = recordCreditPayment,
        _recordTransfer = recordTransfer,
        _recordMovement = recordMovement,
        _recordInstallment = recordInstallment;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<FinancialAccountEntity> get accounts =>
      _state is AccountsLoaded ? (_state as AccountsLoaded).accounts : [];

  List<BankAccountEntity> get bankAccounts =>
      accounts.whereType<BankAccountEntity>().toList();

  List<CreditCardEntity> get creditCards =>
      accounts.whereType<CreditCardEntity>().toList();

  double get totalBankBalance =>
      bankAccounts.fold(0.0, (sum, a) => sum + a.balance);

  /// Kartların TOPLAM borcu — ekstreye yansımış ve yansımamış tümü.
  double get totalCreditUsed =>
      creditCards.fold(0.0, (sum, c) => sum + c.usedAmount);

  double get totalCreditLimit =>
      creditCards.fold(0.0, (sum, c) => sum + c.creditLimit);

  /// Yalnızca kesilmiş ekstrelerin toplamı — yaklaşan ödeme yükü.
  double get totalStatementDebt =>
      creditCards.fold(0.0, (sum, c) => sum + c.statementBalance);

  /// Henüz ekstreye girmemiş harcamalar — gelecek ayın ödeme yükü.
  double get totalUnbilled =>
      creditCards.fold(0.0, (sum, c) => sum + c.unbilledAmount);

  double get totalAvailableLimit =>
      creditCards.fold(0.0, (sum, c) => sum + c.availableLimit);

  /// Kart kullanım oranı — toplam borç / toplam limit.
  ///
  /// Kartların kullanım oranlarının ortalaması DEĞİLDİR: 100.000 limitli boş
  /// bir kartla 1.000 limitli dolu bir kart eşit ağırlık taşımamalı.
  /// Bankalar da bu oranı böyle hesaplar.
  double get creditUtilization =>
      totalCreditLimit > 0 ? totalCreditUsed / totalCreditLimit : 0.0;

  /// Son ödeme tarihi geçmiş ve hâlâ borcu olan kartlar.
  List<CreditCardEntity> get overdueCards =>
      creditCards.where((c) => c.isOverdue).toList();

  /// Kredi sağlığı skoru (0–100). Kullanım oranı + gecikme cezası.
  int get creditHealthScore {
    if (creditCards.isEmpty) return 100;
    final penalty = creditUtilization.clamp(0.0, 1.0) * 80 +
        overdueCards.length * 15;
    return (100 - penalty).clamp(0.0, 100.0).round();
  }

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

    if (accountResult.isFailure) {
      _state = AccountsState.error(message: accountResult.failure.message);
      notifyListeners();
      return;
    }

    final accounts = accountResult.data;
    // Kredi kartlarının hareketleri baştan yüklenir: ekstre devri ve
    // "kesimden sonraki harcama" hesabı bunlara dayanır.
    final txByAccount = await _loadCardTransactions(accounts);
    final synced = await _rollOverStatements(accounts, txByAccount);

    _state = AccountsState.loaded(
      accounts: synced,
      transactionsByAccount: txByAccount,
    );
    notifyListeners();
  }

  /// Tüm kredi kartlarının hareketlerini paralel yükler.
  Future<Map<String, List<AccountTransactionEntity>>> _loadCardTransactions(
      List<FinancialAccountEntity> accounts) async {
    final cards = accounts.whereType<CreditCardEntity>().toList();
    if (cards.isEmpty) return {};

    final results = await Future.wait(cards.map((c) => _getTransactions(c.id)));
    final map = <String, List<AccountTransactionEntity>>{};
    for (var i = 0; i < cards.length; i++) {
      results[i].when(
        success: (txs) => map[cards[i].id] = txs,
        failure: (_) {},
      );
    }
    return map;
  }

  /// Kesim günü geçmiş kartların ekstresini keser ve Firestore'a yazar.
  ///
  /// Devir idempotenttir (bkz. [StatementRollover]); burada yalnızca kesimden
  /// sonraki harcama toplamı hesaplanır.
  Future<List<FinancialAccountEntity>> _rollOverStatements(
    List<FinancialAccountEntity> accounts,
    Map<String, List<AccountTransactionEntity>> txByAccount,
  ) async {
    final updated = <FinancialAccountEntity>[];
    var changed = false;

    for (final acc in accounts) {
      if (acc is! CreditCardEntity || !StatementRollover.isDue(acc)) {
        updated.add(acc);
        continue;
      }

      final closing = acc.lastClosingDate;
      final unbilled = (txByAccount[acc.id] ?? const [])
          .where((t) =>
              t.moneyFlow == MoneyFlow.cardExpense &&
              t.date.isAfter(closing))
          .fold(0.0, (sum, t) => sum + t.amount);

      final rolled = StatementRollover.apply(acc, unbilledSinceClosing: unbilled);
      if (rolled == null) {
        updated.add(acc);
        continue;
      }

      changed = true;
      updated.add(rolled);
      await _updateAccount(rolled); // hata olursa bir sonraki açılışta tekrarlanır
    }

    return changed ? updated : accounts;
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
    // Optimistic UI — hesabı hemen kaldır.
    // Hesap kimliği tüm birleşim üyelerinde ortak olduğu için doğrudan okunur;
    // pozisyonel destructuring kullanılsaydı her yeni alanda bozulurdu.
    if (_state is AccountsLoaded) {
      final loaded = _state as AccountsLoaded;
      _state = loaded.copyWith(
        accounts: loaded.accounts.where((a) => a.id != id).toList(),
      );
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
      usedAmount:        newUsedAmount,
      statementBalance:  newStatementBalance,
      minimumPayment:    newMinimumPayment,
      // Elle girilen değerler devir tarafından ezilmesin
      statementClosedAt: card.lastClosingDate,
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

  /// Gelir kaydı — banka hesabına para girer.
  ///
  /// Hesap hareketi + ANA DEFTER kaydı + bakiye TEK batch'te yazılır.
  /// Eskiden üç ayrı yazma vardı ve ana deftere hiç yazılmıyordu; bu yüzden
  /// cüzdandan girilen gelir Dashboard'da görünmüyordu.
  Future<bool> recordIncome({
    required String bankAccountId,
    required double amount,
    required String description,
    required String category,
    DateTime? date,
  }) =>
      _movement(
        accountId:   bankAccountId,
        amount:      amount,
        description: description,
        category:    category,
        flow:        MoneyFlow.income,
        date:        date,
      );

  /// Banka harcaması — nakit çıkar, gider sayılır.
  Future<bool> recordBankExpense({
    required String bankAccountId,
    required double amount,
    required String description,
    required String category,
    DateTime? date,
  }) =>
      _movement(
        accountId:   bankAccountId,
        amount:      amount,
        description: description,
        category:    category,
        flow:        MoneyFlow.expense,
        date:        date,
      );

  /// Kredi kartı harcaması — kart borcu artar, NAKİT ETKİLENMEZ.
  /// Tahakkuk esası: gider satın alma anında yazılır, ödeme anında değil.
  Future<bool> recordCreditExpense({
    required String creditCardId,
    required double amount,
    required String description,
    required String category,
    DateTime? date,
  }) =>
      _movement(
        accountId:   creditCardId,
        amount:      amount,
        description: description,
        category:    category,
        flow:        MoneyFlow.cardExpense,
        date:        date,
      );

  /// Taksitli kart alışverişi — her taksit kendi ayının gideri olur.
  Future<bool> recordInstallmentPurchase({
    required String creditCardId,
    required double totalAmount,
    required int installmentCount,
    required String description,
    required String category,
    DateTime? date,
  }) async {
    final result = await _recordInstallment(
      creditCardId:     creditCardId,
      totalAmount:      totalAmount,
      installmentCount: installmentCount,
      description:      description,
      category:         category,
      date:             date,
    );
    if (result.isFailure) return false;
    await load();
    return true;
  }

  Future<bool> _movement({
    required String accountId,
    required double amount,
    required String description,
    required String category,
    required MoneyFlow flow,
    DateTime? date,
  }) async {
    final result = await _recordMovement(
      accountId:   accountId,
      amount:      amount,
      description: description,
      category:    category,
      flow:        flow,
      date:        date,
    );
    if (result.isFailure) return false;
    await load();
    return true;
  }

  Future<bool> recordCreditPayment({
    required String bankAccountId,
    required String creditCardId,
    required double amount,
    DateTime? date,
  }) async {
    // Tek batch: banka gideri + kart ödemesi + iki bakiye güncellemesi.
    // Eskiden 4 ayrı yazma yapılıyordu; ortada hata olursa bakiye tutarsız
    // kalıyordu. Bakiyeler FieldValue.increment ile güncellenir (yarış yok).
    final result = await _recordCreditPayment(
      bankAccountId: bankAccountId,
      creditCardId:  creditCardId,
      amount:        amount,
      date:          date,
    );

    if (result.isFailure) return false;
    await load();
    return true;
  }

  /// Hesaplar arası transfer — tek batch, atomik
  Future<bool> recordTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String description = '',
    DateTime? date,
  }) async {
    if (fromAccountId == toAccountId) return false;

    final result = await _recordTransfer(
      fromAccountId: fromAccountId,
      toAccountId:   toAccountId,
      amount:        amount,
      description:   description,
      date:          date,
    );

    if (result.isFailure) return false;
    await load();
    return true;
  }

  /// Ekstre tutarını elle düzeltir.
  ///
  /// Ekstre artık kesim gününde otomatik oluşuyor (bkz. [StatementRollover]);
  /// bu yol yalnızca banka ekstresi farklı geldiğinde düzeltme içindir.
  /// `statementClosedAt` damgalanmazsa devir bir sonraki açılışta kullanıcının
  /// girdiği değeri ezerdi.
  Future<bool> updateStatement({
    required CreditCardEntity card,
    required double statementBalance,
    required double minimumPayment,
  }) async {
    final updated = card.copyWith(
      statementBalance:  statementBalance,
      minimumPayment:    minimumPayment,
      statementClosedAt: card.lastClosingDate,
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
        lastPaymentDate: DateTime.now(), // gecikme uyarısı hemen kalksin
      );
      _loans = _loans.map((l) => l.id == loan.id ? updated : l).toList();
      notifyListeners();

      // Harcama kaydı ekle — kredi taksidi ayrı bir akış tipidir:
      // nakit çıkar ve bütçe gerçekliği açısından gider sayılır.
      await spendingVm.addTransaction(
        amount: amount,
        category: TransactionCategory.fatura.slug,
        type: 'expense',
        flow: MoneyFlow.loanPayment,
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

  /// Net varlık: banka bakiyesi − kartların TOPLAM borcu.
  ///
  /// Ekstre borcu değil toplam borç düşülür: kesimden sonra yapılan harcamalar
  /// henüz ekstreye girmese de borçtur. Eskiden yalnızca ekstre borcu
  /// düşülüyor ve net servet olduğundan yüksek görünüyordu.
  double get netWorth => totalBankBalance - totalCreditUsed;
}
