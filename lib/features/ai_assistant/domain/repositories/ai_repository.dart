import '../../../../core/utils/result.dart';
import '../entities/ai_message_entity.dart';
import '../../data/models/ai_request_dto.dart';

/// AI repository sözleşmesi — domain katmanı bunu bilir, impl'i bilmez
abstract interface class AiRepository {
  /// Claude API'ye mesaj gönder, yanıt al
  Future<Result<AiMessageEntity>> sendMessage({
    required String message,
    required String mode,
    required AiContextDto context,
    required List<Map<String, String>> history,
  });

  /// Konuşma geçmişini temizle
  Future<Result<void>> clearHistory(String userId);
}
