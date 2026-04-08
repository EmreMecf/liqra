import '../../../../core/utils/result.dart';
import '../entities/financial_account_entity.dart';
import '../repositories/accounts_repository.dart';

class GetAccountsUseCase {
  final AccountsRepository _repository;
  const GetAccountsUseCase(this._repository);

  Future<Result<List<FinancialAccountEntity>>> call() =>
      _repository.getAccounts();
}
