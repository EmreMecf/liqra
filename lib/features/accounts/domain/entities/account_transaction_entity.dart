import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/models/money_flow.dart';

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
    /// Aynı taksitli alışverişin parçalarını birbirine bağlar.
    String? installmentGroupId,
    String? merchantName,
    String? statementId,
    @Default('manual') String source,
    /// Para akışı türü (MoneyFlow.slug) — ana deftere bu değerle yazılır
    String? flow,
    String? counterAccountId,
  }) = _AccountTransactionEntity;

  factory AccountTransactionEntity.fromJson(Map<String, dynamic> json) =>
      _$AccountTransactionEntityFromJson(json);
}

extension AccountTransactionEntityX on AccountTransactionEntity {
  bool get isIncome => type == 'income' || type == 'gelir';
  bool get isExpense => type == 'expense' || type == 'gider';

  /// Hareketin para akışı türü. Eski kayıtlarda `flow` alanı yoktur —
  /// [MoneyFlowParser] bunu type + category'den türetir.
  MoneyFlow get moneyFlow => MoneyFlowParser.parse(
        rawFlow: flow,
        rawType: type,
        categorySlug: category,
      );
}
