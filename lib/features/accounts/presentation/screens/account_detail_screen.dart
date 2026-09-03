import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/entities/financial_account_entity.dart';
import '../viewmodels/accounts_viewmodel.dart';
import '../widgets/account_transaction_tile.dart';
import '../widgets/accounting_transaction_sheet.dart';

class AccountDetailScreen extends StatefulWidget {
  final FinancialAccountEntity account;
  const AccountDetailScreen({super.key, required this.account});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountsViewModel>().loadTransactions(widget.account.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pozisyonel destructuring yerine doğrudan tip kontrolü: entity'ye alan
    // eklendiğinde bu ekran sessizce bozulmasın.
    final account = widget.account;
    if (account is CreditCardEntity) return _CreditCardDetail(card: account);
    account as BankAccountEntity;
    return _BankAccountDetail(
      id: account.id, name: account.name, bank: account.bank,
      balance: account.balance, iban: account.iban,
      currency: account.currency,
    );
  }
}

// ── Banka Hesabı Detay ─────────────────────────────────────────────────────

class _BankAccountDetail extends StatelessWidget {
  final String id, name;
  final BankName bank;
  final double balance;
  final String? iban;
  final String currency;

  const _BankAccountDetail({
    required this.id, required this.name, required this.bank,
    required this.balance, this.iban, required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final bankColor = bank.primaryColor;
    final fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.bgPrimary,
            expandedHeight: 200,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      bankColor.withValues(alpha: 0.25),
                      AppColors.bgPrimary,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Text(bank.emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Text(bank.displayName,
                        style: GoogleFonts.outfit(
                            fontSize: 14, color: Colors.white.withValues(alpha: 0.5))),
                    const SizedBox(height: 4),
                    Text(fmt.format(balance),
                        style: GoogleFonts.dmMono(
                            fontSize: 28, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    if (iban != null)
                      Text('TR ···${iban!.replaceAll(' ', '').substring(iban!.replaceAll(' ', '').length - 4)}',
                          style: GoogleFonts.dmMono(
                              fontSize: 11, color: Colors.white.withValues(alpha: 0.3))),
                  ],
                ),
              ),
            ),
          ),

          _TransactionsList(accountId: id),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: bankColor,
        foregroundColor: Colors.white,
        onPressed: () => _showAddTx(context),
        icon: const Icon(Icons.add),
        label: Text('İşlem Ekle', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showAddTx(BuildContext context) {
    final vm = context.read<AccountsViewModel>();
    AccountingTransactionSheet.show(
      context,
      vm: vm,
      bankAccounts: vm.bankAccounts,
      creditCards: vm.creditCards,
      preSelectedAccountId: id,
      preSelectedType: 'bank',
    );
  }
}

// ── Kredi Kartı Detay ──────────────────────────────────────────────────────

class _CreditCardDetail extends StatelessWidget {
  final CreditCardEntity card;

  const _CreditCardDetail({required this.card});

  @override
  Widget build(BuildContext context) {
    final bankColor = card.bank.primaryColor;
    final fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    final usagePct = card.usagePercent;
    final daysLeft = card.daysUntilDue;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.bgPrimary,
            expandedHeight: 300,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [bankColor.withValues(alpha: 0.2), AppColors.bgPrimary],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Text(card.bank.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 6),
                    Text(card.name,
                        style: GoogleFonts.outfit(
                            fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 2),
                    if (card.maskedCardNumber != null)
                      Text('•••• •••• •••• ${card.maskedCardNumber}',
                          style: GoogleFonts.dmMono(
                              fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
                    const SizedBox(height: 16),
                    // Limit arc
                    _LimitArc(usage: usagePct, color: bankColor,
                        used: fmt.format(card.usedAmount), limit: fmt.format(card.creditLimit)),
                  ],
                ),
              ),
            ),
          ),

          // Bilgi paneli
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  _InfoBox(
                    label: 'Ekstre Borcu',
                    value: fmt.format(card.statementBalance),
                    color: bankColor,
                  ),
                  const SizedBox(width: 8),
                  _InfoBox(
                    label: 'Asgari Ödeme',
                    value: fmt.format(card.minimumPayment),
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  _InfoBox(
                    label: card.isOverdue
                        ? '${card.daysPastDue} gün gecikti'
                        : daysLeft == 0
                            ? 'Bugün son gün'
                            : '$daysLeft gün kaldı',
                    value: 'Son Ödeme',
                    color: card.isOverdue
                        ? AppColors.accentRed
                        : card.isDueSoon
                            ? AppColors.accentAmber
                            : Colors.white.withValues(alpha: 0.5),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
            ),
          ),

          // Ekstreye girmemiş harcamalar — gelecek ayın yükü
          if (card.unbilledAmount > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.pending_actions_rounded,
                          size: 15, color: Colors.white.withValues(alpha: 0.4)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kesim sonrası harcama — ${Formatters.shortDate(card.nextClosingDate)} ekstresine girecek',
                          style: GoogleFonts.outfit(
                              fontSize: 11.5, color: Colors.white.withValues(alpha: 0.55)),
                        ),
                      ),
                      Text(
                        fmt.format(card.unbilledAmount),
                        style: GoogleFonts.dmMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Kesim / ödeme günleri
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _DayBadge(label: 'Kesim Günü', day: card.statementClosingDay, color: bankColor),
                  const SizedBox(width: 8),
                  _DayBadge(label: 'Son Ödeme Günü', day: card.paymentDueDay, color: AppColors.accentAmber),
                ],
              ),
            ),
          ),

          // Ekstre güncelle butonu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: GestureDetector(
                onTap: () => _showUpdateStatement(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: bankColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: bankColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_rounded, color: bankColor, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Ekstreyi Düzelt',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: bankColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          _TransactionsList(accountId: card.id),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'pay_card',
            backgroundColor: AppColors.accentBlue,
            foregroundColor: Colors.white,
            onPressed: () => _showCardPayment(context),
            icon: const Icon(Icons.payment_rounded, size: 18),
            label: Text('Ödeme Yap', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'add_card_tx',
            backgroundColor: bankColor,
            foregroundColor: Colors.white,
            onPressed: () => _showAddTx(context),
            icon: const Icon(Icons.add),
            label: Text('İşlem Ekle', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showAddTx(BuildContext context) {
    final vm = context.read<AccountsViewModel>();
    AccountingTransactionSheet.show(
      context,
      vm: vm,
      bankAccounts: vm.bankAccounts,
      creditCards: vm.creditCards,
      preSelectedAccountId: card.id,
      preSelectedType: 'creditCard',
    );
  }

  void _showCardPayment(BuildContext context) {
    final vm = context.read<AccountsViewModel>();
    AccountingTransactionSheet.show(
      context,
      vm: vm,
      bankAccounts: vm.bankAccounts,
      creditCards: vm.creditCards,
      preSelectedAccountId: card.id,
      preSelectedType: 'creditCard',
      // "Ödeme Yap" butonu doğrudan kart ödemesi modunu açmalı
      preSelectedTxType: 'cardPayment',
    );
  }

  void _showUpdateStatement(BuildContext context) {
    final stmtCtrl = TextEditingController(text: card.statementBalance.toStringAsFixed(2));
    final minCtrl = TextEditingController(text: card.minimumPayment.toStringAsFixed(2));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.bgVoid,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Ekstreyi Düzelt',
                  style: GoogleFonts.fraunces(
                      fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                  'Ekstre kesim gününde otomatik oluşur. Bankanızdan gelen '
                  'tutar farklıysa buradan düzeltebilirsiniz.',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54)),
              const SizedBox(height: 20),

              Text('EKSTRE BORCU',
                  style: GoogleFonts.dmMono(fontSize: 10, color: Colors.white38, letterSpacing: 1.4)),
              const SizedBox(height: 6),
              TextField(
                controller: stmtCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.dmMono(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  prefixText: '₺  ',
                  prefixStyle: GoogleFonts.dmMono(fontSize: 18, color: Colors.white38),
                  filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),

              Text('ASGARİ ÖDEME',
                  style: GoogleFonts.dmMono(fontSize: 10, color: Colors.white38, letterSpacing: 1.4)),
              const SizedBox(height: 6),
              TextField(
                controller: minCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.dmMono(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  prefixText: '₺  ',
                  prefixStyle: GoogleFonts.dmMono(fontSize: 18, color: Colors.white38),
                  filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),

              _StatementSaveButton(
                stmtCtrl: stmtCtrl,
                minCtrl: minCtrl,
                statementBalance: card.statementBalance,
                minimumPayment: card.minimumPayment,
                cardId: card.id,
                sheetContext: ctx,
              ),
            ],
          ),
        );
      },
    ).then((_) {
      stmtCtrl.dispose();
      minCtrl.dispose();
    });
  }
}

// ── Limit Arc ─────────────────────────────────────────────────────────────

class _LimitArc extends StatelessWidget {
  final double usage;
  final Color color;
  final String used, limit;
  const _LimitArc({required this.usage, required this.color, required this.used, required this.limit});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(120, 70),
            painter: _ArcPainter(usage: usage, color: color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text('${(usage * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.dmMono(
                      fontSize: 16, fontWeight: FontWeight.w700, color: color)),
              Text('kullanıldı',
                  style: GoogleFonts.outfit(
                      fontSize: 9, color: Colors.white.withValues(alpha: 0.4))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double usage;
  final Color color;
  const _ArcPainter({required this.usage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height;
    const r = 55.0;
    const sw = 8.0;

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;

    const startAngle = 3.14159;
    const sweepFull = 3.14159;

    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle, sweepFull, false, bgPaint);

    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle, sweepFull * usage, false, fgPaint);
  }

  @override
  bool shouldRepaint(_) => true;
}

// ── İşlemler Listesi ──────────────────────────────────────────────────────

class _TransactionsList extends StatelessWidget {
  final String accountId;
  const _TransactionsList({required this.accountId});

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountsViewModel>(
      builder: (_, vm, __) {
        final txs = vm.transactionsFor(accountId);

        if (txs.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text('Henüz işlem yok',
                    style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.3))),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => AccountTransactionTile(tx: txs[i])
                  .animate(delay: (i * 30).ms).fadeIn(duration: 250.ms),
              childCount: txs.length,
            ),
          ),
        );
      },
    );
  }
}

// ── Bilgi kutusu ──────────────────────────────────────────────────────────

class _InfoBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _InfoBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.dmMono(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 9, color: Colors.white.withValues(alpha: 0.35)),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _DayBadge extends StatelessWidget {
  final String label;
  final int day;
  final Color color;
  const _DayBadge({required this.label, required this.day, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Text('$day',
                style: GoogleFonts.dmMono(
                    fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.outfit(
                      fontSize: 10, color: Colors.white.withValues(alpha: 0.4))),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ekstre Kaydet Butonu ──────────────────────────────────────────────────

class _StatementSaveButton extends StatefulWidget {
  final TextEditingController stmtCtrl;
  final TextEditingController minCtrl;
  final double statementBalance;
  final double minimumPayment;
  final String cardId;
  final BuildContext sheetContext;

  const _StatementSaveButton({
    required this.stmtCtrl,
    required this.minCtrl,
    required this.statementBalance,
    required this.minimumPayment,
    required this.cardId,
    required this.sheetContext,
  });

  @override
  State<_StatementSaveButton> createState() => _StatementSaveButtonState();
}

class _StatementSaveButtonState extends State<_StatementSaveButton> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: GestureDetector(
        onTap: _saving ? null : _save,
        child: Container(
          decoration: BoxDecoration(
            color: _saving
                ? AppColors.accentBlue.withValues(alpha: 0.5)
                : AppColors.accentBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Kaydet',
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final newStmt = double.tryParse(
            widget.stmtCtrl.text.replaceAll(',', '.')) ??
        widget.statementBalance;
    final newMin = double.tryParse(
            widget.minCtrl.text.replaceAll(',', '.')) ??
        widget.minimumPayment;
    setState(() => _saving = true);

    final vm = widget.sheetContext.read<AccountsViewModel>();
    final cards = vm.creditCards.where((c) => c.id == widget.cardId);
    if (cards.isNotEmpty) {
      await vm.updateStatement(
        card: cards.first,
        statementBalance: newStmt,
        minimumPayment: newMin,
      );
    }

    if (mounted) setState(() => _saving = false);
    if (widget.sheetContext.mounted) {
      Navigator.pop(widget.sheetContext);
    }
  }
}
