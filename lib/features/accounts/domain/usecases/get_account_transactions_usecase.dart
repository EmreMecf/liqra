import '../../../../core/utils/result.dart';
import '../entities/account_transaction_entity.dart';
import '../repositories/accounts_repository.dart';

class GetAccountTransactionsUseCase {
  final AccountsRepository _repository;
  const GetAccountTransactionsUseCase(this._repository);

  Future<Result<List<AccountTransactionEntity>>> call(String accountId) =>
      _repository.getTransactions(accountId);
}
