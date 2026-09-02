import '../../../../core/utils/result.dart';
import '../assistant_context.dart';
import '../assistant_prompts.dart';
import '../entities/ai_message_entity.dart';
import '../repositories/ai_repository.dart';

/// Sohbet mesajı gönderir. Sistem promptunu bağlamdan burada kurar.
class SendMessageUseCase {
  final AiRepository _repository;

  const SendMessageUseCase(this._repository);

  Future<Result<AiMessageEntity>> call({
    required String message,
    required String mode,
    required AssistantContext context,
    required List<Map<String, String>> history,
  }) =>
      _repository.sendMessage(
        systemPrompt: AssistantPrompts.chat(mode, context),
        message:      message,
        mode:         mode,
        history:      history,
      );
}
