import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/transaction_entity.dart';

part 'spending_state.freezed.dart';

@freezed
sealed class SpendingState with _$SpendingState {
  const factory SpendingState.initial() = SpendingInitial;

  const factory SpendingState.loading() = SpendingLoading;

  const factory SpendingState.loaded({
    required List<TransactionEntity> transactions,
    required MonthlySummaryEntity summary,
    String? filterCategory,
  }) = SpendingLoaded;

  const factory SpendingState.error({
    required String message,
    List<TransactionEntity>? previousTransactions,
  }) = SpendingError;
}

extension SpendingStateX on SpendingState {
  bool get isLoading => this is SpendingLoading;

  List<TransactionEntity> get transactions => switch (this) {
    SpendingLoaded s => s.filterCategory == null
        ? s.transactions
        : s.transactions.where((t) => t.category == s.filterCategory).toList(),
    SpendingError s => s.previousTransactions ?? const [],
    _ => const [],
  };
}
