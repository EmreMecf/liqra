import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_message_entity.freezed.dart';

/// Domain katmanı — saf iş mantığı nesnesi (JSON yok, Dio yok)
@freezed
class AiMessageEntity with _$AiMessageEntity {
  const factory AiMessageEntity({
    required String id,
    required AiRole role,
    required String content,
    required DateTime timestamp,
    String? mode,
  }) = _AiMessageEntity;
}

enum AiRole { user, assistant }

extension AiRoleX on AiRole {
  bool get isUser => this == AiRole.user;
  bool get isAssistant => this == AiRole.assistant;
  String get value => name;
}
