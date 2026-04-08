import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/financial_account_entity.dart';
import '../viewmodels/accounts_viewmodel.dart';
import '../widgets/account_transaction_tile.dart';

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
      final id = widget.account.when(
        bankAccount: (id, _, __, ___, ____, _____, ______, _______, ________) => id,
        creditCard: (id, _, __, ___, ____, _____, ______, _______, ________, _________, __________, ___________, ____________) => id,
      );
      context.read<AccountsViewModel>().loadTransactions(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.account.when(
      bankAccount: (id, _, name, bank, balance, currency, iban, masked, createdAt) =>
          _BankAccountDetail(
            id: id, name: name, bank: bank, balance: balance,
            iban: iban, currency: currency,
          ),
      creditCard: (id, _, name, bank, limit, used, statement, minPay,
          closingDay, dueDay, maskedNo, currency, createdAt) =>
          _CreditCardDetail(
            id: id, name: name, bank: bank,
            creditLimit: limit, usedAmount: used,
            statementBalance: statement, minimumPayment: minPay,
            statementClosingDay: closingDay, paymentDueDay: dueDay,
            maskedCardNumber: maskedNo,
          ),
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
      backgroundColor: const Color(0xFF05080F),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF05080F),
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
                      const Color(0xFF05080F),
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

  void _showAddTx(BuildContext context) => _AddTransactionSheet.show(context, id);
}

// ── Kredi Kartı Detay ──────────────────────────────────────────────────────

class _CreditCardDetail extends StatelessWidget {
  final String id, name;
  final BankName bank;
  final double creditLimit, usedAmount, statementBalance, minimumPayment;
  final int statementClosingDay, paymentDueDay;
  final String? maskedCardNumber;

  const _CreditCardDetail({
    required this.id, required this.name, required this.bank,
    required this.creditLimit, required this.usedAmount,
    required this.statementBalance, required this.minimumPayment,
    required this.statementClosingDay, required this.paymentDueDay,
    this.maskedCardNumber,
  });

  @override
  Widget build(BuildContext context) {
    final bankColor = bank.primaryColor;
    final fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    final usagePct = creditLimit > 0 ? (usedAmount / creditLimit).clamp(0.0, 1.0) : 0.0;

    // Due date hesapla
    final now = DateTime.now();
    var due = DateTime(now.year, now.month, paymentDueDay);
    if (due.isBefore(now)) due = DateTime(now.year, now.month + 1, paymentDueDay);
    final daysLeft = due.difference(now).inDays;

    return Scaffold(
      backgroundColor: const Color(0xFF05080F),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF05080F),
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
                    colors: [bankColor.withValues(alpha: 0.2), const Color(0xFF05080F)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Text(bank.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 6),
                    Text(name,
                        style: GoogleFonts.outfit(
                            fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 2),
                    if (maskedCardNumber != null)
                      Text('•••• •••• •••• $maskedCardNumber',
                          style: GoogleFonts.dmMono(
                              fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
                    const SizedBox(height: 16),
                    // Limit arc
                    _LimitArc(usage: usagePct, color: bankColor,
                        used: fmt.format(usedAmount), limit: fmt.format(creditLimit)),
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
                    value: fmt.format(statementBalance),
                    color: bankColor,
                  ),
                  const SizedBox(width: 8),
                  _InfoBox(
                    label: 'Asgari Ödeme',
                    value: fmt.format(minimumPayment),
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  _InfoBox(
                    label: daysLeft < 0 ? 'GECİKMİŞ' : '$daysLeft Gün Kaldı',
                    value: 'Son Ödeme',
                    color: daysLeft < 0
                        ? const Color(0xFFFF4757)
                        : daysLeft <= 3
                            ? const Color(0xFFE4B84A)
                            : Colors.white.withValues(alpha: 0.5),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
            ),
          ),

          // Kesim / ödeme günleri
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _DayBadge(label: 'Kesim Günü', day: statementClosingDay, color: bankColor),
                  const SizedBox(width: 8),
                  _DayBadge(label: 'Son Ödeme Günü', day: paymentDueDay, color: const Color(0xFFE4B84A)),
                ],
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
        onPressed: () => _AddTransactionSheet.show(context, id),
        icon: const Icon(Icons.add),
        label: Text('İşlem Ekle', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ),
    );
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
          color: const Color(0xFF111827),
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

// ── Manuel İşlem Ekleme Sheet ─────────────────────────────────────────────

class _AddTransactionSheet extends StatefulWidget {
  final String accountId;
  const _AddTransactionSheet({required this.accountId});

  static void show(BuildContext context, String accountId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTransactionSheet(accountId: accountId),
    );
  }

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  final _descCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  String _type = 'expense';
  String _category = 'diger';
  bool _saving = false;

  static const _categories = [
    ('market', '🛒', 'Market'),
    ('yemeicme', '🍽️', 'Yeme-İçme'),
    ('fatura', '📄', 'Fatura'),
    ('ulasim', '🚗', 'Ulaşım'),
    ('saglik', '🏥', 'Sağlık'),
    ('eglence', '🎮', 'Eğlence'),
    ('giyim', '👕', 'Giyim'),
    ('teknoloji', '💻', 'Teknoloji'),
    ('gelir', '💰', 'Gelir'),
    ('diger', '💳', 'Diğer'),
  ];

  @override
  void dispose() {
    _descCtrl.dispose(); _amtCtrl.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0C1120),
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
          Text('İşlem Ekle',
              style: GoogleFonts.fraunces(
                  fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 16),

          // Tip seçimi
          Row(
            children: [
              _TypeBtn(label: 'Gider', selected: _type == 'expense',
                  color: const Color(0xFFFF4757),
                  onTap: () => setState(() => _type = 'expense')),
              const SizedBox(width: 8),
              _TypeBtn(label: 'Gelir', selected: _type == 'income',
                  color: const Color(0xFF0AFFE0),
                  onTap: () => setState(() => _type = 'income')),
            ],
          ),
          const SizedBox(height: 14),

          // Tutar
          TextField(
            controller: _amtCtrl,
            keyboardType: TextInputType.number,
            style: GoogleFonts.dmMono(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: '0,00',
              hintStyle: GoogleFonts.dmMono(fontSize: 22, color: Colors.white.withValues(alpha: 0.2)),
              prefixText: '₺ ',
              prefixStyle: GoogleFonts.dmMono(fontSize: 22, color: Colors.white.withValues(alpha: 0.4)),
              filled: true, fillColor: Colors.white.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0AFFE0), width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 10),

          // Açıklama
          TextField(
            controller: _descCtrl,
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Açıklama',
              hintStyle: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.25)),
              filled: true, fillColor: Colors.white.withValues(alpha: 0.04),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0AFFE0), width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),

          // Kategori seçimi
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _categories.map((c) {
                final selected = _category == c.$1;
                return GestureDetector(
                  onTap: () => setState(() => _category = c.$1),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF0AFFE0).withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected
                              ? const Color(0xFF0AFFE0).withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        Text(c.$2, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(c.$3,
                            style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: selected
                                    ? const Color(0xFF0AFFE0)
                                    : Colors.white.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                decoration: BoxDecoration(
                  color: _saving
                      ? const Color(0xFF0AFFE0).withValues(alpha: 0.5)
                      : const Color(0xFF0AFFE0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF05080F)))
                      : Text('Kaydet',
                          style: GoogleFonts.outfit(
                              fontSize: 14, fontWeight: FontWeight.w700,
                              color: const Color(0xFF05080F))),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amtCtrl.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) return;

    setState(() => _saving = true);
    final ok = await context.read<AccountsViewModel>().addTransaction(
      accountId: widget.accountId,
      amount: amount,
      description: _descCtrl.text.trim().isEmpty ? _category : _descCtrl.text.trim(),
      type: _type,
      category: _category,
    );
    setState(() => _saving = false);
    if (ok && mounted) Navigator.pop(context);
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeBtn({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? color.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08)),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: selected ? color : Colors.white.withValues(alpha: 0.4))),
          ),
        ),
      ),
    );
  }
}
