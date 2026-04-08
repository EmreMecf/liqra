import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_dto.freezed.dart';
part 'transaction_dto.g.dart';

@freezed
class TransactionDto with _$TransactionDto {
  const factory TransactionDto({
    required String id,
    required String userId,
    required double amount,
    required String category,
    required String type,
    required String source,
    required String date,
    String? note,
  }) = _TransactionDto;

  factory TransactionDto.fromJson(Map<String, dynamic> json) =>
      _$TransactionDtoFromJson(json);
}

@freezed
class MonthlySummaryDto with _$MonthlySummaryDto {
  const factory MonthlySummaryDto({
    required double totalIncome,
    required double totalExpenses,
    required double netCash,
    required Map<String, double> byCategory,
    required int year,
    required int month,
  }) = _MonthlySummaryDto;

  factory MonthlySummaryDto.fromJson(Map<String, dynamic> json) =>
      _$MonthlySummaryDtoFromJson(json);
}
