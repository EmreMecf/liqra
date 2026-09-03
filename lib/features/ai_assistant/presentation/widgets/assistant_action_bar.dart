import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/providers/app_provider.dart';
import '../../../accounts/presentation/viewmodels/accounts_viewmodel.dart';
import '../assistant_context_builder.dart';
import '../viewmodel/ai_assistant_viewmodel.dart';
import 'savings_plan_sheet.dart';

/// Asistanın tek dokunuşluk görevleri.
///
/// Sohbet kutusuna yazmak yerine kullanıcı doğrudan "harcamalarımı denetle"
/// diyebilsin diye vardır — asistanın yardımcı gibi davranmasının en görünür
/// kısmı budur.
class AssistantActionBar extends StatelessWidget {
  final AiAssistantViewModel vm;

  const AssistantActionBar({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final busy = vm.isBusy;

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _ActionChip(
            emoji: '🔍',
            label: 'Harcamalarımı denetle',
            enabled: !busy,
            onTap: () => vm.auditSpending(
              AssistantContextBuilder.fromContext(context),
            ),
          ),
          _ActionChip(
            emoji: '🪙',
            label: 'Birikim planı',
            enabled: !busy,
            onTap: () => _openSavingsPlan(context),
          ),
          _ActionChip(
            emoji: '🎁',
            label: 'Bana uygun kampanyalar',
            enabled: !busy,
            onTap: () => vm.recommendCampaigns(
              context: AssistantContextBuilder.fromContext(context),
              userBanks: AssistantContextBuilder.userBanks(
                context.read<AccountsViewModel>(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openSavingsPlan(BuildContext context) {
    final goal = context.read<AppProvider>().primaryGoal;
    showSavingsPlanSheet(
      context,
      vm: vm,
      initialTitle: goal?.title,
      initialTarget: goal?.targetAmount,
      initialCurrent: goal?.currentAmount,
      initialDeadline: goal?.deadline,
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionChip({
    required this.emoji,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.accentGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accentGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
