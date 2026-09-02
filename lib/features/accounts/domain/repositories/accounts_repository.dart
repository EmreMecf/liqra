import '../../../../core/utils/result.dart';
import '../../../../data/models/money_flow.dart';
import '../entities/account_transaction_entity.dart';
import '../entities/financial_account_entity.dart';

abstract class AccountsRepository {
  Future<Result<List<FinancialAccountEntity>>> getAccounts();
  Future<Result<FinancialAccountEntity>> addAccount(
      FinancialAccountEntity account);
  Future<Result<void>> updateAccount(FinancialAccountEntity account);
  Future<Result<void>> deleteAccount(String id);
  Future<Result<List<AccountTransactionEntity>>> getTransactions(
      String accountId);
  Future<Result<AccountTransactionEntity>> addTransaction(
      AccountTransactionEntity tx);
  Future<Result<void>> importStatementTransactions(
      String accountId, List<AccountTransactionEntity> transactions);
  Future<Result<void>> deleteTransaction(String accountId, String txId);

  // ── Atomik para hareketleri ────────────────────────────────────────────────
  // Tek Firestore batch'i: işlem kayıtları + bakiye güncellemeleri birlikte
  // commit edilir. Ayrı ayrı yazımda ortada hata olursa bakiye tutarsız kalır.

  /// Kredi kartı ödemesi: banka bakiyesi düşer, kart borcu ve ekstre azalır.
  Future<Result<void>> recordCreditPayment({
    required String bankAccountId,
    required String creditCardId,
    required double amount,
    required DateTime date,
  });

  /// Tek hesabı ilgilendiren para hareketi (gelir, banka harcaması,
  /// kart harcaması). Hesap hareketi + ana defter kaydı + bakiye tek batch'te.
  Future<Result<void>> recordAccountMovement({
    required String accountId,
    required double amount,
    required String description,
    required String category,
    required MoneyFlow flow,
    required DateTime date,
    bool isInstallment,
    int installmentCount,
    String? merchantName,
  });

  /// Taksitli kart alışverişi: her taksit kendi ayının tarihiyle ayrı bir
  /// hareket olur, kart borcu ise tek seferde toplam tutar kadar artar.
  /// Taksit sayısı 2'den küçükse normal kart harcamasına düşer.
  Future<Result<void>> recordInstallmentPurchase({
    required String creditCardId,
    required double totalAmount,
    required int installmentCount,
    required String description,
    required String category,
    required DateTime date,
    String? merchantName,
  });

  /// İki banka hesabı arasında transfer.
  Future<Result<void>> recordTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required DateTime date,
    required String description,
  });
}
