import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/account_transaction_entity.dart';
import '../../domain/entities/financial_account_entity.dart';

part 'accounts_state.freezed.dart';

@freezed
sealed class AccountsState with _$AccountsState {
  const factory AccountsState.initial() = AccountsInitial;
  const factory AccountsState.loading() = AccountsLoading;
  const factory AccountsState.loaded({
    required List<FinancialAccountEntity> accounts,
    required Map<String, List<AccountTransactionEntity>> transactionsByAccount,
    String? selectedAccountId,
  }) = AccountsLoaded;
  const factory AccountsState.error({required String message}) = AccountsError;
}
