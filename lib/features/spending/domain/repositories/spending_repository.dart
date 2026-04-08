import '../../../../core/utils/result.dart';
import '../entities/transaction_entity.dart';

abstract interface class SpendingRepository {
  Future<Result<List<TransactionEntity>>> getTransactions({
    String? userId,
    DateTime? from,
    DateTime? to,
    String? category,
  });

  Future<Result<TransactionEntity>> addTransaction(TransactionEntity tx);
  Future<Result<void>> deleteTransaction(String id);
  Future<Result<MonthlySummaryEntity>> getMonthlySummary(int year, int month);
  Future<Result<List<TransactionEntity>>> getCurrentMonthTransactions();
}
