import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_request_dto.freezed.dart';
part 'ai_request_dto.g.dart';

/// Modele gönderilen istek.
///
/// Sistem promptu **domain katmanında** (`AssistantPrompts`) üretilir ve hazır
/// gelir. Eskiden prompt data katmanındaki datasource içinde kuruluyordu; bu
/// yüzden bağlamı zenginleştirmek için altyapı koduna dokunmak gerekiyordu ve
/// prompt test edilemiyordu.
@freezed
class AiRequestDto with _$AiRequestDto {
  const factory AiRequestDto({
    required String systemPrompt,
    required String message,
    @Default([]) List<Map<String, String>> history,

    /// Uzun analiz görevleri daha yüksek limit ister.
    @Default(2048) int maxTokens,
  }) = _AiRequestDto;

  factory AiRequestDto.fromJson(Map<String, dynamic> json) =>
      _$AiRequestDtoFromJson(json);
}

/// Modelden dönen cevap.
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
