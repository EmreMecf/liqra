import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/ai_message_entity.dart';

part 'ai_assistant_state.freezed.dart';

/// AI Asistan ekranı sealed state — pattern matching ile UI güvenli
@freezed
sealed class AiAssistantState with _$AiAssistantState {
  /// Uygulama ilk açıldığında / geçmiş boş
  const factory AiAssistantState.initial() = AiInitial;

  /// Mesaj gönderildi, yanıt bekleniyor
  const factory AiAssistantState.loading({
    required List<AiMessageEntity> messages,
  }) = AiLoading;

  /// Yanıt geldi, mesajlar güncellendi
  const factory AiAssistantState.loaded({
    required List<AiMessageEntity> messages,
  }) = AiLoaded;

  /// Hata oluştu — önceki mesajlar korunur
  const factory AiAssistantState.error({
    required String message,
    required List<AiMessageEntity> previousMessages,
  }) = AiError;
}

extension AiAssistantStateX on AiAssistantState {
  List<AiMessageEntity> get messages => switch (this) {
    AiInitial()   => const [],
    AiLoading s   => s.messages,
    AiLoaded s    => s.messages,
    AiError s     => s.previousMessages,
  };

  bool get isLoading => this is AiLoading;
  bool get hasError  => this is AiError;
}
