import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import '../../data/providers/app_provider.dart';
import '../../features/spending/presentation/viewmodel/spending_viewmodel.dart';
import '../widgets/app_card.dart';
import '../widgets/delta_chip.dart';
import '../ocr/ocr_screen.dart';

/// Harcama Yönetimi — 4 sekme: Özet | İşlemler | Sabit Kalemler | Ekle
class SpendingScreen extends StatefulWidget {
  const SpendingScreen({super.key});

  @override
  State<SpendingScreen> createState() => _SpendingScreenState();
}

class _SpendingScreenState extends State<SpendingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _touchedIndex = -1;
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _prevMonth() => setState(() =>
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));

  void _nextMonth() => setState(() =>
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1));

  bool get _isCurrentOrFuture {
    final now = DateTime.now();
    return _selectedMonth.year > now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month >= now.month);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Başlık + Ay navigasyonu
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 22),
                    color: AppColors.textSecondary,
                    onPressed: _prevMonth,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        Formatters.monthYear(_selectedMonth),
                        style: AppTypography.headlineS,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, size: 22,
                        color: _isCurrentOrFuture
                            ? AppColors.borderSubtle
                            : AppColors.textSecondary),
                    onPressed: _isCurrentOrFuture ? null : _nextMonth,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Sekme çubuğu
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(9),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTypography.labelS.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                unselectedLabelStyle: AppTypography.labelS,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Özet'),
                  Tab(text: 'İşlemler'),
                  Tab(text: 'Sabit'),
                  Tab(text: 'Ekle'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _SummaryTab(
                    touchedIndex: _touchedIndex,
                    onTouch: (i) => setState(() => _touchedIndex = i),
                    selectedMonth: _selectedMonth,
                  ),
                  _TransactionsTab(selectedMonth: _selectedMonth),
                  const _RecurringTab(),
                  _AddTab(onAdded: () => _tabController.animateTo(1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Özet Sekmesi ─────────────────────────────────────────────────────────────
class _SummaryTab extends StatelessWidget {
  final int touchedIndex;
  final ValueChanged<int> onTouch;
  final DateTime selectedMonth;
  const _SummaryTab({
    required this.touchedIndex,
    required this.onTouch,
    required this.selectedMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final year  = selectedMonth.year;
        final month = selectedMonth.month;
        final byCategory  = provider.expensesByCategoryForMonth(year, month);
        final totalExpense = provider.expensesForMonth(year, month);
        final entries = byCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Özet kart: tüm zamanlara ait toplamlar (ay filtresinden bağımsız)
        final allIncome   = provider.totalIncomeAllTime;
        final allExpense  = provider.totalExpenseAllTime;
        final totalBalance = provider.totalBalance;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            // ── Genel Özet Kartı (tüm zamanlar) ──────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Genel Özet', style: AppTypography.headlineS),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Tüm Zamanlar',
                          style: AppTypography.labelS.copyWith(
                            color: AppColors.accentBlue, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Toplam Gelir
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Toplam Gelir', style: AppTypography.labelS),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.currency(allIncome),
                              style: GoogleFonts.dmMono(
                                fontSize: 15, fontWeight: FontWeight.w600,
                                color: AppColors.accentGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Toplam Gider
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Toplam Gider', style: AppTypography.labelS),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.currency(allExpense),
                              style: GoogleFonts.dmMono(
                                fontSize: 15, fontWeight: FontWeight.w600,
                                color: AppColors.accentRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Net Bakiye
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Net Bakiye', style: AppTypography.labelS),
                            const SizedBox(height: 4),
                            Text(
                              '${totalBalance >= 0 ? "+" : ""}${Formatters.currency(totalBalance)}',
                              style: GoogleFonts.dmMono(
                                fontSize: 15, fontWeight: FontWeight.w600,
                                color: totalBalance >= 0 ? AppColors.accentGreen : AppColors.accentRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 12),

            const SizedBox(height: 12),
            // ── Aylık Kategori Dağılımı (seçili ay) ──────────────────────────
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kategori Dağılımı', style: AppTypography.headlineS),
                            Text(
                              Formatters.monthYear(selectedMonth),
                              style: AppTypography.labelS.copyWith(
                                color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sections: entries.asMap().entries.map((e) {
                              final isTouched = e.key == touchedIndex;
                              return PieChartSectionData(
                                color: AppColors.chartColors[e.key % AppColors.chartColors.length],
                                value: e.value.value,
                                title: isTouched ? e.value.key.label : '',
                                radius: isTouched ? 65 : 55,
                                titleStyle: AppTypography.labelS.copyWith(
                                  color: AppColors.bgPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              );
                            }).toList(),
                            centerSpaceRadius: 55,
                            sectionsSpace: 2,
                            pieTouchData: PieTouchData(
                              touchCallback: (event, response) {
                                if (response?.touchedSection != null) {
                                  onTouch(response!.touchedSection!.touchedSectionIndex);
                                }
                              },
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Toplam', style: AppTypography.labelS),
                            Text(
                              Formatters.currency(totalExpense),
                              style: GoogleFonts.dmMono(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Efsane
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: entries.asMap().entries.map((e) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.chartColors[e.key % AppColors.chartColors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(e.value.key.label, style: AppTypography.labelS),
                      ],
                    )).toList(),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 12),

            // Kategori karşılaştırma listesi
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bütçe Karşılaştırması', style: AppTypography.headlineS),
                  const SizedBox(height: 16),
                  ...entries.take(6).map((e) => _CategoryRow(
                    category: e.key,
                    spent: e.value,
                    budget: _budget(e.key, provider.user.monthlyIncome),
                  )),
                ],
              ),
            ).animate(delay: 100.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  double _budget(TransactionCategory cat, double monthlyIncome) {
    // Sabit fallback değerleri (gelir bilinmiyorsa)
    const fallback = <TransactionCategory, double>{
      TransactionCategory.yemeicme: 3500,
      TransactionCategory.market:   3000,
      TransactionCategory.eglence:  500,
      TransactionCategory.fatura:   2000,
      TransactionCategory.ulasim:   1500,
      TransactionCategory.giyim:    1000,
    };
    if (monthlyIncome <= 0) return fallback[cat] ?? 500;
    const ratios = <TransactionCategory, double>{
      TransactionCategory.yemeicme: 0.20,
      TransactionCategory.market:   0.25,
      TransactionCategory.eglence:  0.08,
      TransactionCategory.fatura:   0.20,
      TransactionCategory.ulasim:   0.15,
      TransactionCategory.giyim:    0.07,
    };
    return monthlyIncome * (ratios[cat] ?? 0.05);
  }
}

class _CategoryRow extends StatelessWidget {
  final TransactionCategory category;
  final double spent;
  final double budget;
  const _CategoryRow({
    required this.category,
    required this.spent,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (spent / budget).clamp(0.0, 1.5);
    final isOver = spent > budget;
    final color = isOver ? AppColors.accentRed : AppColors.accentGreen;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Text(category.icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(category.label,
                    style: AppTypography.bodyM.copyWith(color: AppColors.textPrimary)),
              ),
              Text(Formatters.currency(spent),
                  style: GoogleFonts.dmMono(
                    color: isOver ? AppColors.accentRed : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  )),
              Text(' / ${Formatters.currency(budget)}',
                  style: AppTypography.labelS),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Container(
                    height: 5,
                    width: constraints.maxWidth * v,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
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

// ── İşlemler Sekmesi ──────────────────────────────────────────────────────────
class _TransactionsTab extends StatefulWidget {
  final DateTime selectedMonth;
  const _TransactionsTab({required this.selectedMonth});

  @override
  State<_TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<_TransactionsTab> {
  TransactionCategory? _filterCategory;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        var txs = provider.transactionsForMonth(
          widget.selectedMonth.year,
          widget.selectedMonth.month,
        );
        if (_filterCategory != null) {
          txs = txs.where((t) => t.category == _filterCategory).toList();
        }

        return Column(
          children: [
            // Kategori filtresi
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FilterChip(
                    label: 'Tümü',
                    isSelected: _filterCategory == null,
                    onTap: () => setState(() => _filterCategory = null),
                  ),
                  ...TransactionCategory.values.map((cat) => _FilterChip(
                    label: cat.label,
                    isSelected: _filterCategory == cat,
                    onTap: () => setState(() =>
                        _filterCategory = _filterCategory == cat ? null : cat),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: txs.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SwipeableTransactionTile(
                    tx: txs[i],
                    onDelete: () => provider.deleteTransaction(txs[i].id),
                  ).animate(delay: (i * 30).ms).fadeIn(duration: 200.ms),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentGreen : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accentGreen : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelS.copyWith(
            color: isSelected ? AppColors.bgPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SwipeableTransactionTile extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback onDelete;
  const _SwipeableTransactionTile({required this.tx, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.accentRed.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.accentRed),
      ),
      onDismissed: (_) => onDelete(),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(tx.category.icon,
                  style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.note ?? tx.category.label,
                    style: AppTypography.bodyM.copyWith(
                        color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text('${tx.category.label} · ${Formatters.date(tx.date)}',
                      style: AppTypography.labelS),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${tx.isIncome ? "+" : "-"}${Formatters.currency(tx.amount)}',
                  style: GoogleFonts.dmMono(
                    color: tx.isIncome ? AppColors.accentGreen : AppColors.textPrimary,
                    fontSize: 14, fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tx.source == 'ocr' ? '📷 OCR'
                        : tx.source == 'recurring' ? '🔄 Sabit'
                        : '✏️ Manuel',
                    style: AppTypography.labelS.copyWith(fontSize: 10),
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

// ── Sabit Kalemler Sekmesi ────────────────────────────────────────────────────
class _RecurringTab extends StatelessWidget {
  const _RecurringTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final items = provider.recurringItems;
        final totalMonthly = items
            .where((r) => r.isActive && r.frequency == 'monthly')
            .fold(0.0, (sum, r) => sum + r.amount);

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            // Özet kart
            AppCard(
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aylık Sabit Gider', style: AppTypography.labelS),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.currency(totalMonthly),
                        style: GoogleFonts.dmMono(
                          fontSize: 22, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Yıllık Toplam', style: AppTypography.labelS),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.currency(totalMonthly * 12),
                        style: GoogleFonts.dmMono(
                          fontSize: 16, fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 12),

            ...items.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                borderColor: e.value.isActive
                    ? AppColors.borderSubtle
                    : AppColors.textDisabled.withOpacity(0.3),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.value.label,
                          style: AppTypography.bodyM.copyWith(
                            color: e.value.isActive
                                ? AppColors.textPrimary
                                : AppColors.textDisabled,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              Formatters.frequency(e.value.frequency),
                              style: AppTypography.labelS,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sonraki: ${Formatters.shortDate(e.value.nextDueDate)}',
                              style: AppTypography.labelS,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.currency(e.value.amount),
                          style: GoogleFonts.dmMono(
                            color: e.value.isActive
                                ? AppColors.textPrimary
                                : AppColors.textDisabled,
                            fontSize: 14, fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: e.value.isActive
                                ? AppColors.accentGreen.withOpacity(0.12)
                                : AppColors.textDisabled.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            e.value.isActive ? 'Aktif' : 'İptal',
                            style: AppTypography.labelS.copyWith(
                              color: e.value.isActive
                                  ? AppColors.accentGreen
                                  : AppColors.textDisabled,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate(delay: (e.key * 50).ms).fadeIn(duration: 200.ms),
            )),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

// ── Ekle Sekmesi ──────────────────────────────────────────────────────────────
class _AddTab extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddTab({required this.onAdded});

  @override
  State<_AddTab> createState() => _AddTabState();
}

class _AddTabState extends State<_AddTab> {
  bool _isManual = true;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  TransactionCategory _selectedCategory = TransactionCategory.market;
  String _type = 'expense';

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(
        _amountController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
    if (amount <= 0) return;

    // SpendingViewModel üzerinden Firestore'a yaz
    final ok = await context.read<SpendingViewModel>().addTransaction(
      amount:   amount,
      category: _selectedCategory.label,
      type:     _type,
      source:   'manual',
      note:     _noteController.text.isEmpty ? null : _noteController.text,
    );

    if (ok) {
      // AppProvider'ı da anlık güncelle (local copy)
      final tx = TransactionModel(
        id:       'tx_${DateTime.now().millisecondsSinceEpoch}',
        userId:   AuthService.instance.userId ?? '',
        amount:   amount,
        category: _selectedCategory,
        type:     _type,
        source:   'manual',
        date:     DateTime.now(),
        note:     _noteController.text.isEmpty ? null : _noteController.text,
      );
      if (mounted) context.read<AppProvider>().addTransaction(tx);
      _amountController.clear();
      _noteController.clear();
      if (mounted) widget.onAdded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Mod seçici
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(child: GestureDetector(
                  onTap: () => setState(() => _isManual = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _isManual ? AppColors.bgTertiary : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.edit_outlined, size: 16,
                            color: AppColors.textPrimary),
                        const SizedBox(width: 6),
                        Text('Manuel Giriş', style: AppTypography.labelM.copyWith(
                          color: AppColors.textPrimary,
                        )),
                      ],
                    ),
                  ),
                )),
                Expanded(child: GestureDetector(
                  onTap: () => setState(() => _isManual = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_isManual ? AppColors.bgTertiary : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_outlined, size: 16,
                            color: AppColors.textPrimary),
                        const SizedBox(width: 6),
                        Text('OCR ile Ekle', style: AppTypography.labelM.copyWith(
                          color: AppColors.textPrimary,
                        )),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_isManual) ...[
            // Gelir / Gider toggle
            Row(
              children: ['expense', 'income'].map((t) => Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: Container(
                    margin: EdgeInsets.only(right: t == 'expense' ? 6 : 0,
                        left: t == 'income' ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _type == t
                          ? (t == 'income' ? AppColors.accentGreen : AppColors.accentRed).withOpacity(0.15)
                          : AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _type == t
                            ? (t == 'income' ? AppColors.accentGreen : AppColors.accentRed)
                            : AppColors.borderSubtle,
                      ),
                    ),
                    child: Text(
                      t == 'income' ? '↑ Gelir' : '↓ Gider',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelM.copyWith(
                        color: _type == t
                            ? (t == 'income' ? AppColors.accentGreen : AppColors.accentRed)
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),

            // Tutar
            _buildField(
              label: 'Tutar (TL)',
              controller: _amountController,
              hint: '0',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Not
            _buildField(
              label: 'Not (opsiyonel)',
              controller: _noteController,
              hint: 'Migros market alışverişi',
            ),
            const SizedBox(height: 16),

            // Kategori
            Text('Kategori', style: AppTypography.labelM),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TransactionCategory.values
                  .where((c) => _type == 'income' ? c == TransactionCategory.gelir : c != TransactionCategory.gelir)
                  .map((cat) => GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedCategory == cat
                        ? AppColors.accentGreen.withOpacity(0.15)
                        : AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedCategory == cat
                          ? AppColors.accentGreen
                          : AppColors.borderSubtle,
                    ),
                  ),
                  child: Text(
                    '${cat.icon} ${cat.label}',
                    style: AppTypography.labelS.copyWith(
                      color: _selectedCategory == cat
                          ? AppColors.accentGreen
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: AppColors.bgPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: Text('İşlemi Kaydet', style: AppTypography.button),
              ),
            ),
          ] else ...[
            // OCR modu
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderActive, width: 1.5,
                    style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.document_scanner_outlined,
                      color: AppColors.accentBlue, size: 48),
                  const SizedBox(height: 12),
                  Text('Fiş veya Ekstre Tarayın',
                      style: AppTypography.bodyM.copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text('Google Cloud Vision ile analiz edilir',
                      style: AppTypography.labelS),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const OcrScreen()),
                    ),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Fiş Tara'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelM),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.outfit(
              color: AppColors.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(
                color: AppColors.textDisabled, fontSize: 16),
            filled: true,
            fillColor: AppColors.bgTertiary,
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
        ),
      ],
    );
  }
}
