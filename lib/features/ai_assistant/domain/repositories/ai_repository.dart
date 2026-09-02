import '../../../../core/utils/result.dart';
import '../entities/ai_message_entity.dart';

/// AI repository sözleşmesi — domain katmanı bunu bilir, impl'i bilmez.
abstract interface class AiRepository {
  /// Sohbet — geçmişle birlikte.
  Future<Result<AiMessageEntity>> sendMessage({
    required String systemPrompt,
    required String message,
    required String mode,
    required List<Map<String, String>> history,
    int maxTokens,
  });

  /// Tek seferlik görev — geçmiş yok (hisse analizi, harcama denetimi,
  /// birikim planı). Sonuç düz metin döner.
  Future<Result<String>> complete({
    required String systemPrompt,
    required String userPrompt,
    int maxTokens,
  });

  /// Konuşma geçmişini temizle.
  Future<Result<void>> clearHistory(String userId);
}
