import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_message_dto.freezed.dart';
part 'ai_message_dto.g.dart';

/// AI mesaj DTO — backend API ile haberleşme katmanı
@freezed
class AiMessageDto with _$AiMessageDto {
  const factory AiMessageDto({
    required String id,
    /// 'user' | 'assistant'
    required String role,
    required String content,
    required String timestamp,
    String? mode,
  }) = _AiMessageDto;

  factory AiMessageDto.fromJson(Map<String, dynamic> json) =>
      _$AiMessageDtoFromJson(json);
}
