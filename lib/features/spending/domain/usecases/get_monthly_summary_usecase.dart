import '../../../../core/utils/result.dart';
import '../entities/transaction_entity.dart';
import '../repositories/spending_repository.dart';

class GetMonthlySummaryUseCase {
  final SpendingRepository _repository;
  const GetMonthlySummaryUseCase(this._repository);

  Future<Result<MonthlySummaryEntity>> call({
    int? year,
    int? month,
  }) {
    final now = DateTime.now();
    return _repository.getMonthlySummary(
      year ?? now.year,
      month ?? now.month,
    );
  }
}
