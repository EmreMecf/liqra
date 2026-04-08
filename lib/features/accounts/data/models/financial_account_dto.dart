import 'package:freezed_annotation/freezed_annotation.dart';

part 'financial_account_dto.freezed.dart';
part 'financial_account_dto.g.dart';

@freezed
class FinancialAccountDto with _$FinancialAccountDto {
  const factory FinancialAccountDto({
    required String id,
    required String userId,
    required String type,
    required String name,
    required String bank,
    required String currency,
    required String createdAt,
    // BankAccount fields
    double? balance,
    String? iban,
    String? maskedAccountNumber,
    // CreditCard fields
    double? creditLimit,
    double? usedAmount,
    double? statementBalance,
    double? minimumPayment,
    int? statementClosingDay,
    int? paymentDueDay,
    String? maskedCardNumber,
  }) = _FinancialAccountDto;

  factory FinancialAccountDto.fromJson(Map<String, dynamic> json) =>
      _$FinancialAccountDtoFromJson(json);
}
