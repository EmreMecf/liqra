import 'package:uuid/uuid.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/result.dart';
import '../../../../data/models/money_flow.dart';
import '../entities/transaction_entity.dart';
import '../repositories/spending_repository.dart';

class AddTransactionUseCase {
  final SpendingRepository _repository;
  static const _uuid = Uuid();
  const AddTransactionUseCase(this._repository);

  /// [flow] verilmezse [type] ve [category]'den türetilir — böylece eski
  /// çağrı noktaları kırılmaz ama yeni kayıtlar doğru akış tipiyle yazılır.
  Future<Result<TransactionEntity>> call({
    required double amount,
    required String category,
    required String type,
    MoneyFlow? flow,
    String source = 'manual',
    String? note,
    DateTime? date,
    String? accountId,
  }) {
    final resolved = flow ??
        MoneyFlowParser.parse(rawType: type, categorySlug: category);

    final entity = TransactionEntity(
      id: _uuid.v4(),
      userId: AuthService.instance.userId ?? '',
      amount: amount,
      category: category,
      type: type,
      source: source,
      date: date ?? DateTime.now(),
      note: note,
      flow: resolved,
      accountId: accountId,
    );
    return _repository.addTransaction(entity);
  }
}
