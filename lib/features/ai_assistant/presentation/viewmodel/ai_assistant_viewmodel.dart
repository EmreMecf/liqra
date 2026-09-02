import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/result.dart';
import '../../domain/assistant_context.dart';
import '../../domain/assistant_insight.dart';
import '../../domain/assistant_notifier.dart';
import '../../domain/campaign_matcher.dart';
import '../../domain/entities/ai_message_entity.dart';
import '../../domain/savings_plan.dart';
import '../../domain/usecases/assistant_tasks_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import 'ai_assistant_state.dart';

/// AI Asistan ViewModel.
///
/// Sohbetin yanı sıra asistanın görevlerini de yürütür: derin hisse analizi,
/// harcama denetimi, birikim planı ve kampanya önerisi. İçgörüler
/// [InsightEngine] tarafından modele hiç gitmeden üretilir.
class AiAssistantViewModel extends ChangeNotifier {
  final SendMessageUseCase _sendMessage;
  final AnalyzeStockUseCase _analyzeStock;
  final AuditSpendingUseCase _auditSpending;
  final BuildSavingsPlanUseCase _buildPlan;
  final RecommendCampaignsUseCase _recommendCampaigns;

  static const _uuid = Uuid();

  AiAssistantViewModel({
    required SendMessageUseCase sendMessage,
    required AnalyzeStockUseCase analyzeStock,
    required AuditSpendingUseCase auditSpending,
    required BuildSavingsPlanUseCase buildPlan,
    required RecommendCampaignsUseCase recommendCampaigns,
  })  : _sendMessage = sendMessage,
        _analyzeStock = analyzeStock,
        _auditSpending = auditSpending,
        _buildPlan = buildPlan,
        _recommendCampaigns = recommendCampaigns;

  // ── State ─────────────────────────────────────────────────────────────────

  AiAssistantState _state = const AiAssistantState.initial();
  AiAssistantState get state => _state;

  String _mode = 'budget_audit';
  String get mode => _mode;

  /// En son üretilen içgörüler — dashboard ve asistan ekranı bunu gösterir.
  List<AssistantInsight> _insights = const [];
  List<AssistantInsight> get insights => _insights;

  /// Son hesaplanan birikim planı (varsa).
  SavingsPlan? _plan;
  SavingsPlan? get savingsPlan => _plan;

  /// Son kampanya eşleşmeleri.
  List<CampaignMatch> _campaignMatches = const [];
  List<CampaignMatch> get campaignMatches => _campaignMatches;

  bool _busy = false;
  bool get isBusy => _busy;

  // ── Mod yönetimi ──────────────────────────────────────────────────────────

  void setMode(String mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  static const modeLabels = {
    'budget_audit': 'Bütçe Denetimi',
    'portfolio_advisor': 'Yatırım Analizi',
    'goal_tracker': 'Hedef & Birikim',
    'free_chat': 'Serbest Sohbet',
  };

  static const modeIcons = {
    'budget_audit': '📊',
    'portfolio_advisor': '📈',
    'goal_tracker': '🎯',
    'free_chat': '💬',
  };

  // ── İçgörüler (AI çağrısı yok) ────────────────────────────────────────────

  /// Bağlamdan içgörüleri üretir ve gerekiyorsa bildirim gönderir.
  ///
  /// Uygulama açılışında ve cüzdan/harcama değiştiğinde çağrılır. Ucuzdur:
  /// hiçbir ağ isteği yapmaz, bildirim dışında yan etkisi yoktur.
  Future<void> refreshInsights(
    AssistantContext context, {
    Set<String> userBanks = const {},
    bool notify = true,
  }) async {
    _insights = InsightEngine.analyze(context);
    _campaignMatches = CampaignMatcher.match(context, userBanks: userBanks);
    notifyListeners();

    if (notify) {
      await AssistantNotifier.instance.run(
        context: context,
        userBanks: userBanks,
      );
    }
  }

  /// En acil birkaç içgörü — dashboard kartı için.
  List<AssistantInsight> topInsights([int count = 3]) =>
      _insights.take(count).toList();

  // ── Sohbet ────────────────────────────────────────────────────────────────

  Future<void> sendMessage({
    required String text,
    required AssistantContext context,
  }) async {
    if (text.trim().isEmpty) return;

    final userMessage = AiMessageEntity(
      id: _uuid.v4(),
      role: AiRole.user,
      content: text.trim(),
      timestamp: DateTime.now(),
      mode: _mode,
    );

    final messages = [..._state.messages, userMessage];
    _state = AiAssistantState.loading(messages: messages);
    notifyListeners();

    // Geçmiş: son 10 mesaj (token tasarrufu). Az önce eklenen kullanıcı
    // mesajı hariç tutulur — o ayrıca gönderiliyor.
    final history = messages
        .sublist(0, messages.length - 1)
        .reversed
        .take(10)
        .toList()
        .reversed
        .map((m) => {'role': m.role.value, 'content': m.content})
        .toList();

    final result = await _sendMessage(
      message: text.trim(),
      mode: _mode,
      context: context,
      history: history,
    );

    result.when(
      success: (response) =>
          _state = AiAssistantState.loaded(messages: [...messages, response]),
      failure: (failure) => _state = AiAssistantState.error(
        message: failure.message,
        previousMessages: messages,
      ),
    );
    notifyListeners();
  }

  /// Asistanın ürettiği bir metni sohbete asistan mesajı olarak ekler.
  void _appendAssistantMessage(String content) {
    final message = AiMessageEntity(
      id: _uuid.v4(),
      role: AiRole.assistant,
      content: content,
      timestamp: DateTime.now(),
      mode: _mode,
    );
    _state = AiAssistantState.loaded(
      messages: [..._state.messages, message],
    );
  }

  /// Kullanıcı adına bir istek satırı ekler — görev sonuçları sohbette
  /// bağlamsız görünmesin diye.
  void _appendUserPrompt(String text) {
    _state = AiAssistantState.loaded(messages: [
      ..._state.messages,
      AiMessageEntity(
        id: _uuid.v4(),
        role: AiRole.user,
        content: text,
        timestamp: DateTime.now(),
        mode: _mode,
      ),
    ]);
  }

  // ── Görevler ──────────────────────────────────────────────────────────────

  /// Derin hisse analizi. Sonuç sohbete yazılır ve ayrıca döner.
  Future<String?> analyzeStock({
    required String symbol,
    required String companyName,
    required AssistantContext context,
  }) async {
    return _runTask(
      prompt: '$symbol analizi yap',
      task: () => _analyzeStock(
        symbol: symbol,
        companyName: companyName,
        context: context,
      ),
    );
  }

  /// Harcama denetimi raporu.
  Future<String?> auditSpending(AssistantContext context) => _runTask(
        prompt: 'Bu ayki harcamalarımı denetle',
        task: () => _auditSpending(context),
      );

  /// Birikim planı. Plan rakamları model çağrısı düşse bile hesaplanır.
  Future<SavingsPlan?> createSavingsPlan({
    required AssistantContext context,
    required String goalTitle,
    required double targetAmount,
    required double currentAmount,
    required DateTime deadline,
  }) async {
    _appendUserPrompt('$goalTitle için birikim planı oluştur');
    _busy = true;
    _state = AiAssistantState.loading(messages: _state.messages);
    notifyListeners();

    final result = await _buildPlan(
      context: context,
      goalTitle: goalTitle,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      deadline: deadline,
    );

    _busy = false;

    return result.when(
      success: (data) {
        _plan = data.plan;
        _appendAssistantMessage(
          data.narrative.isNotEmpty
              ? data.narrative
              // Model düştü ama hesap geçerli — kullanıcı rakamları görsün.
              : '${data.plan.toPromptBlock()}\n\n'
                  "_(Liqra'nın yorumu alınamadı — rakamlar hesaplandı.)_",
        );
        notifyListeners();
        return data.plan;
      },
      failure: (f) {
        _state = AiAssistantState.error(
          message: f.message,
          previousMessages: _state.messages,
        );
        notifyListeners();
        return null;
      },
    );
  }

  /// Kampanya önerisi.
  Future<String?> recommendCampaigns({
    required AssistantContext context,
    Set<String> userBanks = const {},
  }) async {
    _appendUserPrompt('Bana uygun kampanyaları göster');
    _busy = true;
    _state = AiAssistantState.loading(messages: _state.messages);
    notifyListeners();

    final result = await _recommendCampaigns(
      context: context,
      userBanks: userBanks,
    );
    _busy = false;

    return result.when(
      success: (data) {
        _campaignMatches = data.matches;
        _appendAssistantMessage(
          data.narrative.isNotEmpty
              ? data.narrative
              : data.matches.isEmpty
                  ? 'Harcama alışkanlığına uyan bir kampanya bulamadım.'
                  : _fallbackCampaignText(data.matches),
        );
        notifyListeners();
        return data.narrative;
      },
      failure: (f) {
        _state = AiAssistantState.error(
          message: f.message,
          previousMessages: _state.messages,
        );
        notifyListeners();
        return null;
      },
    );
  }

  String _fallbackCampaignText(List<CampaignMatch> matches) {
    final rows = matches
        .take(5)
        .map((m) => '- **${m.offer.bank}** — ${m.offer.title}\n'
            '  _Sana uygun çünkü ${m.reason}._')
        .join('\n');
    return 'Sana uyan kampanyalar:\n\n$rows';
  }

  /// Ortak görev akışı: kullanıcı satırı ekle → yükleniyor → sonuç veya hata.
  Future<String?> _runTask({
    required String prompt,
    required Future<Result<String>> Function() task,
  }) async {
    _appendUserPrompt(prompt);
    _busy = true;
    _state = AiAssistantState.loading(messages: _state.messages);
    notifyListeners();

    final result = await task();
    _busy = false;

    return result.when(
      success: (content) {
        _appendAssistantMessage(content);
        notifyListeners();
        return content;
      },
      failure: (failure) {
        _state = AiAssistantState.error(
          message: failure.message,
          previousMessages: _state.messages,
        );
        notifyListeners();
        return null;
      },
    );
  }

  // ── Geçmiş ────────────────────────────────────────────────────────────────

  void clearHistory() {
    _state = const AiAssistantState.initial();
    _plan = null;
    notifyListeners();
  }

  void retry() {
    if (_state is! AiError) return;
    _state = AiAssistantState.loaded(messages: _state.messages);
    notifyListeners();
  }

  // ── Öneri sorular ─────────────────────────────────────────────────────────

  List<String> get suggestions => switch (_mode) {
        'budget_audit' => [
            'Bu ay nerede fazla harcadım?',
            'Geçen aya göre ne değişti?',
            'Hangi aboneliklerimi iptal etmeliyim?',
          ],
        'portfolio_advisor' => [
            'Portföyüm risk profilime uygun mu?',
            'Serbest nakdimi nereye yatırmalıyım?',
            'Hangi pozisyonum riskli?',
          ],
        'goal_tracker' => [
            'Hedefime yetişiyor muyum?',
            'Bana bir birikim planı çıkar.',
            'Acil fonum yeterli mi?',
          ],
        _ => [
            'Kredi kartı borcumu nasıl kapatırım?',
            'Enflasyona karşı ne yapmalıyım?',
            'Acil fon ne kadar olmalı?',
          ],
      };
}
