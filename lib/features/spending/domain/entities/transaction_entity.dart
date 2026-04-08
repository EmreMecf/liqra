import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_entity.freezed.dart';

/// Spending domain entity — iş mantığı katmanı
@freezed
class TransactionEntity with _$TransactionEntity {
  const factory TransactionEntity({
    required String id,
    required String userId,
    required double amount,
    required String category,
    required String type,
    required String source,
    required DateTime date,
    String? note,
  }) = _TransactionEntity;
}

@freezed
class MonthlySummaryEntity with _$MonthlySummaryEntity {
  const factory MonthlySummaryEntity({
    required double totalIncome,
    required double totalExpenses,
    required double netCash,
    required Map<String, double> byCategory,
    required int year,
    required int month,
  }) = _MonthlySummaryEntity;
}

extension TransactionEntityX on TransactionEntity {
  bool get isIncome  => type == 'income'  || type == 'gelir';
  bool get isExpense => type == 'expense' || type == 'gider';
}
