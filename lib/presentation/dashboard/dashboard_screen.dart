import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/providers/app_provider.dart';
import '../../features/dashboard/presentation/viewmodel/dashboard_viewmodel.dart';
import '../../features/portfolio/domain/entities/asset_entity.dart';
import '../../features/portfolio/presentation/viewmodel/market_viewmodel.dart';
import '../../features/portfolio/presentation/viewmodel/portfolio_viewmodel.dart';
import '../../features/portfolio/presentation/viewmodel/portfolio_state.dart';
import '../main_scaffold.dart';
import '../widgets/animated_counter.dart';
import '../widgets/app_card.dart';
import '../widgets/delta_chip.dart';
import '../widgets/liqra_logo.dart';
import '../widgets/portfolio_donut_chart.dart';

/// Dashboard Ana Ekran — Premium tasarım, responsive web/mobil
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<DashboardViewModel>().load(userMonthlyIncome: income);
      });
    }
  }

  // ── Finansal sağlık skoru (0-100) ─────────────────────────────────────────
  int _healthScore(AppProvider provider, GoalModel? goal, PortfolioState pState) {
    double score = 0;
    // 1. Tasarruf oranı (0-40 puan)
    if (provider.monthlyIncome > 0) {
      final rate = provider.netCash / provider.monthlyIncome;
      score += (rate.clamp(0.0, 1.0) * 40);
    } else {
      score += 20; // gelir girilmemiş → tarafsız
    }
    // 2. Hedef ilerleme (0-30 puan)
    if (goal != null) {
      score += (goal.progressPercent.clamp(0, 100) / 100.0 * 30);
    } else {
      score += 15; // hedef yok → tarafsız
    }
    // 3. Portföy sağlığı (0-30 puan)
    final port = pState.portfolio;
    if (port != null && port.totalValue > 0) {
      final pct = port.gainLossPercent.clamp(-20.0, 20.0);
      score += (pct / 20.0 * 15) + 15;
    } else {
      score += 15; // portföy yok → tarafsız
    }
    return score.clamp(0, 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Consumer3<AppProvider, DashboardViewModel, PortfolioViewModel>(
      builder: (context, provider, dashVm, portVm, _) {
        final user     = provider.user;
        final goal     = provider.primaryGoal;
        final netCash  = provider.netCash;
        final dashState = dashVm.state;
        final hasWarning = dashState is DashboardLoaded && dashState.hasAiWarning;
        final warningMsg = dashState is DashboardLoaded ? dashState.aiWarningMessage : null;
        final recentTxs  = provider.transactions.take(5).toList();
        final prevDelta   = dashState is DashboardLoaded ? dashState.prevMonthDelta : 0.0;
        final monthlySavings =
            (user.monthlyIncome - provider.monthlyExpenses).clamp(1.0, double.infinity);
        final score = _healthScore(provider, goal, portVm.state);

        if (isWide) {
          return _WebDashboard(
            provider: provider,
            dashVm: dashVm,
            portVm: portVm,
            user: user,
            goal: goal,
            netCash: netCash,
            hasWarning: hasWarning,
            warningMsg: warningMsg,
            recentTxs: recentTxs,
            prevDelta: prevDelta,
            monthlySavings: monthlySavings,
            score: score,
          );
        }

        return _MobileDashboard(
          provider: provider,
          dashVm: dashVm,
          portVm: portVm,
          user: user,
          goal: goal,
          netCash: netCash,
          hasWarning: hasWarning,
          warningMsg: warningMsg,
          recentTxs: recentTxs,
          prevDelta: prevDelta,
          monthlySavings: monthlySavings,
          score: score,
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MOBİL LAYOUT — tek sütun kaydırma
// ══════════════════════════════════════════════════════════════════════════════

class _MobileDashboard extends StatelessWidget {
  const _MobileDashboard({
    required this.provider,
    required this.dashVm,
    required this.portVm,
    required this.user,
    required this.goal,
    required this.netCash,
    required this.hasWarning,
    required this.warningMsg,
    required this.recentTxs,
    required this.prevDelta,
    required this.monthlySavings,
    required this.score,
  });

  final AppProvider provider;
  final DashboardViewModel dashVm;
  final PortfolioViewModel portVm;
  final dynamic user;
  final GoalModel? goal;
  final double netCash;
  final bool hasWarning;
  final String? warningMsg;
  final List<TransactionModel> recentTxs;
  final double prevDelta;
  final double monthlySavings;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accentGreen,
          backgroundColor: AppColors.bgSecondary,
          onRefresh: () => dashVm.load(userMonthlyIncome: provider.user.monthlyIncome),
          child: CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _DashboardHeader(user: user, score: score),
              ),

              // ── Hızlı İşlemler ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _QuickActionsRow(),
                ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.06, end: 0),
              ),

              // ── Piyasa Pulse ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Consumer<MarketViewModel>(
                    builder: (_, mvm, __) => _MarketPulseStrip(mvm: mvm),
                  ),
                ).animate(delay: 40.ms).fadeIn(duration: 250.ms),
              ),

              // ── Net Nakit ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: _NetCashCard(
                    netCash: netCash,
                    income: provider.monthlyIncome,
                    expenses: provider.monthlyExpenses,
                    prevDelta: prevDelta,
                  ),
                ).animate(delay: 60.ms).fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
              ),

              // ── Bütçe Durumu ─────────────────────────────────────────────
              if (provider.monthlyExpensesByCategory.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _BudgetCard(provider: provider),
                  ).animate(delay: 100.ms).fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
                ),

              // ── Hedef ────────────────────────────────────────────────────
              if (goal != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _GoalCard(
                      provider: provider,
                      goal: goal!,
                      monthlySavings: monthlySavings,
                    ),
                  ).animate(delay: 140.ms).fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
                ),

              // ── Portföy ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _PortfolioGlassCard(portVm: portVm),
                ).animate(delay: 180.ms).fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
              ),

              // ── AI Uyarı ─────────────────────────────────────────────────
              if (hasWarning && warningMsg != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _AiWarningCard(
                      message: warningMsg!,
                      onTap: () => MainScaffold.switchTab(4),
                    ),
                  ).animate(delay: 220.ms).fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
                ),

              // ── Son İşlemler başlık ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                  child: Row(
                    children: [
                      Text('Son İşlemler', style: AppTypography.headlineS),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => MainScaffold.switchTab(1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Tümü',
                                  style: AppTypography.labelS.copyWith(
                                      color: AppColors.accentBlue, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_forward_ios_rounded,
                                  color: AppColors.accentBlue, size: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── İşlem listesi ─────────────────────────────────────────────
              if (recentTxs.isEmpty)
                SliverToBoxAdapter(
                  child: _EmptyTransactions(),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      if (i >= recentTxs.length) return null;
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                            20, 0, 20, i < recentTxs.length - 1 ? 8 : 28),
                        child: _TransactionTile(tx: recentTxs[i])
                            .animate(delay: (260 + i * 50).ms)
                            .fadeIn(duration: 250.ms)
                            .slideX(begin: 0.04, end: 0),
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
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WEB LAYOUT — iki sütun grid
// ══════════════════════════════════════════════════════════════════════════════

class _WebDashboard extends StatelessWidget {
  const _WebDashboard({
    required this.provider,
    required this.dashVm,
    required this.portVm,
    required this.user,
    required this.goal,
    required this.netCash,
    required this.hasWarning,
    required this.warningMsg,
    required this.recentTxs,
    required this.prevDelta,
    required this.monthlySavings,
    required this.score,
  });

  final AppProvider provider;
  final DashboardViewModel dashVm;
  final PortfolioViewModel portVm;
  final dynamic user;
  final GoalModel? goal;
  final double netCash;
  final bool hasWarning;
  final String? warningMsg;
  final List<TransactionModel> recentTxs;
  final double prevDelta;
  final double monthlySavings;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sol sütun (60%) ──────────────────────────────────────────
            Expanded(
              flex: 60,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _DashboardHeader(user: user, score: score)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: _QuickActionsRow(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                      child: _NetCashCard(
                        netCash: netCash,
                        income: provider.monthlyIncome,
                        expenses: provider.monthlyExpenses,
                        prevDelta: prevDelta,
                      ),
                    ),
                  ),
                  if (provider.monthlyExpensesByCategory.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                        child: _BudgetCard(provider: provider),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
                      child: Row(
                        children: [
                          Text('Son İşlemler', style: AppTypography.headlineS),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => MainScaffold.switchTab(1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accentBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.accentBlue.withValues(alpha: 0.25)),
                              ),
                              child: Text('Tümü →',
                                  style: AppTypography.labelS.copyWith(
                                      color: AppColors.accentBlue,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (recentTxs.isEmpty)
                    SliverToBoxAdapter(child: _EmptyTransactions())
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          if (i >= recentTxs.length) return null;
                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                                24, 0, 24, i < recentTxs.length - 1 ? 8 : 28),
                            child: _TransactionTile(tx: recentTxs[i])
                                .animate(delay: (i * 40).ms)
                                .fadeIn(duration: 200.ms),
                          );
                        },
                        childCount: recentTxs.length,
                      ),
                    ),
                ],
              ),
            ),
            // Dikey ayraç
            Container(
                width: 1,
                color: AppColors.borderSubtle.withValues(alpha: 0.5)),
            // ── Sağ sütun (40%) ──────────────────────────────────────────
            Expanded(
              flex: 40,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: _HealthScoreCard(score: score),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
                      child: Consumer<MarketViewModel>(
                        builder: (_, mvm, __) => _MarketPulseStrip(mvm: mvm),
                      ),
                    ),
                  ),
                  if (goal != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                        child: _GoalCard(
                          provider: provider,
                          goal: goal!,
                          monthlySavings: monthlySavings,
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: _PortfolioGlassCard(portVm: portVm),
                    ),
                  ),
                  if (hasWarning && warningMsg != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                        child: _AiWarningCard(
                          message: warningMsg!,
                          onTap: () => MainScaffold.switchTab(4),
                        ),
                      ),
                    )
                  else
                    const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HEADER
// ══════════════════════════════════════════════════════════════════════════════

class _DashboardHeader extends StatelessWidget {
  final dynamic user;
  final int score;

  const _DashboardHeader({required this.user, required this.score});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final padding = isWide
        ? const EdgeInsets.fromLTRB(24, 20, 24, 0)
        : const EdgeInsets.fromLTRB(20, 16, 20, 0);

    return Padding(
      padding: padding,
      child: Row(
        children: [
          const LiqraLogoMark(size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoş geldin, ${(user.name as String).split(' ').first}',
                  style: AppTypography.headlineS,
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.monthYear(DateTime.now()),
                  style: AppTypography.labelS.copyWith(
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // Sağlık skoru badge (mobilde başlıkta göster)
          if (!isWide) ...[
            _ScoreBadge(score: score),
            const SizedBox(width: 8),
          ],
          // Bildirim
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                Positioned(
                  right: 9,
                  top: 9,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bgTertiary, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentGreen.withAlpha(120),
                          blurRadius: 4,
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// Küçük skor badge — header'da
class _ScoreBadge extends StatelessWidget {
  final int score;
  const _ScoreBadge({required this.score});

  Color get _color {
    if (score >= 80) return AppColors.accentGreen;
    if (score >= 60) return const Color(0xFF00C9B1);
    if (score >= 40) return AppColors.accentAmber;
    return AppColors.accentRed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, color: _color, size: 11),
          const SizedBox(width: 4),
          Text(
            '$score',
            style: GoogleFonts.dmMono(
              color: _color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FİNANSAL SAĞLIK SKORU KARTI (web sağ sütun için büyük versiyon)
// ══════════════════════════════════════════════════════════════════════════════

class _HealthScoreCard extends StatelessWidget {
  final int score;
  const _HealthScoreCard({required this.score});

  Color get _color {
    if (score >= 80) return AppColors.accentGreen;
    if (score >= 60) return const Color(0xFF00C9B1);
    if (score >= 40) return AppColors.accentAmber;
    return AppColors.accentRed;
  }

  String get _grade {
    if (score >= 80) return 'Mükemmel';
    if (score >= 60) return 'İyi';
    if (score >= 40) return 'Orta';
    return 'Dikkat!';
  }

  String get _tip {
    if (score >= 80) return 'Finansal sağlığın üst düzeyde. Böyle devam et!';
    if (score >= 60) return 'İyi gidiyorsun. Tasarruf oranını artırabilirsin.';
    if (score >= 40) return 'Bütçe dengesine dikkat et ve hedefine odaklan.';
    return 'Harcamaların gelirinizi aşıyor. Dikkat!';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('FİNANSAL SAĞLIK', style: AppTypography.labelS.copyWith(
                letterSpacing: 1.2,
                color: AppColors.textSecondary,
              )),
              const Spacer(),
              Icon(Icons.info_outline, size: 14, color: AppColors.textDisabled),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _HealthRing(score: score, size: 100),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _grade,
                      style: AppTypography.headlineM.copyWith(color: _color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tip,
                      style: AppTypography.bodyS.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Mini göstergeler
          Row(
            children: [
              _ScoreIndicator(label: 'Tasarruf', value: score >= 70 ? '✓' : '○', color: _color),
              const SizedBox(width: 12),
              _ScoreIndicator(label: 'Hedef', value: score >= 50 ? '✓' : '○', color: _color),
              const SizedBox(width: 12),
              _ScoreIndicator(label: 'Portföy', value: score >= 60 ? '✓' : '○', color: _color),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0);
  }
}

class _ScoreIndicator extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScoreIndicator({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isOk = value == '✓';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isOk
              ? color.withValues(alpha: 0.08)
              : AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isOk ? color.withValues(alpha: 0.2) : AppColors.borderSubtle,
          ),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: isOk ? color : AppColors.textDisabled, fontSize: 14)),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.labelS.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ── Skor Halkası ─────────────────────────────────────────────────────────────

class _HealthRing extends StatelessWidget {
  final int score;
  final double size;

  const _HealthRing({required this.score, required this.size});

  Color get _color {
    if (score >= 80) return AppColors.accentGreen;
    if (score >= 60) return const Color(0xFF00C9B1);
    if (score >= 40) return AppColors.accentAmber;
    return AppColors.accentRed;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score / 100.0),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(progress: value, color: _color),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: GoogleFonts.dmMono(
                      fontSize: size * 0.26,
                      fontWeight: FontWeight.w700,
                      color: _color,
                    ),
                  ),
                  Text(
                    'puan',
                    style: GoogleFonts.outfit(
                      fontSize: size * 0.11,
                      color: AppColors.textSecondary,
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
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;
    const stroke = 7.0;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.bgTertiary,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.solid, progress > 0 ? 1 : 0),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ══════════════════════════════════════════════════════════════════════════════
// HIZLI İŞLEMLER SATIRI
// ══════════════════════════════════════════════════════════════════════════════

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.add_circle_rounded,        'İşlem\nEkle',   AppColors.accentGreen,     0, () => MainScaffold.switchTab(1)),
      (Icons.candlestick_chart,         'Varlık\nEkle',  AppColors.accentAmber,     1, () => MainScaffold.switchTab(3)),
      (Icons.auto_awesome,              'AI\nAnaliz',    const Color(0xFF9B59B6),   2, () => MainScaffold.switchTab(4)),
      (Icons.show_chart_rounded,        'Piyasa',        AppColors.accentBlue,      3, () => MainScaffold.switchTab(3)),
    ];

    return Row(
      children: actions.asMap().entries.map((entry) {
        final i = entry.key;
        final a = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
            child: _QuickActionButton(
              icon: a.$1,
              label: a.$2,
              color: a.$3,
              onTap: a.$5,
            ).animate(delay: (i * 50).ms).fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0),
          ),
        );
      }).toList(),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PİYASA PULSE ŞERIDI
// ══════════════════════════════════════════════════════════════════════════════

class _MarketPulseStrip extends StatelessWidget {
  final MarketViewModel mvm;
  const _MarketPulseStrip({required this.mvm});

  @override
  Widget build(BuildContext context) {
    final items = mvm.state.marketData;
    final goldGram =
        mvm.goldPrices.where((g) => g.code == 'gram').firstOrNull;

    if (items.isEmpty && goldGram == null) return const SizedBox.shrink();

    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          ...items.take(5).map((item) => _PulseTicker(
                icon: item.icon,
                label: item.name,
                value: item.price.toStringAsFixed(
                    item.price < 100 ? 2 : 0),
                change: item.changePercent,
                currency: item.currency,
              )),
          if (goldGram != null)
            _PulseTicker(
              icon: '🥇',
              label: 'Gram Altın',
              value: goldGram.satis.toStringAsFixed(0),
              change: goldGram.degisim,
              currency: '₺',
            ),
        ],
      ),
    );
  }
}

class _PulseTicker extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final double change;
  final String currency;

  const _PulseTicker({
    required this.icon,
    required this.label,
    required this.value,
    required this.change,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = change >= 0;
    final changeColor =
        isPositive ? AppColors.accentGreen : AppColors.accentRed;

    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 5),
              Text(label,
                  style: AppTypography.labelS
                      .copyWith(color: AppColors.textSecondary, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.dmMono(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${isPositive ? "+" : ""}${change.toStringAsFixed(2)}%',
                style: GoogleFonts.dmMono(
                  color: changeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// NET NAKİT KARTI
// ══════════════════════════════════════════════════════════════════════════════

class _NetCashCard extends StatelessWidget {
  final double netCash;
  final double income;
  final double expenses;
  final double prevDelta;

  const _NetCashCard({
    required this.netCash,
    required this.income,
    required this.expenses,
    required this.prevDelta,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = netCash >= 0;
    final savingsRate = income > 0 ? (netCash / income * 100).clamp(0, 100) : 0.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NET NAKİT',
                    style: AppTypography.labelS.copyWith(
                      letterSpacing: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.monthYear(DateTime.now()),
                    style: AppTypography.labelS.copyWith(
                      color: AppColors.textDisabled,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              DeltaChip(value: prevDelta),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedCounter(
            value: netCash,
            style: GoogleFonts.dmMono(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: isPositive ? AppColors.textPrimary : AppColors.accentRed,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),

          // Gelir / Gider satırı
          Row(
            children: [
              Expanded(
                child: _CashFlow(
                  label: 'Gelir',
                  amount: income,
                  icon: Icons.arrow_upward_rounded,
                  color: AppColors.accentGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CashFlow(
                  label: 'Gider',
                  amount: expenses,
                  icon: Icons.arrow_downward_rounded,
                  color: AppColors.accentRed,
                ),
              ),
            ],
          ),

          // Tasarruf oranı bar
          if (income > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Text('Tasarruf oranı',
                    style: AppTypography.labelS
                        .copyWith(color: AppColors.textSecondary)),
                const Spacer(),
                Text(
                  '%${savingsRate.toStringAsFixed(1)}',
                  style: GoogleFonts.dmMono(
                    color: savingsRate > 20
                        ? AppColors.accentGreen
                        : AppColors.accentAmber,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: savingsRate / 100),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 4,
                  backgroundColor: AppColors.bgTertiary,
                  valueColor: AlwaysStoppedAnimation(
                    savingsRate > 20 ? AppColors.accentGreen : AppColors.accentAmber,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CashFlow extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _CashFlow({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.labelS
                        .copyWith(color: AppColors.textSecondary, fontSize: 10)),
                Text(
                  Formatters.compact(amount),
                  style: GoogleFonts.dmMono(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BÜTÇE DURUMU KARTI
// ══════════════════════════════════════════════════════════════════════════════

class _BudgetCard extends StatelessWidget {
  final AppProvider provider;
  const _BudgetCard({required this.provider});

  static const _catColors = <TransactionCategory, Color>{
    TransactionCategory.yemeicme:  Color(0xFFFF6B6B),
    TransactionCategory.market:    Color(0xFFFFBE76),
    TransactionCategory.ulasim:    Color(0xFF74B9FF),
    TransactionCategory.fatura:    Color(0xFFA29BFE),
    TransactionCategory.eglence:   Color(0xFFFF7675),
    TransactionCategory.saglik:    Color(0xFF55EFC4),
    TransactionCategory.giyim:     Color(0xFFFD79A8),
    TransactionCategory.teknoloji: Color(0xFF00CEC9),
    TransactionCategory.egitim:    Color(0xFFE17055),
    TransactionCategory.diger:     Color(0xFF636E72),
  };

  @override
  Widget build(BuildContext context) {
    final byCategory = provider.monthlyExpensesByCategory;
    if (byCategory.isEmpty) return const SizedBox.shrink();

    final total =
        byCategory.values.fold(0.0, (a, b) => a + b);
    if (total <= 0) return const SizedBox.shrink();

    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(4).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('BÜTÇE DURUMU', style: AppTypography.labelS.copyWith(
                letterSpacing: 1.2,
                color: AppColors.textSecondary,
              )),
              const Spacer(),
              Text(
                Formatters.compact(total),
                style: GoogleFonts.dmMono(
                  color: AppColors.accentRed,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...top.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final pct = e.value / total;
            final color = _catColors[e.key] ?? AppColors.textSecondary;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(e.key.icon, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(e.key.label,
                            style: AppTypography.labelS.copyWith(
                                color: AppColors.textPrimary)),
                      ),
                      Text(
                        Formatters.compact(e.value),
                        style: GoogleFonts.dmMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 36,
                        child: Text(
                          '%${(pct * 100).toStringAsFixed(0)}',
                          textAlign: TextAlign.end,
                          style: GoogleFonts.dmMono(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: pct),
                      duration: Duration(milliseconds: 900 + i * 100),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 5,
                        backgroundColor: AppColors.bgTertiary,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HEDEF KARTI
// ══════════════════════════════════════════════════════════════════════════════

class _GoalCard extends StatelessWidget {
  final AppProvider provider;
  final GoalModel goal;
  final double monthlySavings;

  const _GoalCard({
    required this.provider,
    required this.goal,
    required this.monthlySavings,
  });

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _QuickAddGoalSheet(provider: provider, goal: goal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthsLeft =
        goal.estimatedMonthsRemaining(monthlySavings);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accentAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.accentAmber.withValues(alpha: 0.25)),
                ),
                child: Center(
                  child: Text(goal.emoji ?? '🎯',
                      style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title,
                        style: AppTypography.labelM.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('Hedef birikimim',
                        style: AppTypography.labelS.copyWith(
                            color: AppColors.textDisabled, fontSize: 10)),
                  ],
                ),
              ),
              Text(
                '%${goal.progressPercent.toStringAsFixed(0)}',
                style: GoogleFonts.dmMono(
                  color: AppColors.accentAmber,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress bar
          LayoutBuilder(
            builder: (context, constraints) => Stack(
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
                  tween: Tween(begin: 0, end: goal.progress),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Container(
                    height: 8,
                    width: constraints.maxWidth * v,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accentAmber, Color(0xFFFFD700)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentAmber.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatters.compact(goal.currentAmount),
                    style: GoogleFonts.dmMono(
                      color: AppColors.accentAmber,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text('birikti',
                      style: AppTypography.labelS.copyWith(
                          color: AppColors.textDisabled, fontSize: 10)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.compact(goal.remaining),
                    style: GoogleFonts.dmMono(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text('kaldı · ~${monthsLeft.toStringAsFixed(1)} ay',
                      style: AppTypography.labelS.copyWith(
                          color: AppColors.textDisabled, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Para Ekle butonu
          GestureDetector(
            onTap: () => _showAddSheet(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentAmber, Color(0xFFE4B84A)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentAmber.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline, color: Colors.white, size: 15),
                  const SizedBox(width: 6),
                  Text('Para Ekle',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PORTFÖY GLASSMORPHISM KARTI
// ══════════════════════════════════════════════════════════════════════════════

class _PortfolioGlassCard extends StatelessWidget {
  final PortfolioViewModel portVm;
  const _PortfolioGlassCard({required this.portVm});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accentGreen.withValues(alpha: 0.18),
              width: 0.8,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.bgSecondary.withValues(alpha: 0.95),
                AppColors.bgTertiary.withValues(alpha: 0.7),
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Consumer<PortfolioViewModel>(
            builder: (_, vm, __) {
              final p       = vm.state.portfolio;
              final value   = p?.totalValue    ?? 0;
              final gain    = p?.totalGainLoss ?? 0;
              final gainPct = p?.gainLossPercent ?? 0;
              final assets  = p?.assets ?? [];
              final isPositive = gain >= 0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.accentGreen.withValues(alpha: 0.2)),
                        ),
                        child: Text('PORTFÖY',
                            style: AppTypography.labelS.copyWith(
                              letterSpacing: 1.5,
                              color: AppColors.accentGreen,
                              fontSize: 10,
                            )),
                      ),
                      const Spacer(),
                      DeltaChip(value: gainPct),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedCounter(
                    value: value,
                    style: GoogleFonts.dmMono(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        color: isPositive ? AppColors.accentGreen : AppColors.accentRed,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isPositive ? "+" : ""}${Formatters.compact(gain)} G/K',
                        style: AppTypography.labelS.copyWith(
                          color: isPositive ? AppColors.accentGreen : AppColors.accentRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (assets.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        PortfolioDonutChart(assets: assets, size: 110),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: assets
                                .take(3)
                                .map((a) => _AssetRow(asset: a))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => MainScaffold.switchTab(3),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.accentGreen.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_circle_outline,
                                color: AppColors.accentGreen, size: 15),
                            const SizedBox(width: 6),
                            Text('Varlık Ekle',
                                style: AppTypography.labelM.copyWith(
                                    color: AppColors.accentGreen)),
                          ],
                        ),
                      ),
                    ),
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

class _AssetRow extends StatelessWidget {
  final AssetEntity asset;
  const _AssetRow({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.chartColors[
                  asset.hashCode % AppColors.chartColors.length],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              asset.name,
              style: AppTypography.labelS.copyWith(
                  color: AppColors.textSecondary, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            Formatters.compact(asset.totalValue),
            style: GoogleFonts.dmMono(
              color: AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// AI UYARI KARTI
// ══════════════════════════════════════════════════════════════════════════════

class _AiWarningCard extends StatefulWidget {
  final String message;
  final VoidCallback onTap;

  const _AiWarningCard({required this.message, required this.onTap});

  @override
  State<_AiWarningCard> createState() => _AiWarningCardState();
}

class _AiWarningCardState extends State<_AiWarningCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
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
          border: Border.all(
              color: AppColors.accentRed.withValues(alpha: 0.5), width: 1),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accentRed.withValues(alpha: 0.05),
              AppColors.bgSecondary,
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Opacity(
                opacity: _pulse.value,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accentRed.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.accentRed.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: AppColors.accentRed, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Uyarısı',
                      style: AppTypography.labelS.copyWith(
                        color: AppColors.accentRed,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 3),
                  Text(
                    widget.message,
                    style: AppTypography.bodyM.copyWith(
                        color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.textSecondary, size: 14),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// İŞLEM SATIRI
// ══════════════════════════════════════════════════════════════════════════════

class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.isIncome;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isIncome
                  ? AppColors.accentGreen.withValues(alpha: 0.08)
                  : AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: isIncome
                    ? AppColors.accentGreen.withValues(alpha: 0.2)
                    : AppColors.borderSubtle,
              ),
            ),
            child: Center(
              child: Text(tx.category.icon,
                  style: const TextStyle(fontSize: 18)),
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
                  style: AppTypography.labelS.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? "+" : "-"}${Formatters.compact(tx.amount)}',
                style: GoogleFonts.dmMono(
                  color: isIncome
                      ? AppColors.accentGreen
                      : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isIncome)
                Text('Gelir',
                    style: AppTypography.labelS.copyWith(
                      color: AppColors.accentGreen.withValues(alpha: 0.7),
                      fontSize: 9,
                    ))
              else
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(tx.category.label,
                      style: AppTypography.labelS.copyWith(
                        color: AppColors.textDisabled,
                        fontSize: 9,
                      )),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BOŞ İŞLEM DURUMU
// ══════════════════════════════════════════════════════════════════════════════

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            const Text('💸', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text('Henüz işlem yok', style: AppTypography.bodyM),
            const SizedBox(height: 6),
            Text(
              'İlk işlemini eklemek için + butonuna bas',
              style: AppTypography.labelS
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => MainScaffold.switchTab(1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 11),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentGreen, Color(0xFF00C9B1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGreen.withAlpha(70),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'İşlem Ekle',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HEDEFE HIZLI PARA EKLE BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _QuickAddGoalSheet extends StatefulWidget {
  final AppProvider provider;
  final GoalModel goal;
  const _QuickAddGoalSheet({required this.provider, required this.goal});

  @override
  State<_QuickAddGoalSheet> createState() => _QuickAddGoalSheetState();
}

class _QuickAddGoalSheetState extends State<_QuickAddGoalSheet> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_ctrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;
    setState(() => _saving = true);
    final newCurrent = (widget.goal.currentAmount + amount)
        .clamp(0.0, widget.goal.targetAmount);
    final updated = widget.goal.copyWith(
      currentAmount: newCurrent,
      status: newCurrent >= widget.goal.targetAmount ? 'completed' : 'active',
    );
    await widget.provider.updateGoal(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(goal.emoji ?? '🎯',
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title, style: AppTypography.headlineS),
                    Text(
                      '${Formatters.currency(goal.currentAmount)} / ${Formatters.currency(goal.targetAmount)}',
                      style: AppTypography.labelS
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                '%${goal.progressPercent.toStringAsFixed(0)}',
                style: GoogleFonts.dmMono(
                  color: AppColors.accentAmber,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progress,
              backgroundColor: AppColors.bgTertiary,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.accentAmber),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 24),
          Text('Ne kadar eklemek istiyorsun?',
              style: AppTypography.labelM
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: GoogleFonts.dmMono(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: GoogleFonts.dmMono(
                  color: AppColors.textDisabled, fontSize: 26),
              suffixText: '₺',
              suffixStyle: GoogleFonts.dmMono(
                  color: AppColors.accentAmber, fontSize: 22),
              filled: true,
              fillColor: AppColors.bgTertiary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.accentAmber, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [500, 1000, 2000, 5000].asMap().entries.map((e) {
              final amt = e.value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: e.key < 3 ? 6 : 0),
                  child: GestureDetector(
                    onTap: () => _ctrl.text = amt.toString(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Text(
                        '+${amt >= 1000 ? '${amt ~/ 1000}B' : amt}',
                        textAlign: TextAlign.center,
                        style: AppTypography.labelS.copyWith(
                          color: AppColors.accentAmber,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentAmber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Hedefe Ekle',
                      style: GoogleFonts.outfit(
                          fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
