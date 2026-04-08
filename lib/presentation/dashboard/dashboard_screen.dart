import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/portfolio_model.dart';
import '../../data/providers/app_provider.dart';
import '../../features/dashboard/presentation/viewmodel/dashboard_viewmodel.dart';
import '../../features/portfolio/domain/entities/asset_entity.dart';
import '../../features/portfolio/presentation/viewmodel/portfolio_viewmodel.dart';
import '../../features/portfolio/presentation/viewmodel/portfolio_state.dart';
import '../main_scaffold.dart';
import '../widgets/app_card.dart';
import '../widgets/animated_counter.dart';
import '../widgets/delta_chip.dart';
import '../widgets/portfolio_donut_chart.dart';

/// Ana Ekran (Dashboard)
/// Kurumsal dark mode — veri yoğun ama nefes alan layout
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _lastIncome = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final income = context.read<AppProvider>().user.monthlyIncome;
    if (income != _lastIncome) {
      _lastIncome = income;
      // addPostFrameCallback ile build bitmeden önce setState çağrısını engelle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<DashboardViewModel>().load(userMonthlyIncome: income);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, DashboardViewModel>(
      builder: (context, provider, dashVm, _) {
        final user = provider.user;
        final goal = provider.primaryGoal;
        final portfolio = provider.portfolio;
        final netCash = provider.netCash;

        // ViewModel'den uyarı ve işlem bilgisi
        final dashState = dashVm.state;
        final hasWarning = dashState is DashboardLoaded && dashState.hasAiWarning;
        final warningMsg = dashState is DashboardLoaded ? dashState.aiWarningMessage : null;

        // Son işlemler: AppProvider stream'inden (Firestore real-time)
        final recentTxs = provider.transactions.take(5).toList();

        // Geçen aya göre net nakit delta
        final prevMonthDelta = dashState is DashboardLoaded ? dashState.prevMonthDelta : 0.0;

        // Aylık birikim kapasitesi (gelir - gider) — 0'dan küçükse 1 TL kullan
        final monthlySavings = (user.monthlyIncome - provider.monthlyExpenses).clamp(1.0, double.infinity);

        return Scaffold(
          backgroundColor: AppColors.bgPrimary,
          body: SafeArea(
            child: RefreshIndicator(
              color: AppColors.accentGreen,
              backgroundColor: AppColors.bgSecondary,
              onRefresh: () => dashVm.load(userMonthlyIncome: provider.user.monthlyIncome),
              child: CustomScrollView(
                slivers: [
                  // ── AppBar ────────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hoş geldin, ${user.name.split(' ').first}',
                                  style: AppTypography.headlineS,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  Formatters.monthYear(DateTime.now()),
                                  style: AppTypography.bodyS,
                                ),
                              ],
                            ),
                          ),
                          // Bildirim butonu
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.bgTertiary,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Net Nakit Kartı ────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Net Nakit', style: AppTypography.labelS.copyWith(
                                  letterSpacing: 1.2,
                                  color: AppColors.textSecondary,
                                )),
                                const Spacer(),
                                DeltaChip(value: prevMonthDelta),
                              ],
                            ),
                            const SizedBox(height: 8),
                            AnimatedCounter(
                              value: netCash,
                              style: GoogleFonts.dmMono(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                color: netCash >= 0 ? AppColors.textPrimary : AppColors.accentRed,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _incomeExpenseChip(
                                  '↑ ${Formatters.currency(provider.monthlyIncome)}',
                                  AppColors.accentGreen,
                                ),
                                const SizedBox(width: 12),
                                _incomeExpenseChip(
                                  '↓ ${Formatters.currency(provider.monthlyExpenses)}',
                                  AppColors.accentRed,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                    ),
                  ),

                  // ── Hedef Çubuğu ───────────────────────────────────────────
                  if (goal != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(goal.emoji ?? '🎯', style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(goal.title, style: AppTypography.labelM.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    )),
                                  ),
                                  Text(
                                    '%${goal.progressPercent.toStringAsFixed(0)}',
                                    style: GoogleFonts.dmMono(
                                      color: AppColors.accentGreen,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _AnimatedProgressBar(progress: goal.progress),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text(
                                    'Kalan: ${Formatters.currency(goal.remaining)}',
                                    style: AppTypography.labelS,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '~${goal.estimatedMonthsRemaining(monthlySavings).toStringAsFixed(1)} ay',
                                    style: AppTypography.labelS.copyWith(
                                      color: AppColors.accentAmber,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ).animate(delay: 80.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                      ),
                    ),

                  // ── Portföy Özeti (Glassmorphism) ──────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: _GlassmorphismPortfolioCard(portfolio: portfolio),
                    ).animate(delay: 160.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                  ),

                  // ── AI Uyarı Kartı (sadece gerçek uyarı varsa) ─────────────
                  if (hasWarning && warningMsg != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: _AiWarningCard(
                          message: warningMsg,
                          onTap: () => MainScaffold.switchTab(3),
                        ),
                      ).animate(delay: 240.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                    ),

                  // ── Son İşlemler ───────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Row(
                        children: [
                          Text('Son İşlemler', style: AppTypography.headlineS),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => MainScaffold.switchTab(1),
                            child: Text('Tümü →',
                              style: AppTypography.labelM.copyWith(color: AppColors.accentBlue)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        if (i >= recentTxs.length) return null;
                        return Padding(
                          padding: EdgeInsets.fromLTRB(20, 0, 20, i < recentTxs.length - 1 ? 8 : 24),
                          child: _TransactionTile(tx: recentTxs[i])
                              .animate(delay: (280 + i * 60).ms)
                              .fadeIn(duration: 300.ms)
                              .slideX(begin: 0.05, end: 0),
                        );
                      },
                      childCount: recentTxs.length,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _incomeExpenseChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmMono(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Animasyonlu Progress Bar ────────────────────────────────────────────────
class _AnimatedProgressBar extends StatelessWidget {
  final double progress;
  const _AnimatedProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Container(
                height: 8,
                width: constraints.maxWidth * value,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentGreen, Color(0xFF00F5A0)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGreen.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Glassmorphism Portföy Kartı ─────────────────────────────────────────────
class _GlassmorphismPortfolioCard extends StatelessWidget {
  final PortfolioModel portfolio;
  const _GlassmorphismPortfolioCard({required this.portfolio});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgSecondary.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.borderActive.withValues(alpha: 0.5),
                width: 0.5),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.bgSecondary,
                AppColors.bgTertiary.withValues(alpha: 0.6),
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Consumer<PortfolioViewModel>(
            builder: (_, vm, __) {
              final p      = vm.state.portfolio;
              final value  = p?.totalValue    ?? portfolio.totalValue;
              final gain   = p?.totalGainLoss ?? portfolio.totalGainLoss;
              final gainPct = p?.gainLossPercent ?? portfolio.totalGainLossPercent;
              final assets = p?.assets ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('PORTFÖY', style: AppTypography.labelS.copyWith(
                          letterSpacing: 1.5)),
                      const Spacer(),
                      DeltaChip(value: gainPct),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AnimatedCounter(
                        value: value,
                        style: GoogleFonts.dmMono(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          '${gain >= 0 ? "+" : ""}${gain.toStringAsFixed(0)} TL G/K',
                          style: AppTypography.labelS.copyWith(
                            color: gain >= 0
                                ? AppColors.accentGreen
                                : AppColors.accentRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (assets.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    PortfolioDonutChart(assets: assets, size: 140),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── AI Uyarı Kartı ───────────────────────────────────────────────────────────
class _AiWarningCard extends StatefulWidget {
  final String message;
  final VoidCallback onTap;
  const _AiWarningCard({required this.message, required this.onTap});

  @override
  State<_AiWarningCard> createState() => _AiWarningCardState();
}

class _AiWarningCardState extends State<_AiWarningCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accentRed.withOpacity(0.6), width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, __) => Opacity(
                opacity: _pulseAnimation.value,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accentRed.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy_outlined,
                      color: AppColors.accentRed, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Uyarısı', style: AppTypography.labelS.copyWith(
                    color: AppColors.accentRed,
                    letterSpacing: 0.8,
                  )),
                  const SizedBox(height: 3),
                  Text(
                    widget.message,
                    style: AppTypography.bodyM.copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── İşlem Satırı ─────────────────────────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(tx.category.icon, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.note ?? tx.category.label,
                  style: AppTypography.bodyM.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${tx.category.label} · ${Formatters.shortDate(tx.date)}',
                  style: AppTypography.labelS,
                ),
              ],
            ),
          ),
          Text(
            '${tx.isIncome ? "+" : "-"}${Formatters.currency(tx.amount)}',
            style: GoogleFonts.dmMono(
              color: tx.isIncome ? AppColors.accentGreen : AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
