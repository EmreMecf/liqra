import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/financial_account_entity.dart';
import '../viewmodels/accounts_viewmodel.dart';

// ── İşlem tipleri ─────────────────────────────────────────────────────────────

enum _TxType {
  income,
  bankExpense,
  cardExpense,
  cardPayment,
  transfer,
}

extension _TxTypeExt on _TxType {
  String get label {
    switch (this) {
      case _TxType.income:
        return 'Gelir';
      case _TxType.bankExpense:
        return 'Banka Harcaması';
      case _TxType.cardExpense:
        return 'Kart Harcaması';
      case _TxType.cardPayment:
        return 'Kart Ödemesi';
      case _TxType.transfer:
        return 'Transfer';
    }
  }

  String get emoji {
    switch (this) {
      case _TxType.income:
        return '📥';
      case _TxType.bankExpense:
        return '💳';
      case _TxType.cardExpense:
        return '🛒';
      case _TxType.cardPayment:
        return '💸';
      case _TxType.transfer:
        return '🔄';
    }
  }

  Color get color {
    switch (this) {
      case _TxType.income:
        return const Color(0xFF0AFFE0);
      case _TxType.bankExpense:
        return const Color(0xFFFF4757);
      case _TxType.cardExpense:
        return const Color(0xFFFF9F43);
      case _TxType.cardPayment:
        return const Color(0xFF3B82F6);
      case _TxType.transfer:
        return const Color(0xFF8B5CF6);
    }
  }

  LinearGradient get gradient {
    final c = color;
    return LinearGradient(
      colors: [c, c.withValues(alpha: 0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

// ── Kategori sabitleri ─────────────────────────────────────────────────────────

const _expenseCategories = [
  ('market', '🛒', 'Market'),
  ('yemeicme', '🍽️', 'Yeme-İçme'),
  ('fatura', '📄', 'Fatura'),
  ('ulasim', '🚗', 'Ulaşım'),
  ('saglik', '🏥', 'Sağlık'),
  ('eglence', '🎮', 'Eğlence'),
  ('giyim', '👕', 'Giyim'),
  ('teknoloji', '💻', 'Teknoloji'),
  ('diger', '💡', 'Diğer'),
];

const _incomeCategories = [
  ('maas', '💼', 'Maaş'),
  ('serbest', '🧑‍💻', 'Serbest'),
  ('kira', '🏠', 'Kira Geliri'),
  ('faiz', '📈', 'Faiz/Temettü'),
  ('gelir', '💰', 'Diğer Gelir'),
];

// ── Ana Widget ─────────────────────────────────────────────────────────────────

class AccountingTransactionSheet extends StatefulWidget {
  final AccountsViewModel vm;
  final List<BankAccountEntity> bankAccounts;
  final List<CreditCardEntity> creditCards;
  final String? preSelectedAccountId;
  final String? preSelectedType; // 'bank' | 'creditCard'

  const AccountingTransactionSheet({
    super.key,
    required this.vm,
    required this.bankAccounts,
    required this.creditCards,
    this.preSelectedAccountId,
    this.preSelectedType,
  });

  static Future<void> show(
    BuildContext context, {
    required AccountsViewModel vm,
    required List<BankAccountEntity> bankAccounts,
    required List<CreditCardEntity> creditCards,
    String? preSelectedAccountId,
    String? preSelectedType,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => AccountingTransactionSheet(
        vm: vm,
        bankAccounts: bankAccounts,
        creditCards: creditCards,
        preSelectedAccountId: preSelectedAccountId,
        preSelectedType: preSelectedType,
      ),
    );
  }

  @override
  State<AccountingTransactionSheet> createState() =>
      _AccountingTransactionSheetState();
}

class _AccountingTransactionSheetState
    extends State<AccountingTransactionSheet> {
  // Form state
  late _TxType _txType;
  String? _fromAccountId;
  String? _toAccountId;
  String? _fromCardId;
  String _category = 'diger';
  DateTime _date = DateTime.now();
  bool _saving = false;

  final _amtCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amtFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    // Determine default type based on preSelectedType
    if (widget.preSelectedType == 'creditCard') {
      _txType = _TxType.cardExpense;
    } else {
      _txType = _TxType.income;
    }

    // Pre-select accounts
    if (widget.preSelectedAccountId != null) {
      final isCreditCard = widget.creditCards
          .any((c) => c.id == widget.preSelectedAccountId);
      if (isCreditCard) {
        _fromCardId = widget.preSelectedAccountId;
        _txType = _TxType.cardExpense;
      } else {
        _fromAccountId = widget.preSelectedAccountId;
      }
    } else {
      // Default selections
      if (widget.bankAccounts.isNotEmpty) {
        _fromAccountId = widget.bankAccounts.first.id;
      }
      if (widget.creditCards.isNotEmpty) {
        _fromCardId = widget.creditCards.first.id;
      }
    }

    if (widget.bankAccounts.length > 1) {
      _toAccountId = widget.bankAccounts
          .firstWhere(
            (a) => a.id != _fromAccountId,
            orElse: () => widget.bankAccounts.first,
          )
          .id;
    } else if (widget.bankAccounts.isNotEmpty) {
      _toAccountId = widget.bankAccounts.first.id;
    }

    _setDefaultCategory();
  }

  void _setDefaultCategory() {
    switch (_txType) {
      case _TxType.income:
        _category = 'maas';
        break;
      default:
        _category = 'market';
    }
  }

  @override
  void dispose() {
    _amtCtrl.dispose();
    _descCtrl.dispose();
    _amtFocus.dispose();
    super.dispose();
  }

  void _onTypeChanged(_TxType type) {
    setState(() {
      _txType = type;
      _setDefaultCategory();
    });
  }

  Future<void> _save() async {
    final amount =
        double.tryParse(_amtCtrl.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) {
      _amtFocus.requestFocus();
      return;
    }

    setState(() => _saving = true);

    bool ok = false;
    final desc = _descCtrl.text.trim();
    final effectiveDesc = desc.isEmpty ? _txType.label : desc;

    try {
      switch (_txType) {
        case _TxType.income:
          if (_fromAccountId == null) break;
          ok = await widget.vm.recordIncome(
            bankAccountId: _fromAccountId!,
            amount: amount,
            description: effectiveDesc,
            category: _category,
            date: _date,
          );
          break;

        case _TxType.bankExpense:
          if (_fromAccountId == null) break;
          ok = await widget.vm.recordBankExpense(
            bankAccountId: _fromAccountId!,
            amount: amount,
            description: effectiveDesc,
            category: _category,
            date: _date,
          );
          break;

        case _TxType.cardExpense:
          if (_fromCardId == null) break;
          ok = await widget.vm.recordCreditExpense(
            creditCardId: _fromCardId!,
            amount: amount,
            description: effectiveDesc,
            category: _category,
            date: _date,
          );
          break;

        case _TxType.cardPayment:
          if (_fromAccountId == null || _fromCardId == null) break;
          ok = await widget.vm.recordCreditPayment(
            bankAccountId: _fromAccountId!,
            creditCardId: _fromCardId!,
            amount: amount,
            date: _date,
          );
          break;

        case _TxType.transfer:
          if (_fromAccountId == null || _toAccountId == null) break;
          if (_fromAccountId == _toAccountId) break;
          ok = await widget.vm.recordTransfer(
            fromAccountId: _fromAccountId!,
            toAccountId: _toAccountId!,
            amount: amount,
            description: effectiveDesc,
            date: _date,
          );
          break;
      }
    } catch (_) {
      ok = false;
    }

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.pop(context);
  }

  // ── Tarih seçici ─────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentGreen,
            onPrimary: AppColors.bgPrimary,
            surface: AppColors.bgSecondary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final color = _txType.color;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgVoid,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.borderMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Başlık
            Text(
              'İşlem Kaydet',
              style: AppTypography.headlineS,
            ),
            const SizedBox(height: 4),
            Text(
              'Hesabınıza doğru işlemi seçin',
              style: AppTypography.bodyS,
            ),
            const SizedBox(height: 16),

            // Tip seçici kartlar
            _TypeSelector(
              selected: _txType,
              onChanged: _onTypeChanged,
              hasBankAccounts: widget.bankAccounts.isNotEmpty,
              hasCreditCards: widget.creditCards.isNotEmpty,
            ),
            const SizedBox(height: 20),

            // İşlem formları
            _buildForm(color),
            const SizedBox(height: 20),

            // Kaydet butonu
            _SaveButton(
              saving: _saving,
              color: color,
              gradient: _txType.gradient,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(Color color) {
    switch (_txType) {
      case _TxType.income:
        return _buildIncomeExpenseForm(color, isIncome: true);
      case _TxType.bankExpense:
        return _buildIncomeExpenseForm(color, isIncome: false);
      case _TxType.cardExpense:
        return _buildCardExpenseForm(color);
      case _TxType.cardPayment:
        return _buildCardPaymentForm(color);
      case _TxType.transfer:
        return _buildTransferForm(color);
    }
  }

  // ── Gelir / Banka Gider formu ─────────────────────────────────────────────

  Widget _buildIncomeExpenseForm(Color color, {required bool isIncome}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hesap seçici
        if (widget.bankAccounts.isNotEmpty) ...[
          _SectionLabel('Hesap'),
          const SizedBox(height: 6),
          _AccountDropdown(
            accounts: widget.bankAccounts
                .map((a) => _AccountOption(id: a.id, label: a.name, subtitle: a.bank.displayName, emoji: a.bank.emoji))
                .toList(),
            selectedId: _fromAccountId,
            color: color,
            onChanged: (id) => setState(() => _fromAccountId = id),
          ),
          const SizedBox(height: 12),
        ],

        // Tutar
        _SectionLabel('Tutar'),
        const SizedBox(height: 6),
        _AmountField(controller: _amtCtrl, focusNode: _amtFocus, color: color),
        const SizedBox(height: 12),

        // Açıklama
        _SectionLabel('Açıklama'),
        const SizedBox(height: 6),
        _DescField(controller: _descCtrl),
        const SizedBox(height: 12),

        // Kategori
        _SectionLabel('Kategori'),
        const SizedBox(height: 6),
        _CategoryChips(
          categories: isIncome ? _incomeCategories : _expenseCategories,
          selected: _category,
          color: color,
          onChanged: (c) => setState(() => _category = c),
        ),
        const SizedBox(height: 12),

        // Tarih
        _DateChip(date: _date, color: color, onTap: _pickDate),
      ],
    );
  }

  // ── Kart harcaması formu ──────────────────────────────────────────────────

  Widget _buildCardExpenseForm(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.creditCards.isNotEmpty) ...[
          _SectionLabel('Kredi Kartı'),
          const SizedBox(height: 6),
          _AccountDropdown(
            accounts: widget.creditCards
                .map((c) => _AccountOption(
                      id: c.id,
                      label: c.name,
                      subtitle: '${c.bank.displayName} • Kullanılan: ₺${c.usedAmount.toStringAsFixed(0)}',
                      emoji: c.bank.emoji,
                    ))
                .toList(),
            selectedId: _fromCardId,
            color: color,
            onChanged: (id) => setState(() => _fromCardId = id),
          ),
          const SizedBox(height: 12),
        ],
        _SectionLabel('Tutar'),
        const SizedBox(height: 6),
        _AmountField(controller: _amtCtrl, focusNode: _amtFocus, color: color),
        const SizedBox(height: 12),
        _SectionLabel('Açıklama'),
        const SizedBox(height: 6),
        _DescField(controller: _descCtrl),
        const SizedBox(height: 12),
        _SectionLabel('Kategori'),
        const SizedBox(height: 6),
        _CategoryChips(
          categories: _expenseCategories,
          selected: _category,
          color: color,
          onChanged: (c) => setState(() => _category = c),
        ),
        const SizedBox(height: 12),
        _DateChip(date: _date, color: color, onTap: _pickDate),
      ],
    );
  }

  // ── Kart ödemesi formu ────────────────────────────────────────────────────

  Widget _buildCardPaymentForm(Color color) {
    // Suggest minimum payment amount
    CreditCardEntity? selectedCard;
    if (_fromCardId != null) {
      final matches = widget.creditCards.where((c) => c.id == _fromCardId);
      if (matches.isNotEmpty) selectedCard = matches.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.bankAccounts.isNotEmpty) ...[
          _SectionLabel('Ödeyen Banka Hesabı'),
          const SizedBox(height: 6),
          _AccountDropdown(
            accounts: widget.bankAccounts
                .map((a) => _AccountOption(
                      id: a.id,
                      label: a.name,
                      subtitle: '${a.bank.displayName} • ₺${a.balance.toStringAsFixed(2)}',
                      emoji: a.bank.emoji,
                    ))
                .toList(),
            selectedId: _fromAccountId,
            color: color,
            onChanged: (id) => setState(() => _fromAccountId = id),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.creditCards.isNotEmpty) ...[
          _SectionLabel('Ödenecek Kredi Kartı'),
          const SizedBox(height: 6),
          _AccountDropdown(
            accounts: widget.creditCards
                .map((c) => _AccountOption(
                      id: c.id,
                      label: c.name,
                      subtitle: '${c.bank.displayName} • Borç: ₺${c.usedAmount.toStringAsFixed(0)}',
                      emoji: c.bank.emoji,
                    ))
                .toList(),
            selectedId: _fromCardId,
            color: color,
            onChanged: (id) => setState(() => _fromCardId = id),
          ),
          const SizedBox(height: 12),
        ],

        // Kısa yollar
        if (selectedCard != null) ...[
          _SectionLabel('Hızlı Tutar'),
          const SizedBox(height: 6),
          Row(
            children: [
              _QuickAmountChip(
                label: 'Asgari',
                amount: selectedCard.minimumPayment,
                color: color,
                onTap: () => _amtCtrl.text =
                    selectedCard!.minimumPayment.toStringAsFixed(2),
              ),
              const SizedBox(width: 8),
              _QuickAmountChip(
                label: 'Ekstre',
                amount: selectedCard.statementBalance,
                color: color,
                onTap: () => _amtCtrl.text =
                    selectedCard!.statementBalance.toStringAsFixed(2),
              ),
              const SizedBox(width: 8),
              _QuickAmountChip(
                label: 'Tüm Borç',
                amount: selectedCard.usedAmount,
                color: color,
                onTap: () => _amtCtrl.text =
                    selectedCard!.usedAmount.toStringAsFixed(2),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        _SectionLabel('Ödeme Tutarı'),
        const SizedBox(height: 6),
        _AmountField(controller: _amtCtrl, focusNode: _amtFocus, color: color),
        const SizedBox(height: 12),
        _DateChip(date: _date, color: color, onTap: _pickDate),
      ],
    );
  }

  // ── Transfer formu ────────────────────────────────────────────────────────

  Widget _buildTransferForm(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.bankAccounts.isNotEmpty) ...[
          _SectionLabel('Gönderen Hesap'),
          const SizedBox(height: 6),
          _AccountDropdown(
            accounts: widget.bankAccounts
                .map((a) => _AccountOption(
                      id: a.id,
                      label: a.name,
                      subtitle: '${a.bank.displayName} • ₺${a.balance.toStringAsFixed(2)}',
                      emoji: a.bank.emoji,
                    ))
                .toList(),
            selectedId: _fromAccountId,
            color: color,
            onChanged: (id) => setState(() {
              _fromAccountId = id;
              // Eğer aynı hesap seçildiyse başka birini seç
              if (_toAccountId == id) {
                final others =
                    widget.bankAccounts.where((a) => a.id != id);
                _toAccountId =
                    others.isNotEmpty ? others.first.id : null;
              }
            }),
          ),
          const SizedBox(height: 12),
          _SectionLabel('Alıcı Hesap'),
          const SizedBox(height: 6),
          _AccountDropdown(
            accounts: widget.bankAccounts
                .where((a) => a.id != _fromAccountId)
                .map((a) => _AccountOption(
                      id: a.id,
                      label: a.name,
                      subtitle: '${a.bank.displayName} • ₺${a.balance.toStringAsFixed(2)}',
                      emoji: a.bank.emoji,
                    ))
                .toList(),
            selectedId: _toAccountId,
            color: color,
            onChanged: (id) => setState(() => _toAccountId = id),
            emptyLabel: 'Başka hesap yok',
          ),
          const SizedBox(height: 12),
        ],
        _SectionLabel('Tutar'),
        const SizedBox(height: 6),
        _AmountField(controller: _amtCtrl, focusNode: _amtFocus, color: color),
        const SizedBox(height: 12),
        _SectionLabel('Açıklama (opsiyonel)'),
        const SizedBox(height: 6),
        _DescField(controller: _descCtrl, hint: 'Transfer açıklaması'),
        const SizedBox(height: 12),
        _DateChip(date: _date, color: color, onTap: _pickDate),
      ],
    );
  }
}

// ── Tip seçici ─────────────────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  final _TxType selected;
  final ValueChanged<_TxType> onChanged;
  final bool hasBankAccounts;
  final bool hasCreditCards;

  const _TypeSelector({
    required this.selected,
    required this.onChanged,
    required this.hasBankAccounts,
    required this.hasCreditCards,
  });

  @override
  Widget build(BuildContext context) {
    final types = _TxType.values.where((t) {
      if (!hasBankAccounts &&
          (t == _TxType.income ||
              t == _TxType.bankExpense ||
              t == _TxType.cardPayment ||
              t == _TxType.transfer)) {
        return false;
      }
      if (!hasCreditCards &&
          (t == _TxType.cardExpense || t == _TxType.cardPayment)) {
        return false;
      }
      return true;
    }).toList();

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final type = types[i];
          final isSelected = type == selected;
          final color = type.color;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(type);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 76,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.15)
                    : AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? color.withValues(alpha: 0.6)
                      : AppColors.borderSubtle,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(type.emoji,
                      style: TextStyle(
                          fontSize: isSelected ? 22 : 20)),
                  const SizedBox(height: 4),
                  Text(
                    type.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? color
                          : AppColors.textDisabled,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Hesap seçici dropdown ──────────────────────────────────────────────────────

class _AccountOption {
  final String id;
  final String label;
  final String subtitle;
  final String emoji;
  const _AccountOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.emoji,
  });
}

class _AccountDropdown extends StatelessWidget {
  final List<_AccountOption> accounts;
  final String? selectedId;
  final Color color;
  final ValueChanged<String?> onChanged;
  final String emptyLabel;

  const _AccountDropdown({
    required this.accounts,
    required this.selectedId,
    required this.color,
    required this.onChanged,
    this.emptyLabel = 'Hesap yok',
  });

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Text(emptyLabel,
            style: GoogleFonts.outfit(color: AppColors.textDisabled)),
      );
    }

    final selected = accounts.where((a) => a.id == selectedId);
    final current = selected.isNotEmpty ? selected.first : accounts.first;

    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Text(current.emoji,
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(current.label,
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text(current.subtitle,
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: color, size: 20),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ...accounts.map((a) => ListTile(
                  leading: Text(a.emoji,
                      style: const TextStyle(fontSize: 22)),
                  title: Text(a.label,
                      style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                  subtitle: Text(a.subtitle,
                      style: GoogleFonts.outfit(
                          color: AppColors.textSecondary,
                          fontSize: 12)),
                  trailing: a.id == selectedId
                      ? Icon(Icons.check_circle_rounded,
                          color: color)
                      : null,
                  onTap: () {
                    onChanged(a.id);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Bölüm etiketi ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.capsLabel,
    );
  }
}

// ── Tutar alanı ───────────────────────────────────────────────────────────────

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final Color color;

  const _AmountField({
    required this.controller,
    this.focusNode,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      style: GoogleFonts.dmMono(
          fontSize: 24,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: '0,00',
        hintStyle: GoogleFonts.dmMono(
            fontSize: 24,
            color: AppColors.textDisabled),
        prefixText: '₺  ',
        prefixStyle: GoogleFonts.dmMono(
            fontSize: 20, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.bgTertiary,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: AppColors.borderSubtle, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: color, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

// ── Açıklama alanı ────────────────────────────────────────────────────────────

class _DescField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _DescField({
    required this.controller,
    this.hint = 'Açıklama (opsiyonel)',
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: AppColors.textDisabled),
        filled: true,
        fillColor: AppColors.bgTertiary,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: AppColors.borderSubtle, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: AppColors.accentGreen, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

// ── Kategori seçimi ───────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  final List<(String, String, String)> categories;
  final String selected;
  final Color color;
  final ValueChanged<String> onChanged;

  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: categories.map((c) {
          final isSelected = selected == c.$1;
          return GestureDetector(
            onTap: () => onChanged(c.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.12)
                    : AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? color.withValues(alpha: 0.5)
                      : AppColors.borderSubtle,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(c.$2,
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(c.$3,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? color
                            : AppColors.textSecondary,
                      )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Tarih chip ────────────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  final DateTime date;
  final Color color;
  final VoidCallback onTap;

  const _DateChip({
    required this.date,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMMM yyyy', 'tr_TR');
    final isToday = DateUtils.isSameDay(date, DateTime.now());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_rounded,
                color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              isToday ? 'Bugün — ${fmt.format(date)}' : fmt.format(date),
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(width: 4),
            Icon(Icons.edit_rounded,
                color: AppColors.textDisabled, size: 12),
          ],
        ),
      ),
    );
  }
}

// ── Hızlı tutar chip ─────────────────────────────────────────────────────────

class _QuickAmountChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final VoidCallback onTap;

  const _QuickAmountChip({
    required this.label,
    required this.amount,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Text(label,
                  style: GoogleFonts.outfit(
                      fontSize: 10, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text('₺${amount.toStringAsFixed(0)}',
                  style: GoogleFonts.dmMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Kaydet butonu ─────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final bool saving;
  final Color color;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _SaveButton({
    required this.saving,
    required this.color,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: saving ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: saving ? null : gradient,
          color: saving ? color.withValues(alpha: 0.4) : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: saving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.bgPrimary))
              : Text(
                  'Kaydet',
                  style: AppTypography.button
                      .copyWith(fontSize: 16),
                ),
        ),
      ),
    );
  }
}
