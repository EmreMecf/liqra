import '../../../../core/utils/result.dart';
import '../repositories/accounts_repository.dart';

class DeleteAccountUseCase {
  final AccountsRepository _repository;
  const DeleteAccountUseCase(this._repository);

  Future<Result<void>> call(String accountId) =>
      _repository.deleteAccount(accountId);
}
