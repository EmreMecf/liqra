import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/financial_account_entity.dart';
import '../viewmodels/accounts_viewmodel.dart';

/// Hesap ekleme bottom sheet — 3 adım: tip → banka → detaylar
Future<void> showAddAccountSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddAccountSheet(),
  );
}

class _AddAccountSheet extends StatefulWidget {
  const _AddAccountSheet();

  @override
  State<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<_AddAccountSheet> {
  int _step = 0;
  AccountType? _type;
  BankName? _bank;
  bool _saving = false;

  // Form controllers
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  final _usedCtrl = TextEditingController();
  final _statementCtrl = TextEditingController();
  final _minPayCtrl = TextEditingController();
  final _cardNoCtrl = TextEditingController();
  int _closingDay = 15;
  int _dueDay = 5;

  @override
  void dispose() {
    _nameCtrl.dispose(); _balanceCtrl.dispose(); _ibanCtrl.dispose();
    _limitCtrl.dispose(); _usedCtrl.dispose(); _statementCtrl.dispose();
    _minPayCtrl.dispose(); _cardNoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0C1120),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

          // Başlık + adım
          Row(
            children: [
              if (_step > 0)
                GestureDetector(
                  onTap: () => setState(() => _step--),
                  child: Icon(Icons.arrow_back_ios,
                      size: 16, color: Colors.white.withValues(alpha: 0.5)),
                ),
              if (_step > 0) const SizedBox(width: 8),
              Text(
                _stepTitle(),
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              // Adım göstergesi
              Row(
                children: List.generate(3, (i) => Container(
                  width: i == _step ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: i == _step
                        ? AppColors.accentGreen
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                )),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // İçerik
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildStep(),
          ),
        ],
      ),
    );
  }

  String _stepTitle() {
    switch (_step) {
      case 0: return 'Hesap Türü';
      case 1: return 'Banka Seç';
      case 2: return _type == AccountType.bankAccount
          ? 'Hesap Bilgileri'
          : 'Kart Bilgileri';
      default: return '';
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:  return _StepType(onSelect: (t) { setState(() { _type = t; _step = 1; }); });
      case 1:  return _StepBank(onSelect: (b) { setState(() { _bank = b; _step = 2; }); });
      case 2:  return _type == AccountType.bankAccount
          ? _StepBankDetails(
              nameCtrl: _nameCtrl, balanceCtrl: _balanceCtrl, ibanCtrl: _ibanCtrl,
              bank: _bank!, saving: _saving, onSave: _save)
          : _StepCardDetails(
              nameCtrl: _nameCtrl, limitCtrl: _limitCtrl, usedCtrl: _usedCtrl,
              statementCtrl: _statementCtrl, minPayCtrl: _minPayCtrl,
              cardNoCtrl: _cardNoCtrl, bank: _bank!,
              closingDay: _closingDay, dueDay: _dueDay,
              onClosingDayChanged: (v) => setState(() => _closingDay = v),
              onDueDayChanged: (v) => setState(() => _dueDay = v),
              saving: _saving, onSave: _save);
      default: return const SizedBox.shrink();
    }
  }

  Future<void> _save() async {
    final vm = context.read<AccountsViewModel>();
    setState(() => _saving = true);

    bool ok = false;
    if (_type == AccountType.bankAccount) {
      ok = await vm.addBankAccount(
        name: _nameCtrl.text.trim().isEmpty
            ? _bank!.displayName
            : _nameCtrl.text.trim(),
        bank: _bank!,
        balance: double.tryParse(_balanceCtrl.text.replaceAll(',', '.')) ?? 0,
        iban: _ibanCtrl.text.trim().isEmpty ? null : _ibanCtrl.text.trim(),
      );
    } else {
      ok = await vm.addCreditCard(
        name: _nameCtrl.text.trim().isEmpty
            ? '${_bank!.displayName} Kart'
            : _nameCtrl.text.trim(),
        bank: _bank!,
        creditLimit: double.tryParse(_limitCtrl.text.replaceAll(',', '.')) ?? 0,
        usedAmount: double.tryParse(_usedCtrl.text.replaceAll(',', '.')) ?? 0,
        statementBalance: double.tryParse(_statementCtrl.text.replaceAll(',', '.')) ?? 0,
        minimumPayment: double.tryParse(_minPayCtrl.text.replaceAll(',', '.')) ?? 0,
        statementClosingDay: _closingDay,
        paymentDueDay: _dueDay,
        maskedCardNumber: _cardNoCtrl.text.trim().isEmpty ? null : _cardNoCtrl.text.trim(),
      );
    }

    setState(() => _saving = false);
    if (ok && mounted) Navigator.pop(context);
  }
}

// ── Adım 1: Tür Seçimi ─────────────────────────────────────────────────────

class _StepType extends StatelessWidget {
  final void Function(AccountType) onSelect;
  const _StepType({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TypeCard(
          icon: Icons.account_balance_outlined,
          title: 'Banka Hesabı',
          subtitle: 'Vadesiz, tasarruf veya birikim hesabı',
          color: const Color(0xFF0AFFE0),
          onTap: () => onSelect(AccountType.bankAccount),
        ),
        const SizedBox(height: 12),
        _TypeCard(
          icon: Icons.credit_card_outlined,
          title: 'Kredi Kartı',
          subtitle: 'Limit, ekstre ve son ödeme takibi',
          color: const Color(0xFFE4B84A),
          onTap: () => onSelect(AccountType.creditCard),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon, required this.title, required this.subtitle,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.outfit(
                          fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Adım 2: Banka Seçimi ───────────────────────────────────────────────────

class _StepBank extends StatelessWidget {
  final void Function(BankName) onSelect;
  const _StepBank({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final banks = BankName.values;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: banks.length,
      itemBuilder: (_, i) {
        final bank = banks[i];
        return GestureDetector(
          onTap: () => onSelect(bank),
          child: Container(
            decoration: BoxDecoration(
              color: bank.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: bank.primaryColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(bank.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 6),
                Text(
                  bank.displayName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Adım 3a: Banka Hesabı Detayları ───────────────────────────────────────

class _StepBankDetails extends StatelessWidget {
  final TextEditingController nameCtrl, balanceCtrl, ibanCtrl;
  final BankName bank;
  final bool saving;
  final VoidCallback onSave;

  const _StepBankDetails({
    required this.nameCtrl, required this.balanceCtrl, required this.ibanCtrl,
    required this.bank, required this.saving, required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Field(ctrl: nameCtrl, label: 'Hesap Adı', hint: bank.displayName),
        const SizedBox(height: 12),
        _Field(ctrl: balanceCtrl, label: 'Güncel Bakiye (₺)',
            hint: '0,00', keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        _Field(ctrl: ibanCtrl, label: 'IBAN (opsiyonel)',
            hint: 'TR00 0000 0000 0000 0000 0000 00'),
        const SizedBox(height: 24),
        _SaveButton(saving: saving, onTap: onSave),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Adım 3b: Kredi Kartı Detayları ────────────────────────────────────────

class _StepCardDetails extends StatelessWidget {
  final TextEditingController nameCtrl, limitCtrl, usedCtrl,
      statementCtrl, minPayCtrl, cardNoCtrl;
  final BankName bank;
  final int closingDay, dueDay;
  final void Function(int) onClosingDayChanged, onDueDayChanged;
  final bool saving;
  final VoidCallback onSave;

  const _StepCardDetails({
    required this.nameCtrl, required this.limitCtrl, required this.usedCtrl,
    required this.statementCtrl, required this.minPayCtrl, required this.cardNoCtrl,
    required this.bank, required this.closingDay, required this.dueDay,
    required this.onClosingDayChanged, required this.onDueDayChanged,
    required this.saving, required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Field(ctrl: nameCtrl, label: 'Kart Adı', hint: '${bank.displayName} Bonus'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Field(ctrl: limitCtrl, label: 'Kart Limiti (₺)',
                hint: '0', keyboardType: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _Field(ctrl: usedCtrl, label: 'Kullanılan (₺)',
                hint: '0', keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Field(ctrl: statementCtrl, label: 'Ekstre Borcu (₺)',
                hint: '0', keyboardType: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _Field(ctrl: minPayCtrl, label: 'Asgari Ödeme (₺)',
                hint: '0', keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          _Field(ctrl: cardNoCtrl, label: 'Son 4 Hane (opsiyonel)',
              hint: '1234', keyboardType: TextInputType.number,
              inputFormatters: [LengthLimitingTextInputFormatter(4)]),
          const SizedBox(height: 16),

          // Kesim ve son ödeme günleri
          _DaySelector(
            label: 'Ekstre Kesim Günü',
            value: closingDay,
            onChanged: onClosingDayChanged,
          ),
          const SizedBox(height: 10),
          _DaySelector(
            label: 'Son Ödeme Günü',
            value: dueDay,
            onChanged: onDueDayChanged,
          ),

          const SizedBox(height: 24),
          _SaveButton(saving: saving, onTap: onSave),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Ortak widget'lar ───────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _Field({
    required this.ctrl, required this.label, required this.hint,
    this.keyboardType = TextInputType.text, this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: GoogleFonts.dmMono(fontSize: 14, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmMono(
                fontSize: 14, color: Colors.white.withValues(alpha: 0.2)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF0AFFE0), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _DaySelector extends StatelessWidget {
  final String label;
  final int value;
  final void Function(int) onChanged;

  const _DaySelector({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
            const Spacer(),
            Text(
              '$value',
              style: GoogleFonts.dmMono(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: const Color(0xFF0AFFE0)),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF0AFFE0),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
            thumbColor: const Color(0xFF0AFFE0),
            overlayColor: const Color(0xFF0AFFE0).withValues(alpha: 0.1),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 31,
            divisions: 30,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback onTap;

  const _SaveButton({required this.saving, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: GestureDetector(
        onTap: saving ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            color: saving
                ? const Color(0xFF0AFFE0).withValues(alpha: 0.5)
                : const Color(0xFF0AFFE0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: saving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF05080F)))
                : Text(
                    'Hesabı Ekle',
                    style: GoogleFonts.outfit(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: const Color(0xFF05080F),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
