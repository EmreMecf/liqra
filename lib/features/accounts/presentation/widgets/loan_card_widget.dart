import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/financial_account_entity.dart';
import '../../domain/entities/loan_entity.dart';
import '../viewmodels/accounts_viewmodel.dart';
import '../../../spending/presentation/viewmodel/spending_viewmodel.dart';

class LoanCardWidget extends StatelessWidget {
  final LoanEntity loan;

  const LoanCardWidget({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    final fmt =
        NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    final bankColor = loan.bank.primaryColor;

    Color dueDateColor;
    String dueDateLabel;
    if (loan.isOverdue) {
      dueDateColor = AppColors.accentRed;
      dueDateLabel = 'Gecikmiş!';
    } else if (loan.isDueSoon) {
      dueDateColor = AppColors.accentAmber;
      dueDateLabel = '${loan.daysUntilPayment} gün kaldı';
    } else {
      dueDateColor = AppColors.accentGreen;
      dueDateLabel = '${loan.daysUntilPayment} gün kaldı';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: bankColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Başlık satırı ────────────────────────────────────────────
            Row(
              children: [
                Text(loan.bank.emoji,
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.name,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        loan.bank.displayName,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Durum etiketi
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: dueDateColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: dueDateColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule,
                          size: 11, color: dueDateColor),
                      const SizedBox(width: 4),
                      Text(
                        dueDateLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: dueDateColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── İlerleme çubuğu ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ödenen',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.textDisabled,
                  ),
                ),
                Text(
                  '%${(loan.progressPercent * 100).toStringAsFixed(1)}',
                  style: GoogleFonts.dmMono(
                    fontSize: 11,
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: loan.progressPercent,
                backgroundColor:
                    AppColors.accentGreen.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.accentGreen),
                minHeight: 6,
              ),
            ),

            const SizedBox(height: 14),

            // ── Borç bilgileri ───────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    label: 'Kalan Borç',
                    value: fmt.format(loan.remainingAmount),
                    valueColor: AppColors.accentRed,
                    large: true,
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    label: 'Aylık Taksit',
                    value: fmt.format(loan.monthlyPayment),
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    label: 'Kalan Taksit',
                    value: '${loan.remainingInstallments} ay',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Ödeme butonu ─────────────────────────────────────────────
            if (loan.status == 'active')
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.accentGreen.withValues(alpha: 0.15),
                    foregroundColor: AppColors.accentGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppColors.accentGreen.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  onPressed: () => _showPaymentSheet(context),
                  child: Text(
                    'Ödeme Yap',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: AppColors.accentGreen, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Kredi Tamamlandı',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentGreen,
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

  void _showPaymentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LoanPaymentSheet(loan: loan),
    );
  }
}

// ── Info item ──────────────────────────────────────────────────────────────

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool large;

  const _InfoItem({
    required this.label,
    required this.value,
    this.valueColor,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: AppColors.textDisabled,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.dmMono(
            fontSize: large ? 16 : 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Ödeme sayfası ──────────────────────────────────────────────────────────

class _LoanPaymentSheet extends StatefulWidget {
  final LoanEntity loan;
  const _LoanPaymentSheet({required this.loan});

  @override
  State<_LoanPaymentSheet> createState() => _LoanPaymentSheetState();
}

class _LoanPaymentSheetState extends State<_LoanPaymentSheet> {
  late final TextEditingController _amountCtrl;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.loan.monthlyPayment.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final fmt = NumberFormat.currency(
        locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0C1120),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Başlık
          Text(
            'Taksit Öde',
            style: GoogleFonts.fraunces(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.loan.name,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 20),

          // Aylık taksit bilgisi
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.accentGreen.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Aylık Taksit',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  fmt.format(widget.loan.monthlyPayment),
                  style: GoogleFonts.dmMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentGreen,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tutar alanı
          Text(
            'Ödeme Tutarı (₺)',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.dmMono(fontSize: 16, color: Colors.white),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: GoogleFonts.dmMono(
                  fontSize: 16, color: Colors.white.withValues(alpha: 0.2)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppColors.accentGreen, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),

          const SizedBox(height: 10),

          // Hızlı chip — minimum taksit
          GestureDetector(
            onTap: () => setState(() {
              _amountCtrl.text =
                  widget.loan.monthlyPayment.toStringAsFixed(0);
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentAmber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.accentAmber.withValues(alpha: 0.25)),
              ),
              child: Text(
                'Taksit: ${fmt.format(widget.loan.monthlyPayment)}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accentAmber,
                ),
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: GoogleFonts.outfit(
                  fontSize: 12, color: AppColors.accentRed),
            ),
          ],

          const SizedBox(height: 20),

          // Onayla butonu
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _loading
                    ? AppColors.accentGreen.withValues(alpha: 0.5)
                    : AppColors.accentGreen,
                foregroundColor: const Color(0xFF05080F),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _loading ? null : _confirm,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF05080F)),
                    )
                  : Text(
                      'Onayla',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm() async {
    final amount = double.tryParse(
        _amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Geçerli bir tutar girin');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final vm = context.read<AccountsViewModel>();
    final spendingVm = context.read<SpendingViewModel>();

    final err = await vm.recordLoanPayment(
      loan: widget.loan,
      amount: amount,
      spendingVm: spendingVm,
    );

    if (!mounted) return;
    if (err != null) {
      setState(() {
        _loading = false;
        _error = err;
      });
    } else {
      Navigator.pop(context);
    }
  }
}
