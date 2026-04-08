import '../../../../core/utils/result.dart';
import '../entities/financial_account_entity.dart';
import '../repositories/accounts_repository.dart';

class UpdateAccountUseCase {
  final AccountsRepository _repository;
  const UpdateAccountUseCase(this._repository);

  Future<Result<void>> call(FinancialAccountEntity account) =>
      _repository.updateAccount(account);
}
