import 'package:uuid/uuid.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/result.dart';
import '../entities/account_transaction_entity.dart';
import '../repositories/accounts_repository.dart';

class AddAccountTransactionUseCase {
  final AccountsRepository _repository;
  static const _uuid = Uuid();
  const AddAccountTransactionUseCase(this._repository);

  String get _uid => AuthService.instance.userId ?? '';

  Future<Result<AccountTransactionEntity>> call({
    required String accountId,
    required double amount,
    required String description,
    required String type,
    required String category,
    DateTime? date,
    bool isInstallment = false,
    int installmentCount = 1,
    int installmentNumber = 1,
    String? merchantName,
    String source = 'manual',
  }) {
    final tx = AccountTransactionEntity(
      id: _uuid.v4(),
      accountId: accountId,
      userId: _uid,
      amount: amount,
      description: description,
      date: date ?? DateTime.now(),
      type: type,
      category: category,
      isInstallment: isInstallment,
      installmentCount: installmentCount,
      installmentNumber: installmentNumber,
      merchantName: merchantName,
      source: source,
    );
    return _repository.addTransaction(tx);
  }
}
