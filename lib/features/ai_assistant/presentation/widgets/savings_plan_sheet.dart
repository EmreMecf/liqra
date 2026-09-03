import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../assistant_context_builder.dart';
import '../viewmodel/ai_assistant_viewmodel.dart';

/// Birikim planı formu.
///
/// Kullanıcının aktif hedefi varsa alanlar onunla dolu gelir; yoksa serbestçe
/// bir hedef tanımlayabilir ("6 ayda 50.000 ₺ biriktirmek istiyorum").
Future<void> showSavingsPlanSheet(
  BuildContext context, {
  required AiAssistantViewModel vm,
  String? initialTitle,
  double? initialTarget,
  double? initialCurrent,
  DateTime? initialDeadline,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SavingsPlanSheet(
      vm: vm,
      initialTitle: initialTitle,
      initialTarget: initialTarget,
      initialCurrent: initialCurrent,
      initialDeadline: initialDeadline,
    ),
  );
}

class _SavingsPlanSheet extends StatefulWidget {
  final AiAssistantViewModel vm;
  final String? initialTitle;
  final double? initialTarget;
  final double? initialCurrent;
  final DateTime? initialDeadline;

  const _SavingsPlanSheet({
    required this.vm,
    this.initialTitle,
    this.initialTarget,
    this.initialCurrent,
    this.initialDeadline,
  });

  @override
  State<_SavingsPlanSheet> createState() => _SavingsPlanSheetState();
}

class _SavingsPlanSheetState extends State<_SavingsPlanSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _currentCtrl;
  late DateTime _deadline;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle ?? '');
    _targetCtrl = TextEditingController(
        text: widget.initialTarget == null
            ? ''
            : widget.initialTarget!.toStringAsFixed(0));
    _currentCtrl = TextEditingController(
        text: (widget.initialCurrent ?? 0).toStringAsFixed(0));
    _deadline = widget.initialDeadline ??
        DateTime(DateTime.now().year, DateTime.now().month + 6, 1);

    for (final c in [_titleCtrl, _targetCtrl, _currentCtrl]) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    _currentCtrl.dispose();
    super.dispose();
  }

  double _amount(TextEditingController c) {
    final raw = c.text.trim();
    if (raw.isEmpty) return 0;
    return double.tryParse(raw.replaceAll('.', '').replaceAll(',', '.')) ??
        double.tryParse(raw) ??
        0;
  }

  /// Formdaki ilk hata (yoksa null).
  String? get _error {
    if (_titleCtrl.text.trim().isEmpty) return 'Hedefe bir ad ver';
    final target = _amount(_targetCtrl);
    if (target <= 0) return 'Hedef tutarı sıfırdan büyük olmalı';
    if (_amount(_currentCtrl) > target) {
      return 'Mevcut birikim hedeften büyük olamaz';
    }
    if (!_deadline.isAfter(DateTime.now())) {
      return 'Son tarih ileride olmalı';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_error != null) return;
    setState(() => _saving = true);

    await widget.vm.createSavingsPlan(
      context: AssistantContextBuilder.fromContext(context),
      goalTitle: _titleCtrl.text.trim(),
      targetAmount: _amount(_targetCtrl),
      currentAmount: _amount(_currentCtrl),
      deadline: _deadline,
    );

    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime(now.year, now.month + 1),
      lastDate: DateTime(now.year + 20),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentGreen,
            surface: AppColors.bgSecondary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final error = _error;

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
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Birikim Planı',
              style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            'Rakamları asistan hesaplar, nasıl yapacağını da anlatır.',
            style: GoogleFonts.outfit(fontSize: 12.5, color: Colors.white54),
          ),
          const SizedBox(height: 20),

          _Field(ctrl: _titleCtrl, label: 'Hedef', hint: 'Ev peşinatı'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _Field(
                ctrl: _targetCtrl,
                label: 'Hedef Tutar (₺)',
                hint: '250000',
                numeric: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Field(
                ctrl: _currentCtrl,
                label: 'Şu anki Birikim (₺)',
                hint: '0',
                numeric: true,
              ),
            ),
          ]),
          const SizedBox(height: 14),

          Text('SON TARİH',
              style: GoogleFonts.dmMono(
                  fontSize: 10, color: Colors.white38, letterSpacing: 1.4)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickDeadline,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_rounded,
                      size: 15, color: AppColors.accentGreen),
                  const SizedBox(width: 8),
                  Text(Formatters.date(_deadline),
                      style: GoogleFonts.dmMono(
                          fontSize: 14, color: Colors.white)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),
          if (error != null) ...[
            Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 14, color: AppColors.accentRed),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(error,
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: AppColors.accentRed)),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          SizedBox(
            width: double.infinity,
            height: 50,
            child: GestureDetector(
              onTap: (error == null && !_saving) ? _submit : null,
              child: Container(
                decoration: BoxDecoration(
                  color: (error == null && !_saving)
                      ? AppColors.accentGreen
                      : AppColors.accentGreen.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.bgPrimary),
                        )
                      : Text('Planı Oluştur',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.bgPrimary,
                          )),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final bool numeric;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.numeric = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: GoogleFonts.dmMono(
                fontSize: 10, color: Colors.white38, letterSpacing: 1.4)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          inputFormatters: numeric
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
              : null,
          style: GoogleFonts.dmMono(fontSize: 14, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmMono(
                fontSize: 14, color: Colors.white.withValues(alpha: 0.2)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.accentGreen, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
