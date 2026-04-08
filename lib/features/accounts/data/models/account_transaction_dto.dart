import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_transaction_dto.freezed.dart';
part 'account_transaction_dto.g.dart';

@freezed
class AccountTransactionDto with _$AccountTransactionDto {
  const factory AccountTransactionDto({
    required String id,
    required String accountId,
    required String userId,
    required double amount,
    required String description,
    required String date,
    required String type,
    required String category,
    @Default(false) bool isInstallment,
    @Default(1) int installmentCount,
    @Default(1) int installmentNumber,
    String? merchantName,
    String? statementId,
    @Default('manual') String source,
  }) = _AccountTransactionDto;

  factory AccountTransactionDto.fromJson(Map<String, dynamic> json) =>
      _$AccountTransactionDtoFromJson(json);
}
