import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_transaction_entity.freezed.dart';
part 'account_transaction_entity.g.dart';

@freezed
class AccountTransactionEntity with _$AccountTransactionEntity {
  const factory AccountTransactionEntity({
    required String id,
    required String accountId,
    required String userId,
    required double amount,
    required String description,
    required DateTime date,
    required String type,
    required String category,
    @Default(false) bool isInstallment,
    @Default(1) int installmentCount,
    @Default(1) int installmentNumber,
    String? merchantName,
    String? statementId,
    @Default('manual') String source,
  }) = _AccountTransactionEntity;

  factory AccountTransactionEntity.fromJson(Map<String, dynamic> json) =>
      _$AccountTransactionEntityFromJson(json);
}

extension AccountTransactionEntityX on AccountTransactionEntity {
  bool get isIncome => type == 'income' || type == 'gelir';
  bool get isExpense => type == 'expense' || type == 'gider';
}
