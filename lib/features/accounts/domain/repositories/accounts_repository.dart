import '../../../../core/utils/result.dart';
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
}
