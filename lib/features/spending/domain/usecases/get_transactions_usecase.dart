import '../../../../core/utils/result.dart';
import '../entities/transaction_entity.dart';
import '../repositories/spending_repository.dart';

class GetTransactionsUseCase {
  final SpendingRepository _repository;
  const GetTransactionsUseCase(this._repository);

  Future<Result<List<TransactionEntity>>> call({
    DateTime? from,
    DateTime? to,
    String? category,
  }) =>
      _repository.getTransactions(from: from, to: to, category: category);

  Future<Result<List<TransactionEntity>>> currentMonth() =>
      _repository.getCurrentMonthTransactions();
}
