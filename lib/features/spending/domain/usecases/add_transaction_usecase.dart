import 'package:uuid/uuid.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/result.dart';
import '../entities/transaction_entity.dart';
import '../repositories/spending_repository.dart';

class AddTransactionUseCase {
  final SpendingRepository _repository;
  static const _uuid = Uuid();
  const AddTransactionUseCase(this._repository);

  Future<Result<TransactionEntity>> call({
    required double amount,
    required String category,
    required String type,
    String source = 'manual',
    String? note,
    DateTime? date,
  }) {
    final entity = TransactionEntity(
      id: _uuid.v4(),
      userId: AuthService.instance.userId ?? '',
      amount: amount,
      category: category,
      type: type,
      source: source,
      date: date ?? DateTime.now(),
      note: note,
    );
    return _repository.addTransaction(entity);
  }
}
