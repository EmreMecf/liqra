import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/providers/app_provider.dart';

/// Kategori bazlı aylık bütçe limitlerini belirleme sayfası.
///
/// Limit girilmemiş kategori "sınırsız" sayılır — kullanıcıyı her kalem için
/// rakam girmeye zorlamak yerine, takip etmek istediklerini seçmesine izin
/// verilir.
Future<void> showBudgetSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _BudgetSheet(),
  );
}

/// Bütçe belirlenebilen kategoriler.
/// Gelir ve yatırım gider değildir; bunlara limit konmaz.
const _budgetableCategories = <TransactionCategory>[
  TransactionCategory.market,
  TransactionCategory.yemeicme,
  TransactionCategory.ulasim,
  TransactionCategory.eglence,
  TransactionCategory.giyim,
  TransactionCategory.teknoloji,
  TransactionCategory.fatura,
  TransactionCategory.saglik,
  TransactionCategory.egitim,
  TransactionCategory.diger,
];

class _BudgetSheet extends StatefulWidget {
  const _BudgetSheet();

  @override
  State<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<_BudgetSheet> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final budget = provider.budget;
    final spentByCategory = provider.monthlyExpensesByCategory;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0C1120),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Aylık Bütçe',
                            style: GoogleFonts.fraunces(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        const SizedBox(height: 3),
                        Text(
                          budget.isEmpty
                              ? 'Takip etmek istediğin kategorilere limit koy.'
                              : 'Toplam bütçen '
                                  '${Formatters.currency(budget.totalLimit)}',
                          style: GoogleFonts.outfit(
                              fontSize: 12.5, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white38, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                itemCount: _budgetableCategories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final category = _budgetableCategories[i];
                  return _BudgetRow(
                    category: category,
                    limit: budget.limitFor(category),
                    spent: spentByCategory[category] ?? 0,
                    onChanged: (value) => context
                        .read<AppProvider>()
                        .setBudgetLimit(category, value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetRow extends StatefulWidget {
  final TransactionCategory category;
  final double? limit;
  final double spent;
  final void Function(double?) onChanged;

  const _BudgetRow({
    required this.category,
    required this.limit,
    required this.spent,
    required this.onChanged,
  });

  @override
  State<_BudgetRow> createState() => _BudgetRowState();
}

class _BudgetRowState extends State<_BudgetRow> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.limit == null ? '' : widget.limit!.toStringAsFixed(0));
    _focus = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  /// Odak kaybında kaydeder — her tuş vuruşunda Firestore'a yazmamak için.
  void _onFocusChange() {
    if (_focus.hasFocus) return;
    final raw = _ctrl.text.trim();
    final parsed = raw.isEmpty
        ? null
        : double.tryParse(raw.replaceAll('.', '').replaceAll(',', '.'));
    if (parsed != widget.limit) widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final hasLimit = (widget.limit ?? 0) > 0;
    final status = hasLimit
        ? BudgetStatus(
            category: widget.category,
            limit: widget.limit!,
            spent: widget.spent)
        : null;

    final color = status == null
        ? Colors.white24
        : status.isOver
            ? AppColors.accentRed
            : status.isNear
                ? AppColors.accentAmber
                : AppColors.accentGreen;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: status?.isOver == true
              ? AppColors.accentRed.withValues(alpha: 0.35)
              : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(widget.category.icon, style: const TextStyle(fontSize: 17)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.category.label,
                        style: AppTypography.labelM.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      hasLimit
                          ? '${Formatters.currency(widget.spent)} harcandı'
                          : 'Limit yok',
                      style: AppTypography.bodyS.copyWith(
                        color: status?.isOver == true
                            ? AppColors.accentRed
                            : AppColors.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 104,
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  textAlign: TextAlign.right,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: false),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  style: GoogleFonts.dmMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '—',
                    suffixText: '₺',
                    suffixStyle: GoogleFonts.dmMono(
                        fontSize: 12, color: Colors.white38),
                    hintStyle: GoogleFonts.dmMono(
                        fontSize: 14, color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: const BorderSide(
                          color: AppColors.accentGreen, width: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (status != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: status.ratio,
                minHeight: 5,
                backgroundColor: AppColors.bgTertiary,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '%${(status.rawRatio * 100).round()}',
                  style: GoogleFonts.dmMono(fontSize: 11, color: color),
                ),
                const Spacer(),
                Text(
                  status.isOver
                      ? '${Formatters.currency(status.overspend)} aşıldı'
                      : '${Formatters.currency(status.remaining)} kaldı',
                  style: GoogleFonts.dmMono(fontSize: 11, color: color),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
