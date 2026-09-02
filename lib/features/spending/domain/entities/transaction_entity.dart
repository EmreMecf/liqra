import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/models/money_flow.dart';

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
    /// Para hareketi türü. Eski kayıtlar için repository katmanında
    /// type+category'den türetilir; bu yüzden burada zorunlu.
    @Default(MoneyFlow.expense) MoneyFlow flow,
    String? accountId,
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
  // NOT: isIncome/isExpense artık `flow` üzerinden çalışır. Eskiden ham `type`
  // string'ine bakılıyordu; bu yüzden yatırım alımı ve kart ödemesi de gider
  // sayılıyor, aynı para iki kez düşülüyordu.
  bool get isIncome  => flow.countsAsIncome;
  bool get isExpense => flow.countsAsExpense;

  /// Nakit üzerindeki işaretli etkisi (kart harcaması nakdi etkilemez)
  double get cashEffect => amount * flow.cashDirection;
}
