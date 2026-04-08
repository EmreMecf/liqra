import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_request_dto.freezed.dart';
part 'ai_request_dto.g.dart';

/// Backend'e gönderilecek AI istek DTO'su
@freezed
class AiRequestDto with _$AiRequestDto {
  const factory AiRequestDto({
    required String message,
    required String mode,
    required AiContextDto context,
    @Default([]) List<Map<String, String>> history,
  }) = _AiRequestDto;

  factory AiRequestDto.fromJson(Map<String, dynamic> json) =>
      _$AiRequestDtoFromJson(json);
}

/// Claude'a gönderilecek kullanıcı bağlamı
@freezed
class AiContextDto with _$AiContextDto {
  const factory AiContextDto({
    required String riskProfile,
    required double monthlyIncome,
    required double monthlyExpenses,
    required double netCash,
    required String portfolioSummary,
    required String transactionsSummary,
    String? goalTitle,
    double? goalProgress,
    String? goalDeadline,
  }) = _AiContextDto;

  factory AiContextDto.fromJson(Map<String, dynamic> json) =>
      _$AiContextDtoFromJson(json);
}

/// Backend'den dönen cevap DTO'su
@freezed
class AiResponseDto with _$AiResponseDto {
  const factory AiResponseDto({
    required String id,
    required String content,
    required String timestamp,
    int? inputTokens,
    int? outputTokens,
  }) = _AiResponseDto;

  factory AiResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AiResponseDtoFromJson(json);
}
