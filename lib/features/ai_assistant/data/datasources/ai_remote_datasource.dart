import '../../../../core/error/app_exception.dart';
import '../../../../core/services/gemini_service.dart';
import '../models/ai_request_dto.dart';

/// Gemini'ye bağlanan ince katman.
///
/// Prompt kurmaz, bağlam bilmez — yalnızca hazır promptu gönderir. Prompt
/// mantığı `domain/assistant_prompts.dart` içindedir.
abstract interface class AiRemoteDataSource {
  Future<AiResponseDto> sendMessage(AiRequestDto request);
}

class AiRemoteDataSourceImpl implements AiRemoteDataSource {
  final GeminiService _gemini;

  const AiRemoteDataSourceImpl(this._gemini);

  @override
  Future<AiResponseDto> sendMessage(AiRequestDto request) async {
    try {
      final messages = <Map<String, String>>[
        ...request.history,
        {'role': 'user', 'content': request.message},
      ];

      final content = await _gemini.chat(
        systemPrompt: request.systemPrompt,
        messages:     messages,
        maxTokens:    request.maxTokens,
      );

      if (content.trim().isEmpty) {
        throw AppException.server(
          message: 'Liqra boş yanıt döndürdü. Lütfen tekrar deneyin.',
          statusCode: 200,
        );
      }

      return AiResponseDto(
        id:        DateTime.now().millisecondsSinceEpoch.toString(),
        content:   content,
        timestamp: DateTime.now().toIso8601String(),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.unknown(message: e.toString());
    }
  }
}
