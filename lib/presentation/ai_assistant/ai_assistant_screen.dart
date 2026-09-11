import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/investment_disclaimer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/constants/app_typography.dart';
import '../../features/ai_assistant/domain/entities/ai_message_entity.dart';
import '../../features/ai_assistant/presentation/viewmodel/ai_assistant_viewmodel.dart';
import '../../features/ai_assistant/presentation/viewmodel/ai_assistant_state.dart';
import '../../features/ai_assistant/presentation/assistant_context_builder.dart';
import '../../features/ai_assistant/presentation/widgets/assistant_action_bar.dart';
import '../../features/ai_assistant/presentation/widgets/insight_card.dart';

/// Liqra — asistanın sohbet ekranı.
///
/// Modlar: Bütçe Denetimi | Yatırım Analizi | Hedef & Birikim | Serbest Sohbet
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(AiAssistantViewModel vm) {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();

    // Asistan artık cüzdanı, portföyü, piyasayı, haberleri ve kampanyaları
    // birlikte görüyor — bağlam tek yerden kurulur.
    vm
        .sendMessage(
          text: text,
          context: AssistantContextBuilder.fromContext(context),
        )
        .then((_) => _scrollToBottom());

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AiAssistantViewModel>(
      builder: (context, vm, _) {
        final isLoading = vm.state is AiLoading;
        final messages  = vm.state.messages;
        final errorMsg  = vm.state is AiError
            ? (vm.state as AiError).message : null;

        return Scaffold(
          backgroundColor: AppColors.bgPrimary,
          body: SafeArea(
            child: Column(
              children: [
                // ── Başlık ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.accentPurple, AppColors.accentBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentPurple.withAlpha(80),
                              blurRadius: 14,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                        child: const Icon(Icons.auto_awesome,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Liqra', style: AppTypography.headlineS),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentGreen.withAlpha(20),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.accentGreen.withAlpha(50),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 5, height: 5,
                                        decoration: BoxDecoration(
                                          color: AppColors.accentGreen,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.accentGreen.withAlpha(120),
                                              blurRadius: 4,
                                            )
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text('Çevrimiçi',
                                          style: AppTypography.labelS.copyWith(
                                            color: AppColors.accentGreen,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          )),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Text('Gemini 2.0 Flash',
                                style: AppTypography.labelS.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                )),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showClearDialog(context, vm),
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppColors.bgTertiary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: const Icon(Icons.restart_alt_rounded,
                              color: AppColors.textSecondary, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Mod seçici ──────────────────────────────────────────────
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: AiAssistantViewModel.modeLabels.entries.map((entry) {
                      final isActive = vm.mode == entry.key;
                      return GestureDetector(
                        onTap: () => vm.setMode(entry.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.accentGreen.withAlpha(28)
                                : AppColors.bgSecondary,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.accentGreen.withAlpha(160)
                                  : AppColors.borderSubtle,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: AppColors.accentGreen.withAlpha(30),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Text(AiAssistantViewModel.modeIcons[entry.key]!,
                                  style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 5),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 220),
                                style: AppTypography.labelS.copyWith(
                                  color: isActive
                                      ? AppColors.accentGreen
                                      : AppColors.textSecondary,
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                                child: Text(entry.value),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Hata banner ─────────────────────────────────────────────
                if (errorMsg != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.accentRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.accentRed.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_rounded,
                            color: AppColors.accentRed, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(errorMsg,
                              style: AppTypography.bodyS.copyWith(
                                color: AppColors.accentRed,
                              )),
                        ),
                        GestureDetector(
                          onTap: vm.retry,
                          child: Text('Tekrar dene',
                              style: AppTypography.labelS.copyWith(
                                color: AppColors.accentRed,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),

                // ── Tek dokunuşluk görevler ─────────────────────────────────
                AssistantActionBar(vm: vm),

                // ── Mesaj listesi ───────────────────────────────────────────
                Expanded(
                  child: messages.isEmpty
                      ? _buildEmptyState(vm)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: messages.length + (isLoading ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (isLoading && i == messages.length) {
                              return const _TypingIndicator();
                            }
                            final msg = messages[i];
                            return _MessageBubble(
                              content: msg.content,
                              isUser: msg.role == AiRole.user,
                            );
                          },
                        ),
                ),

                // Asistan yatırım yorumu yapıyor; uyarı her zaman görünür.
                if (messages.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: InvestmentDisclaimer(),
                  ),

                // ── Giriş alanı ─────────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderActive),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          style: GoogleFonts.outfit(
                            color: AppColors.textPrimary, fontSize: 15,
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(vm),
                          decoration: InputDecoration(
                            hintText: _getHintText(vm.mode),
                            hintStyle: GoogleFonts.outfit(
                              color: AppColors.textDisabled, fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: isLoading ? null : () => _sendMessage(vm),
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isLoading
                                  ? [AppColors.textDisabled, AppColors.textDisabled]
                                  : [AppColors.accentGreen, const Color(0xFF00B965)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.send_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(AiAssistantViewModel vm) {
    // İçgörüler modele hiç gitmeden üretilir; ekran açılır açılmaz hazırdır.
    final insights = vm.topInsights(3);

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 20),
      children: [
        if (insights.isNotEmpty) ...[
          InsightList(
            insights: insights,
            title: 'Bugün dikkatini çekenler',
            // Uygulama named route kullanmıyor; rota adı sekmeye çevrilir.
            // pushNamed çağrısı kayıtlı rota olmadığı için hata fırlatıyordu.
            onTap: (i) {
              if (i.route != AppRoutes.assistant) AppRoutes.go(i.route);
            },
          ),
          const SizedBox(height: 12),
        ],
        Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentPurple, AppColors.accentBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPurple.withAlpha(80),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: AppColors.accentBlue.withAlpha(40),
                  blurRadius: 36,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text('Merhaba, ben Liqra',
              style: AppTypography.headlineS, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Cüzdanını, harcamalarını ve portföyünü birlikte görüyorum. '
            'Sor ya da aşağıdaki görevlerden birini seç.',
            style: AppTypography.bodyM, textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ...vm.suggestions.map((s) => GestureDetector(
            onTap: () {
              _inputController.text = s;
              _sendMessage(vm);
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.keyboard_arrow_right_rounded,
                        color: AppColors.accentPurple, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s, style: AppTypography.bodyM.copyWith(
                    color: AppColors.textPrimary,
                  ))),
                ],
              ),
            ),
          )),
        ],
      ),
        ),
      ],
    );
  }

  String _getHintText(String mode) {
    switch (mode) {
      case 'budget_audit':      return "Liqra'ya harcamalarını sor...";
      case 'portfolio_advisor': return "Liqra'ya portföyünü sor...";
      case 'goal_tracker':      return "Liqra'ya hedefini sor...";
      default:                  return "Liqra'ya bir şey sor...";
    }
  }

  void _showClearDialog(BuildContext context, AiAssistantViewModel vm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: Text('Geçmişi Temizle', style: AppTypography.headlineS),
        content: Text('Tüm konuşma geçmişi silinecek.',
            style: AppTypography.bodyM),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: AppTypography.bodyM.copyWith(
              color: AppColors.textSecondary,
            )),
          ),
          TextButton(
            onPressed: () {
              vm.clearHistory();
              Navigator.pop(context);
            },
            child: Text('Temizle', style: AppTypography.bodyM.copyWith(
              color: AppColors.accentRed,
              fontWeight: FontWeight.w600,
            )),
          ),
        ],
      ),
    );
  }
}

// ── Mesaj Balonu ──────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  const _MessageBubble({required this.content, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentPurple, AppColors.accentBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentPurple.withAlpha(60),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.accentGreen.withValues(alpha: 0.15)
                    : AppColors.bgSecondary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser
                      ? AppColors.accentGreen.withValues(alpha: 0.3)
                      : AppColors.borderSubtle,
                  width: 0.5,
                ),
              ),
              child: isUser
                  ? Text(content, style: AppTypography.bodyM.copyWith(
                      color: AppColors.textPrimary,
                    ))
                  : MarkdownBody(
                      data: content,
                      styleSheet: MarkdownStyleSheet(
                        p: AppTypography.bodyM.copyWith(
                            color: AppColors.textPrimary),
                        strong: AppTypography.bodyM.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        h2: AppTypography.headlineS,
                        h3: AppTypography.labelM.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        tableHead: AppTypography.labelS.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        tableBody: AppTypography.bodyS.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        tableBorder: TableBorder.all(
                          color: AppColors.borderSubtle,
                          width: 0.5,
                        ),
                        blockquote: AppTypography.bodyM.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        blockquoteDecoration: const BoxDecoration(
                          color: AppColors.bgTertiary,
                          border: Border(
                            left: BorderSide(
                              color: AppColors.accentGreen, width: 3,
                            ),
                          ),
                        ),
                        listBullet: AppTypography.bodyM.copyWith(
                          color: AppColors.accentGreen,
                        ),
                        code: GoogleFonts.dmMono(
                          fontSize: 13,
                          color: AppColors.accentAmber,
                          backgroundColor: AppColors.bgTertiary,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: AppColors.bgTertiary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Yazıyor Göstergesi ────────────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true));

    _animations = _controllers.asMap().entries.map((e) {
      Future.delayed(Duration(milliseconds: e.key * 150), () {
        if (mounted) e.value.repeat(reverse: true);
      });
      return Tween<double>(begin: 0.3, end: 1.0).animate(e.value);
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentPurple, AppColors.accentBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPurple.withAlpha(60),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: AppColors.borderSubtle, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => AnimatedBuilder(
                animation: _animations[i],
                builder: (_, __) => Container(
                  margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen
                        .withValues(alpha: _animations[i].value),
                    shape: BoxShape.circle,
                  ),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}
