import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/formatters.dart';
import '../../features/subscriptions/domain/entities/subscription_entity.dart';
import '../../features/subscriptions/presentation/viewmodel/subscription_state.dart';
import '../../features/subscriptions/presentation/viewmodel/subscription_viewmodel.dart';

// ─── Abonelik ön ayarlı şablonlar ────────────────────────────────────────────

class _Preset {
  final String name;
  final String emoji;
  final int color;
  final String category;
  final double price;
  final BillingCycle cycle;
  const _Preset(this.name, this.emoji, this.color, this.category, this.price,
      [this.cycle = BillingCycle.monthly]);
}

const _presets = [
  _Preset('Netflix',           '🎬', 0xFFE50914, 'Eğlence',     199.90),
  _Preset('Spotify',           '🎵', 0xFF1DB954, 'Müzik',        49.99),
  _Preset('YouTube Premium',   '▶️', 0xFFFF0000, 'Eğlence',      89.99),
  _Preset('Disney+',           '🏰', 0xFF113CCF, 'Eğlence',     129.99),
  _Preset('Amazon Prime',      '📦', 0xFFFF9900, 'Alışveriş',    79.90),
  _Preset('Apple TV+',         '🍎', 0xFF888888, 'Eğlence',     129.99),
  _Preset('ChatGPT Plus',      '🤖', 0xFF10A37F, 'Yapay Zeka',  649.00),
  _Preset('Claude Pro',        '✦',  0xFFCC785C, 'Yapay Zeka',  649.00),
  _Preset('Notion',            '📝', 0xFF191919, 'Verimlilik',  199.00),
  _Preset('Microsoft 365',     '🪟', 0xFF0078D4, 'Verimlilik',  149.99),
  _Preset('Adobe CC',          '🅰️', 0xFFFF0000, 'Tasarım',     699.00),
  _Preset('Figma',             '🎨', 0xFFF24E1E, 'Tasarım',     399.00),
  _Preset('GitHub Copilot',    '💻', 0xFF24292F, 'Geliştirme',  399.00),
  _Preset('iCloud+',           '☁️', 0xFF3A8EF5, 'Depolama',     39.99),
  _Preset('Google One',        '🔵', 0xFF4285F4, 'Depolama',     59.99),
  _Preset('Dropbox',           '📂', 0xFF0061FF, 'Depolama',    139.99),
  _Preset('Özel',              '⭐', 0xFF0AFFE0, 'Diğer',          0.0),
];

// ─── Ana ekran ────────────────────────────────────────────────────────────────

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  String? _uid;
  String _selectedCategory = 'Tümü';

  @override
  void initState() {
    super.initState();
    _uid = AuthService.instance.userId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    if (_uid == null) return;
    context.read<SubscriptionViewModel>().load(_uid!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Consumer<SubscriptionViewModel>(
        builder: (context, vm, _) {
          final state = vm.state;
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Başlık ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _HeaderSection(
                  totalMonthly: vm.totalMonthly,
                  totalYearly:  vm.totalYearly,
                  activeCount:  vm.activeCount,
                ).animate().fadeIn(duration: 400.ms),
              ),

              if (state is SubscriptionLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accentGreen),
                  ),
                )
              else if (state is SubscriptionError)
                SliverFillRemaining(
                  child: _ErrorView(message: state.message, onRetry: _load),
                )
              else if (state is SubscriptionLoaded) ...[
                // ── Yaklaşan ödemeler ──────────────────────────────────────
                if (state.upcoming.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _UpcomingSection(items: state.upcoming)
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 350.ms),
                  ),

                // ── Kategori filtresi ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: _CategoryFilter(
                    subscriptions: state.active,
                    selected:      _selectedCategory,
                    onChanged: (c) => setState(() => _selectedCategory = c),
                  ).animate().fadeIn(delay: 150.ms, duration: 350.ms),
                ),

                // ── Aktif abonelikler ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Text(
                      'Aktif Abonelikler  (${state.activeCount})',
                      style: AppTypography.headlineS,
                    ),
                  ),
                ),
                if (state.active.isEmpty)
                  SliverToBoxAdapter(child: _EmptyActive(onAdd: _openAddSheet))
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: _filtered(state.active).length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final sub = _filtered(state.active)[i];
                        return _SubCard(
                          subscription: sub,
                          onToggle: (v) =>
                              vm.toggle(_uid!, sub.id, v),
                          onEdit: () => _openEditSheet(sub),
                          onDelete: () => _confirmDelete(sub),
                        ).animate(delay: Duration(milliseconds: 60 * i))
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.08, end: 0);
                      },
                    ),
                  ),

                // ── Pasif abonelikler ──────────────────────────────────────
                if (state.inactive.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                      child: Text(
                        'Pasif Abonelikler  (${state.inactive.length})',
                        style: AppTypography.headlineS.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: state.inactive.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final sub = state.inactive[i];
                        return _SubCard(
                          subscription: sub,
                          onToggle: (v) => vm.toggle(_uid!, sub.id, v),
                          onEdit: () => _openEditSheet(sub),
                          onDelete: () => _confirmDelete(sub),
                        );
                      },
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        backgroundColor: AppColors.accentGreen,
        foregroundColor: AppColors.bgPrimary,
        icon: const Icon(Icons.add),
        label: Text('Abonelik Ekle', style: AppTypography.button.copyWith(color: AppColors.bgPrimary)),
      ),
    );
  }

  List<SubscriptionEntity> _filtered(List<SubscriptionEntity> list) {
    if (_selectedCategory == 'Tümü') return list;
    return list.where((s) => s.category == _selectedCategory).toList();
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<SubscriptionViewModel>(),
        child: _AddSubscriptionSheet(userId: _uid ?? ''),
      ),
    );
  }

  void _openEditSheet(SubscriptionEntity sub) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<SubscriptionViewModel>(),
        child: _EditSubscriptionSheet(subscription: sub),
      ),
    );
  }

  void _confirmDelete(SubscriptionEntity sub) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: Text('Aboneliği Sil', style: AppTypography.headlineS),
        content: Text(
          '${sub.name} aboneliğini silmek istiyor musunuz?',
          style: AppTypography.bodyM.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SubscriptionViewModel>().delete(_uid!, sub.id);
            },
            child: const Text('Sil', style: TextStyle(color: AppColors.accentRed)),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  final double totalMonthly;
  final double totalYearly;
  final int activeCount;

  const _HeaderSection({
    required this.totalMonthly,
    required this.totalYearly,
    required this.activeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Abonelikler', style: AppTypography.headlineL),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accentGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.subscriptions_outlined,
                          color: AppColors.accentGreen, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '$activeCount aktif',
                        style: AppTypography.labelS.copyWith(
                          color: AppColors.accentGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Summary card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A2A1A), Color(0xFF0D1A1A)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.accentGreen.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aylık Toplam',
                          style: AppTypography.labelS.copyWith(
                            color: AppColors.textSecondary,
                          )),
                      const SizedBox(height: 6),
                      Text(
                        Formatters.currency(totalMonthly),
                        style: GoogleFonts.dmMono(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: AppColors.borderSubtle,
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Yıllık Toplam',
                        style: AppTypography.labelS.copyWith(
                          color: AppColors.textSecondary,
                        )),
                    const SizedBox(height: 6),
                    Text(
                      Formatters.currency(totalYearly),
                      style: GoogleFonts.dmMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Yaklaşan ödemeler ────────────────────────────────────────────────────────

class _UpcomingSection extends StatelessWidget {
  final List<SubscriptionEntity> items;
  const _UpcomingSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text('Yaklaşan Ödemeler', style: AppTypography.headlineS),
        ),
        SizedBox(
          height: 124,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) => _UpcomingCard(sub: items[i]),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final SubscriptionEntity sub;
  const _UpcomingCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final color  = Color(sub.colorValue);
    final days   = sub.daysUntilBilling;
    final isToday = sub.isDueToday;
    final isSoon  = sub.isExpiringSoon && !isToday;

    return Container(
      width: 148,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? AppColors.accentRed.withValues(alpha: 0.6)
              : isSoon
                  ? AppColors.accentAmber.withValues(alpha: 0.4)
                  : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _EmojiCircle(emoji: sub.emoji, color: color, size: 32),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isToday
                          ? AppColors.accentRed
                          : isSoon
                              ? AppColors.accentAmber
                              : AppColors.bgTertiary)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isToday ? 'Bugün' : '$days gün',
                  style: AppTypography.capsLabel.copyWith(
                    color: isToday
                        ? AppColors.accentRed
                        : isSoon
                            ? AppColors.accentAmber
                            : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sub.name,
            style: AppTypography.bodyS.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.currency(sub.price),
            style: GoogleFonts.dmMono(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Kategori filtresi ────────────────────────────────────────────────────────

class _CategoryFilter extends StatelessWidget {
  final List<SubscriptionEntity> subscriptions;
  final String selected;
  final ValueChanged<String> onChanged;

  const _CategoryFilter({
    required this.subscriptions,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cats = ['Tümü', ...{for (final s in subscriptions) s.category}];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final cat = cats[i];
          final active = cat == selected;
          return GestureDetector(
            onTap: () => onChanged(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.accentGreen
                    : AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? AppColors.accentGreen
                      : AppColors.borderSubtle,
                ),
              ),
              child: Text(
                cat,
                style: AppTypography.bodyS.copyWith(
                  color: active ? AppColors.bgPrimary : AppColors.textSecondary,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Abonelik Kartı ───────────────────────────────────────────────────────────

class _SubCard extends StatelessWidget {
  final SubscriptionEntity subscription;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubCard({
    required this.subscription,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sub   = subscription;
    final color = Color(sub.colorValue);
    final days  = sub.daysUntilBilling;

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sub.isActive && sub.isExpiringSoon
                ? AppColors.accentAmber.withValues(alpha: 0.4)
                : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            _EmojiCircle(emoji: sub.emoji, color: color, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sub.name, style: AppTypography.bodyM.copyWith(
                    fontWeight: FontWeight.w600,
                    color: sub.isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  )),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        sub.category,
                        style: AppTypography.labelS.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: AppColors.textDisabled,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (sub.isActive)
                        Text(
                          sub.isOverdue
                              ? 'Süresi geçti'
                              : sub.isDueToday
                                  ? 'Bugün ödenir'
                                  : '$days gün sonra',
                          style: AppTypography.labelS.copyWith(
                            color: sub.isOverdue
                                ? AppColors.accentRed
                                : sub.isExpiringSoon
                                    ? AppColors.accentAmber
                                    : AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.currency(sub.price),
                  style: GoogleFonts.dmMono(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: sub.isActive ? color : AppColors.textSecondary,
                  ),
                ),
                Text(
                  sub.billingCycle.shortLabel,
                  style: AppTypography.labelS.copyWith(
                    color: AppColors.textDisabled,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => onToggle(!sub.isActive),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 24,
                    decoration: BoxDecoration(
                      color: sub.isActive
                          ? AppColors.accentGreen.withValues(alpha: 0.2)
                          : AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sub.isActive
                            ? AppColors.accentGreen
                            : AppColors.borderSubtle,
                      ),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: sub.isActive
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: sub.isActive
                                ? AppColors.accentGreen
                                : AppColors.textDisabled,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Emoji Daire ──────────────────────────────────────────────────────────────

class _EmojiCircle extends StatelessWidget {
  final String emoji;
  final Color  color;
  final double size;
  const _EmojiCircle({required this.emoji, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.15),
        shape:        BoxShape.circle,
        border:       Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: size * 0.46),
        ),
      ),
    );
  }
}

// ─── Boş durum ────────────────────────────────────────────────────────────────

class _EmptyActive extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyActive({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            const Text('📱', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('Henüz abonelik yok', style: AppTypography.headlineS),
            const SizedBox(height: 8),
            Text(
              'Netflix, Spotify, YouTube gibi aylık aboneliklerinizi\ntakip etmek için ekleyin.',
              style: AppTypography.bodyS.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                foregroundColor: AppColors.bgPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text('İlk Aboneliği Ekle', style: AppTypography.button.copyWith(color: AppColors.bgPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded,
              color: AppColors.textDisabled, size: 48),
          const SizedBox(height: 16),
          Text(message,
              style: AppTypography.bodyM
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: const Text('Tekrar Dene',
                style: TextStyle(color: AppColors.accentGreen)),
          ),
        ],
      ),
    );
  }
}

// ─── Abonelik Ekleme Sheet ────────────────────────────────────────────────────

class _AddSubscriptionSheet extends StatefulWidget {
  final String userId;
  const _AddSubscriptionSheet({required this.userId});

  @override
  State<_AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends State<_AddSubscriptionSheet> {
  _Preset? _selectedPreset;
  bool _showForm = false;

  void _selectPreset(_Preset preset) {
    setState(() {
      _selectedPreset = preset;
      _showForm = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: _showForm && _selectedPreset != null
          ? _SubForm(
              userId:  widget.userId,
              preset:  _selectedPreset!,
              onBack:  () => setState(() => _showForm = false),
            )
          : _PresetGrid(onSelect: _selectPreset),
    );
  }
}

// ── Preset seçim ekranı ─────────────────────────────────────────────────────

class _PresetGrid extends StatelessWidget {
  final ValueChanged<_Preset> onSelect;
  const _PresetGrid({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('Abonelik Seç', style: AppTypography.headlineS),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close,
                      color: AppColors.textSecondary, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.82,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              itemCount: _presets.length,
              itemBuilder: (ctx, i) {
                final p = _presets[i];
                return GestureDetector(
                  onTap: () => onSelect(p),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _EmojiCircle(
                        emoji: p.emoji,
                        color: Color(p.color),
                        size: 54,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p.name,
                        style: AppTypography.labelS.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Form ekranı ─────────────────────────────────────────────────────────────

class _SubForm extends StatefulWidget {
  final String   userId;
  final _Preset  preset;
  final VoidCallback onBack;
  final SubscriptionEntity? editing;

  const _SubForm({
    required this.userId,
    required this.preset,
    required this.onBack,
    this.editing,
  });

  @override
  State<_SubForm> createState() => _SubFormState();
}

class _SubFormState extends State<_SubForm> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _noteCtrl;
  late BillingCycle _cycle;
  late DateTime _nextDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _nameCtrl  = TextEditingController(text: e?.name  ?? widget.preset.name);
    _priceCtrl = TextEditingController(
        text: (e?.price ?? widget.preset.price) > 0
            ? (e?.price ?? widget.preset.price).toStringAsFixed(2)
            : '');
    _noteCtrl  = TextEditingController(text: e?.note ?? '');
    _cycle     = e?.billingCycle    ?? widget.preset.cycle;
    _nextDate  = e?.nextBillingDate ?? _defaultNextDate();
  }

  DateTime _defaultNextDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, now.day);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.preset.color);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle + header
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                GestureDetector(
                  onTap: widget.onBack,
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textSecondary, size: 18),
                ),
                const SizedBox(width: 12),
                _EmojiCircle(emoji: widget.preset.emoji, color: color, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.editing != null ? 'Aboneliği Düzenle' : 'Abonelik Ekle',
                    style: AppTypography.headlineS,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Ad
            _Label('Abonelik Adı'),
            const SizedBox(height: 8),
            _Field(controller: _nameCtrl, hint: 'Netflix, Spotify...'),
            const SizedBox(height: 16),

            // Ücret
            _Label('Ücret (₺)'),
            const SizedBox(height: 8),
            _Field(
              controller: _priceCtrl,
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
            ),
            const SizedBox(height: 16),

            // Döngü
            _Label('Fatura Dönemi'),
            const SizedBox(height: 8),
            Row(
              children: BillingCycle.values.map((c) {
                final active = c == _cycle;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _cycle = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.accentGreen.withValues(alpha: 0.15)
                            : AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: active
                              ? AppColors.accentGreen
                              : AppColors.borderSubtle,
                        ),
                      ),
                      child: Text(
                        c.label,
                        textAlign: TextAlign.center,
                        style: AppTypography.labelS.copyWith(
                          color: active
                              ? AppColors.accentGreen
                              : AppColors.textSecondary,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Sonraki ödeme tarihi
            _Label('Sonraki Ödeme Tarihi'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      '${_nextDate.day.toString().padLeft(2, '0')}.${_nextDate.month.toString().padLeft(2, '0')}.${_nextDate.year}',
                      style: AppTypography.bodyM.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Not (opsiyonel)
            _Label('Not (opsiyonel)'),
            const SizedBox(height: 8),
            _Field(
              controller: _noteCtrl,
              hint: 'Aile planı, öğrenci indirimi...',
            ),
            const SizedBox(height: 28),

            // Kaydet
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: AppColors.bgPrimary,
                  disabledBackgroundColor:
                      AppColors.accentGreen.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.bgPrimary,
                        ),
                      )
                    : Text(
                        widget.editing != null ? 'Güncelle' : 'Ekle',
                        style: AppTypography.button
                            .copyWith(color: AppColors.bgPrimary),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentGreen,
            onPrimary: AppColors.bgPrimary,
            surface: AppColors.bgSecondary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _nextDate = picked);
  }

  Future<void> _save() async {
    final name  = _nameCtrl.text.trim();
    final price = double.tryParse(
            _priceCtrl.text.replaceAll(',', '.').replaceAll(' ', '')) ??
        0.0;
    if (name.isEmpty || price <= 0) return;

    setState(() => _saving = true);

    final vm  = context.read<SubscriptionViewModel>();
    bool ok;

    if (widget.editing != null) {
      final updated = widget.editing!.copyWith(
        name:            name,
        price:           price,
        billingCycle:    _cycle,
        nextBillingDate: _nextDate,
        note:            _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        colorValue:      widget.preset.color,
        emoji:           widget.preset.emoji,
        category:        widget.preset.category,
      );
      ok = await vm.update(updated);
    } else {
      final entity = SubscriptionEntity(
        id:              const Uuid().v4(),
        userId:          widget.userId,
        name:            name,
        price:           price,
        billingCycle:    _cycle,
        nextBillingDate: _nextDate,
        category:        widget.preset.category,
        colorValue:      widget.preset.color,
        emoji:           widget.preset.emoji,
        isActive:        true,
        note:            _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        createdAt:       DateTime.now(),
      );
      ok = await vm.add(entity);
    }

    if (mounted) {
      setState(() => _saving = false);
      if (ok) Navigator.pop(context);
    }
  }
}

// ─── Düzenleme Sheet ──────────────────────────────────────────────────────────

class _EditSubscriptionSheet extends StatelessWidget {
  final SubscriptionEntity subscription;
  const _EditSubscriptionSheet({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final preset = _presets.firstWhere(
      (p) => p.name == subscription.name,
      orElse: () => _Preset(
        subscription.name,
        subscription.emoji,
        subscription.colorValue,
        subscription.category,
        subscription.price,
        subscription.billingCycle,
      ),
    );
    return _SubForm(
      userId:  subscription.userId,
      preset:  preset,
      onBack:  () => Navigator.pop(context),
      editing: subscription,
    );
  }
}

// ─── Yardımcı widget'lar ──────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTypography.labelS.copyWith(color: AppColors.textSecondary),
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _Field({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller:       controller,
        keyboardType:     keyboardType,
        inputFormatters:  inputFormatters,
        style:            AppTypography.bodyM.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText:     hint,
          hintStyle:    AppTypography.bodyM.copyWith(color: AppColors.textDisabled),
          filled:       true,
          fillColor:    AppColors.bgTertiary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accentGreen, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}
