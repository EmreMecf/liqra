import '../../../../core/utils/result.dart';
import '../repositories/spending_repository.dart';

class DeleteTransactionUseCase {
  final SpendingRepository _repository;
  const DeleteTransactionUseCase(this._repository);

  Future<Result<void>> call(String id) => _repository.deleteTransaction(id);
}
