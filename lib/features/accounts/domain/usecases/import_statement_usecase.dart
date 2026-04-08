import '../../../../core/utils/result.dart';
import '../entities/account_transaction_entity.dart';
import '../repositories/accounts_repository.dart';

class ImportStatementUseCase {
  final AccountsRepository _repository;
  const ImportStatementUseCase(this._repository);

  Future<Result<void>> call({
    required String accountId,
    required List<AccountTransactionEntity> transactions,
  }) =>
      _repository.importStatementTransactions(accountId, transactions);
}
