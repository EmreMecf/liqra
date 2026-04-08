import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/financial_account_entity.dart';
import '../viewmodels/accounts_viewmodel.dart';
import '../viewmodels/accounts_state.dart';
import '../widgets/add_account_sheet.dart';
import '../widgets/bank_account_card.dart';
import '../widgets/credit_card_widget.dart';
import '../widgets/account_transaction_tile.dart';
import 'account_detail_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountsViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Consumer<AccountsViewModel>(
        builder: (context, vm, _) {
          final state = vm.state;
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Başlık ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildHeader(vm),
              ),

              if (state is AccountsLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.accentGreen, strokeWidth: 2),
                  ),
                )
              else if (state is AccountsError)
                SliverFillRemaining(
                  child: _ErrorView(
                      message: state.message, onRetry: vm.load),
                )
              else if (state is AccountsLoaded) ...[
                // ── 1. Net Servet ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _NetWorthCard(vm: vm)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.06, end: 0),
                ),

                // ── 2. Kredi Sağlığı + Özet ───────────────────────────────
                if (vm.creditCards.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _CreditHealthRow(cards: vm.creditCards)
                        .animate()
                        .fadeIn(delay: 80.ms, duration: 350.ms),
                  ),

                // ── 3. Akıllı Uyarılar ────────────────────────────────────
                SliverToBoxAdapter(
                  child: _SmartAlerts(vm: vm)
                      .animate()
                      .fadeIn(delay: 120.ms, duration: 350.ms),
                ),

                // ── 4. Ödeme Takvimi ──────────────────────────────────────
                if (vm.creditCards.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _PaymentCalendar(cards: vm.creditCards)
                        .animate()
                        .fadeIn(delay: 160.ms, duration: 350.ms),
                  ),

                // ── 5. Banka Hesapları ─────────────────────────────────────
                if (vm.bankAccounts.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                        title: 'Banka Hesapları',
                        count: vm.bankAccounts.length),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 170,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: vm.bankAccounts.length,
                        itemBuilder: (_, i) {
                          final acc = vm.bankAccounts[i];
                          return BankAccountCard(
                            account: acc,
                            onTap: () => _openDetail(acc),
                            onDelete: () =>
                                _confirmDelete(acc.id, acc.name),
                          )
                              .animate(delay: (i * 70).ms)
                              .fadeIn()
                              .slideX(begin: 0.12, end: 0);
                        },
                      ),
                    ),
                  ),
                ],

                // ── 6. Kredi Kartları ──────────────────────────────────────
                if (vm.creditCards.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                        title: 'Kredi Kartları',
                        count: vm.creditCards.length),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 300,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: vm.creditCards.length,
                        itemBuilder: (_, i) {
                          final card = vm.creditCards[i];
                          return CreditCardWidget(
                            card: card,
                            onTap: () => _openDetail(card),
                            onDelete: () =>
                                _confirmDelete(card.id, card.name),
                          )
                              .animate(delay: (i * 70).ms)
                              .fadeIn()
                              .slideX(begin: 0.12, end: 0);
                        },
                      ),
                    ),
                  ),
                ],

                // ── Boş durum ─────────────────────────────────────────────
                if (vm.accounts.isEmpty)
                  SliverToBoxAdapter(
                    child: _EmptyState(
                        onAdd: () => showAddAccountSheet(context)),
                  ),

                // ── 7. Son İşlemler ───────────────────────────────────────
                if (vm.recentTransactions.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                        title: 'Son İşlemler', count: null),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => AccountTransactionTile(
                                tx: vm.recentTransactions[i])
                            .animate(delay: (i * 35).ms)
                            .fadeIn(duration: 280.ms),
                        childCount: vm.recentTransactions.length,
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: _AddFab(
          onTap: () => showAddAccountSheet(context)),
    );
  }

  Widget _buildHeader(AccountsViewModel vm) {
    return Container(
      color: AppColors.bgPrimary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Finansal Merkez', style: AppTypography.headlineL),
          GestureDetector(
            onTap: () => showAddAccountSheet(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.accentGreen.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.add,
                  color: AppColors.accentGreen, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(FinancialAccountEntity account) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AccountDetailScreen(account: account)),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hesabı Sil', style: AppTypography.headlineS),
        content: Text('$name hesabını ve tüm işlemleri silmek istiyor musun?',
            style: AppTypography.bodyM
                .copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AccountsViewModel>().deleteAccount(id);
            },
            child: const Text('Sil',
                style: TextStyle(color: AppColors.accentRed)),
          ),
        ],
      ),
    );
  }
}

// ─── 1. Net Servet Kartı ──────────────────────────────────────────────────────

class _NetWorthCard extends StatelessWidget {
  final AccountsViewModel vm;
  const _NetWorthCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final totalAssets = vm.totalBankBalance;
    final totalDebt   = vm.totalStatementDebt;
    final netWorth    = totalAssets - totalDebt;
    final isPositive  = netWorth >= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPositive
              ? [const Color(0xFF0D2010), const Color(0xFF071510)]
              : [const Color(0xFF201008), const Color(0xFF150705)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: (isPositive ? AppColors.accentGreen : AppColors.accentRed)
              .withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? AppColors.accentGreen : AppColors.accentRed)
                .withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Net Servет',
                style: AppTypography.labelS.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive
                          ? AppColors.accentGreen
                          : AppColors.accentRed)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 12,
                      color: isPositive
                          ? AppColors.accentGreen
                          : AppColors.accentRed,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPositive ? 'Pozitif' : 'Negatif',
                      style: AppTypography.capsLabel.copyWith(
                        color: isPositive
                            ? AppColors.accentGreen
                            : AppColors.accentRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            Formatters.currency(netWorth.abs()),
            style: GoogleFonts.dmMono(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: isPositive
                  ? AppColors.accentGreen
                  : AppColors.accentRed,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Banka bakiyesi eksi kredi kartı borcu',
            style: AppTypography.bodyS
                .copyWith(color: AppColors.textDisabled),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _NetWorthStat(
                  label: 'Toplam Varlık',
                  value: Formatters.currency(totalAssets),
                  color: AppColors.accentGreen,
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              Container(
                  width: 1, height: 36, color: AppColors.borderSubtle),
              Expanded(
                child: _NetWorthStat(
                  label: 'Kredi Borcu',
                  value: Formatters.currency(totalDebt),
                  color: AppColors.accentRed,
                  icon: Icons.credit_card_outlined,
                  align: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetWorthStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final CrossAxisAlignment align;

  const _NetWorthStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: align == CrossAxisAlignment.start ? 0 : 16,
        right: align == CrossAxisAlignment.end ? 0 : 16,
      ),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment: align == CrossAxisAlignment.end
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 12, color: AppColors.textDisabled),
              const SizedBox(width: 4),
              Text(label,
                  style: AppTypography.labelS
                      .copyWith(color: AppColors.textDisabled)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.dmMono(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 2. Kredi Sağlığı Skoru ───────────────────────────────────────────────────

class _CreditHealthRow extends StatelessWidget {
  final List<CreditCardEntity> cards;
  const _CreditHealthRow({required this.cards});

  int _computeScore() {
    if (cards.isEmpty) return 100;
    final avgUsage = cards.fold(0.0, (s, c) => s + c.usagePercent) / cards.length;
    final overdueCount = cards.where((c) => c.isOverdue).length;
    final score = (100 - avgUsage * 80 - overdueCount * 15).clamp(0.0, 100.0);
    return score.round();
  }

  @override
  Widget build(BuildContext context) {
    final score    = _computeScore();
    final color    = score >= 75
        ? AppColors.accentGreen
        : score >= 45
            ? AppColors.accentAmber
            : AppColors.accentRed;
    final label    = score >= 75 ? 'Sağlıklı' : score >= 45 ? 'Orta' : 'Riskli';
    final totalAvail = cards.fold(0.0, (s, c) => s + c.availableLimit);
    final totalLimit = cards.fold(0.0, (s, c) => s + c.creditLimit);
    final totalUsed  = cards.fold(0.0, (s, c) => s + c.usedAmount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          // Skor gauge
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Kredi Sağlığı',
                          style: AppTypography.labelS
                              .copyWith(color: AppColors.textSecondary)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          label,
                          style: AppTypography.capsLabel
                              .copyWith(color: color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$score',
                        style: GoogleFonts.dmMono(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: color,
                          height: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 2),
                        child: Text('/100',
                            style: AppTypography.labelS
                                .copyWith(color: AppColors.textDisabled)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: score / 100,
                      backgroundColor: AppColors.bgTertiary,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Limit özeti
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Toplam Limit',
                      style: AppTypography.labelS
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text(
                    Formatters.currency(totalLimit),
                    style: GoogleFonts.dmMono(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _LimitRow(
                    label: 'Kullanılan',
                    value: totalUsed,
                    color: AppColors.accentAmber,
                  ),
                  const SizedBox(height: 4),
                  _LimitRow(
                    label: 'Boş',
                    value: totalAvail,
                    color: AppColors.accentGreen,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LimitRow extends StatelessWidget {
  final String label;
  final double value;
  final Color  color;
  const _LimitRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: AppTypography.labelS
                  .copyWith(color: AppColors.textDisabled)),
          const Spacer(),
          Text(
            Formatters.currency(value),
            style: GoogleFonts.dmMono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      );
}

// ─── 3. Akıllı Uyarılar ───────────────────────────────────────────────────────

class _SmartAlerts extends StatelessWidget {
  final AccountsViewModel vm;
  const _SmartAlerts({required this.vm});

  List<_Alert> _buildAlerts() {
    final alerts = <_Alert>[];

    // Kredi kartı ödeme uyarıları
    for (final card in vm.creditCards) {
      if (card.isOverdue) {
        alerts.add(_Alert(
          icon: Icons.warning_amber_rounded,
          color: AppColors.accentRed,
          title: '${card.name} süresi geçti',
          body: '${Formatters.currency(card.statementBalance)} ödemeniz gecikmiş.',
          priority: 0,
        ));
      } else if (card.isDueSoon) {
        alerts.add(_Alert(
          icon: Icons.schedule_rounded,
          color: AppColors.accentAmber,
          title: '${card.name} — ${card.daysUntilDue} gün kaldı',
          body: 'Minimum ödeme: ${Formatters.currency(card.minimumPayment)}',
          priority: 1,
        ));
      }
      // Yüksek kullanım uyarısı
      if (card.usagePercent > 0.80) {
        alerts.add(_Alert(
          icon: Icons.credit_card_off_outlined,
          color: AppColors.accentAmber,
          title: '${card.name} limiti dolmak üzere',
          body: '%${(card.usagePercent * 100).round()} kullanıldı — kredi skorunu etkiler.',
          priority: 2,
        ));
      }
    }

    // Banka bakiyesi düşük uyarısı
    if (vm.totalBankBalance < 1000 && vm.bankAccounts.isNotEmpty) {
      alerts.add(_Alert(
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.accentRed,
        title: 'Banka bakiyeniz düşük',
        body: 'Toplam ${Formatters.currency(vm.totalBankBalance)} kaldı.',
        priority: 1,
      ));
    }

    // Boş limit — acil fon bilgisi
    final totalAvail = vm.creditCards.fold(0.0, (s, c) => s + c.availableLimit);
    if (totalAvail > 5000 && vm.creditCards.isNotEmpty) {
      alerts.add(_Alert(
        icon: Icons.shield_outlined,
        color: AppColors.accentGreen,
        title: 'Acil fon kapasitesi',
        body: '${Formatters.currency(totalAvail)} boş limit acil durumda kullanılabilir.',
        priority: 3,
      ));
    }

    alerts.sort((a, b) => a.priority.compareTo(b.priority));
    return alerts.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _buildAlerts();
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Text('Akıllı Uyarılar', style: AppTypography.headlineS),
        ),
        ...alerts.asMap().entries.map(
          (e) => _AlertTile(alert: e.value)
              .animate(delay: Duration(milliseconds: e.key * 60))
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.04, end: 0),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Alert {
  final IconData icon;
  final Color    color;
  final String   title;
  final String   body;
  final int      priority;
  const _Alert({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.priority,
  });
}

class _AlertTile extends StatelessWidget {
  final _Alert alert;
  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: alert.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: alert.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: alert.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(alert.icon, color: alert.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title,
                    style: AppTypography.bodyS.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                Text(alert.body,
                    style: AppTypography.labelS
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 4. Ödeme Takvimi ─────────────────────────────────────────────────────────

class _PaymentCalendar extends StatelessWidget {
  final List<CreditCardEntity> cards;
  const _PaymentCalendar({required this.cards});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // sonraki 30 günde hangi günlerde ödeme/hesap kesim var?
    final paymentDays  = <int>{};  // ödeme günleri (paymentDueDay)
    final statementDays = <int>{}; // hesap kesim günleri

    for (final card in cards) {
      // Bu ay ve gelecek ayın ödeme günleri
      for (var offset = 0; offset <= 30; offset++) {
        final day = now.add(Duration(days: offset));
        if (day.day == card.paymentDueDay)     paymentDays.add(offset);
        if (day.day == card.statementClosingDay) statementDays.add(offset);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Text('Ödeme Takvimi', style: AppTypography.headlineS),
              const Spacer(),
              _Legend(color: AppColors.accentRed,   label: 'Ödeme'),
              const SizedBox(width: 12),
              _Legend(color: AppColors.accentAmber, label: 'Hesap kesim'),
            ],
          ),
        ),
        SizedBox(
          height: 74,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 30,
            itemBuilder: (ctx, i) {
              final day  = now.add(Duration(days: i));
              final isToday   = i == 0;
              final hasPayment = paymentDays.contains(i);
              final hasStmt   = statementDays.contains(i);

              return _CalendarDay(
                day:        day,
                isToday:    isToday,
                hasPayment: hasPayment,
                hasStatement: hasStmt,
                cards:      cards,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color  color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: AppTypography.labelS
                  .copyWith(color: AppColors.textDisabled)),
        ],
      );
}

class _CalendarDay extends StatelessWidget {
  final DateTime day;
  final bool     isToday;
  final bool     hasPayment;
  final bool     hasStatement;
  final List<CreditCardEntity> cards;

  const _CalendarDay({
    required this.day,
    required this.isToday,
    required this.hasPayment,
    required this.hasStatement,
    required this.cards,
  });

  static const _weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  Widget build(BuildContext context) {
    final hasEvent  = hasPayment || hasStatement;
    final eventColor = hasPayment ? AppColors.accentRed : AppColors.accentAmber;

    return Tooltip(
      message: hasPayment
          ? 'Ödeme günü — ${cards.where((c) => c.paymentDueDay == day.day).map((c) => c.name).join(', ')}'
          : hasStatement
              ? 'Hesap kesim — ${cards.where((c) => c.statementClosingDay == day.day).map((c) => c.name).join(', ')}'
              : '',
      child: Container(
        width: 48,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isToday
              ? AppColors.accentGreen.withValues(alpha: 0.12)
              : hasEvent
                  ? eventColor.withValues(alpha: 0.08)
                  : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday
                ? AppColors.accentGreen.withValues(alpha: 0.5)
                : hasEvent
                    ? eventColor.withValues(alpha: 0.3)
                    : AppColors.borderSubtle,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _weekdays[day.weekday - 1],
              style: AppTypography.capsLabel.copyWith(
                color: isToday
                    ? AppColors.accentGreen
                    : AppColors.textDisabled,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${day.day}',
              style: GoogleFonts.dmMono(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isToday
                    ? AppColors.accentGreen
                    : hasEvent
                        ? eventColor
                        : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            if (hasEvent)
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: eventColor,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

// ─── Yardımcı widget'lar ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int?   count;
  const _SectionHeader({required this.title, this.count});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Row(
          children: [
            Text(title, style: AppTypography.headlineS),
            if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: AppTypography.capsLabel
                      .copyWith(color: AppColors.textDisabled),
                ),
              ),
            ],
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.accentGreen.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.accentGreen, size: 30),
            ),
            const SizedBox(height: 20),
            Text('Hesabını Ekle', style: AppTypography.headlineS),
            const SizedBox(height: 10),
            Text(
              'Tüm banka hesaplarını ve kredi kartlarını\nbir arada gör. Net servetini hesapla.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyS
                  .copyWith(color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                foregroundColor: AppColors.bgPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text('Hesap Ekle',
                  style: AppTypography.button
                      .copyWith(color: AppColors.bgPrimary)),
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
              color: AppColors.textDisabled, size: 44),
          const SizedBox(height: 14),
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

class _AddFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AddFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.accentGreen,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGreen.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: AppColors.bgPrimary, size: 24),
      ),
    );
  }
}
