import '../../../../core/utils/result.dart';
import '../entities/ai_message_entity.dart';
import '../repositories/ai_repository.dart';
import '../../data/models/ai_request_dto.dart';

/// Kullanıcı mesajını AI'ya gönderir, yanıt entity döner
class SendMessageUseCase {
  final AiRepository _repository;

  const SendMessageUseCase(this._repository);

  Future<Result<AiMessageEntity>> call({
    required String message,
    required String mode,
    required AiContextDto context,
    required List<Map<String, String>> history,
  }) {
    return _repository.sendMessage(
      message: message,
      mode: mode,
      context: context,
      history: history,
    );
  }
}
