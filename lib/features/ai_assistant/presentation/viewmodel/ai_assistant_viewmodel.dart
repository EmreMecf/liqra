import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/ai_message_entity.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/get_context_usecase.dart';
import 'ai_assistant_state.dart';

/// AI Asistan ViewModel
/// Provider ile bağlı — UI sadece state'i izler, iş mantığına dokunmaz
class AiAssistantViewModel extends ChangeNotifier {
  final SendMessageUseCase _sendMessage;
  final GetContextUseCase _getContext;
  static const _uuid = Uuid();

  AiAssistantViewModel({
    required SendMessageUseCase sendMessage,
    required GetContextUseCase getContext,
  })  : _sendMessage = sendMessage,
        _getContext = getContext;

  // ── State ─────────────────────────────────────────────────────────────────

  AiAssistantState _state = const AiAssistantState.initial();
  AiAssistantState get state => _state;

  String _mode = 'budget_audit';
  String get mode => _mode;

  // ── Mod Yönetimi ──────────────────────────────────────────────────────────

  void setMode(String mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  final Map<String, String> modeLabels = const {
    'budget_audit':      'Bütçe Denetimi',
    'portfolio_advisor': 'Yatırım Tavsiyesi',
    'goal_tracker':      'Hedef Analizi',
    'free_chat':         'Serbest Sohbet',
  };

  final Map<String, String> modeIcons = const {
    'budget_audit':      '📊',
    'portfolio_advisor': '📈',
    'goal_tracker':      '🎯',
    'free_chat':         '💬',
  };

  // ── Mesaj Gönderme ────────────────────────────────────────────────────────

  Future<void> sendMessage({
    required String text,
    // Bağlam parametreleri — AppProvider'dan veya ViewModel'den gelir
    required String riskProfile,
    required double monthlyIncome,
    required double monthlyExpenses,
    required String transactionsSummary,
    required String portfolioSummary,
    String? goalTitle,
    double? goalProgress,
    String? goalDeadline,
  }) async {
    if (text.trim().isEmpty) return;

    // Kullanıcı mesajını anında ekle
    final userMessage = AiMessageEntity(
      id: _uuid.v4(),
      role: AiRole.user,
      content: text.trim(),
      timestamp: DateTime.now(),
      mode: _mode,
    );

    final currentMessages = [..._state.messages, userMessage];
    _state = AiAssistantState.loading(messages: currentMessages);
    notifyListeners();

    // Bağlam oluştur
    final context = _getContext(
      riskProfile: riskProfile,
      monthlyIncome: monthlyIncome,
      monthlyExpenses: monthlyExpenses,
      transactionsSummary: transactionsSummary,
      portfolioSummary: portfolioSummary,
      goalTitle: goalTitle,
      goalProgress: goalProgress,
      goalDeadline: goalDeadline,
    );

    // Geçmiş — son 10 mesaj (token tasarrufu)
    final history = currentMessages
        .take(10)
        .map((m) => {'role': m.role.value, 'content': m.content})
        .toList();

    final result = await _sendMessage(
      message: text.trim(),
      mode: _mode,
      context: context,
      history: history,
    );

    result.when(
      success: (response) {
        _state = AiAssistantState.loaded(
          messages: [...currentMessages, response],
        );
      },
      failure: (failure) {
        _state = AiAssistantState.error(
          message: failure.message,
          previousMessages: currentMessages,
        );
      },
    );

    notifyListeners();
  }

  // ── Geçmiş Yönetimi ───────────────────────────────────────────────────────

  void clearHistory() {
    _state = const AiAssistantState.initial();
    notifyListeners();
  }

  /// Hata sonrası tekrar dene — state'i loading'e çek
  void retry() {
    if (_state is! AiError) return;
    final msgs = _state.messages;
    _state = AiAssistantState.loaded(messages: msgs);
    notifyListeners();
  }

  // ── Öneri Sorular ─────────────────────────────────────────────────────────

  List<String> get suggestions => switch (_mode) {
    'budget_audit' => [
      'Bu ay nerede çok para harcadım?',
      'Hangi aboneliklerimi iptal etmeliyim?',
      'Yeme-içme bütçemi nasıl optimize ederim?',
    ],
    'portfolio_advisor' => [
      'Portföyüm risk profilime uygun mu?',
      'Bu ay 5.000 TL nereye yatırım yapayım?',
      'Altın ağırlığımı artırmalı mıyım?',
    ],
    'goal_tracker' => [
      'Hedetime ne zaman ulaşabilirim?',
      'Birikim hızımı artırmak için 3 somut öneri ver.',
      'Hedefimden ne kadar gerideyim?',
    ],
    _ => [
      'TL\'yi enflasyona karşı nasıl koruyabilirim?',
      'TEFAS fon seçiminde nelere dikkat etmeliyim?',
      'Acil fon ne kadar olmalı?',
    ],
  };
}
