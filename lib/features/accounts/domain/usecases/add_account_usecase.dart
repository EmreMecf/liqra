import 'package:uuid/uuid.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/result.dart';
import '../entities/financial_account_entity.dart';
import '../repositories/accounts_repository.dart';

class AddAccountUseCase {
  final AccountsRepository _repository;
  static const _uuid = Uuid();
  const AddAccountUseCase(this._repository);

  String get _uid => AuthService.instance.userId ?? '';

  /// Banka hesabı ekle
  Future<Result<FinancialAccountEntity>> addBankAccount({
    required String name,
    required BankName bank,
    required double balance,
    String currency = 'TRY',
    String? iban,
    String? maskedAccountNumber,
  }) {
    final entity = FinancialAccountEntity.bankAccount(
      id: _uuid.v4(),
      userId: _uid,
      name: name,
      bank: bank,
      balance: balance,
      currency: currency,
      iban: iban,
      maskedAccountNumber: maskedAccountNumber,
      createdAt: DateTime.now(),
    );
    return _repository.addAccount(entity);
  }

  /// Kredi kartı ekle
  Future<Result<FinancialAccountEntity>> addCreditCard({
    required String name,
    required BankName bank,
    required double creditLimit,
    required double usedAmount,
    required double statementBalance,
    required double minimumPayment,
    required int statementClosingDay,
    required int paymentDueDay,
    String? maskedCardNumber,
    String currency = 'TRY',
  }) {
    final entity = FinancialAccountEntity.creditCard(
      id: _uuid.v4(),
      userId: _uid,
      name: name,
      bank: bank,
      creditLimit: creditLimit,
      usedAmount: usedAmount,
      statementBalance: statementBalance,
      minimumPayment: minimumPayment,
      statementClosingDay: statementClosingDay,
      paymentDueDay: paymentDueDay,
      maskedCardNumber: maskedCardNumber,
      currency: currency,
      createdAt: DateTime.now(),
    );
    return _repository.addAccount(entity);
  }
}
