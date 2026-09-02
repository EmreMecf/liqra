import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/assistant_insight.dart';

Color _severityColor(InsightSeverity s) => switch (s) {
      InsightSeverity.critical => AppColors.accentRed,
      InsightSeverity.warning => AppColors.accentAmber,
      InsightSeverity.opportunity => AppColors.accentGreen,
      InsightSeverity.info => AppColors.textSecondary,
    };

/// Tek bir içgörü kartı.
class InsightCard extends StatelessWidget {
  final AssistantInsight insight;
  final VoidCallback? onTap;

  const InsightCard({super.key, required this.insight, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(insight.severity);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(insight.emoji,
                  style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.title,
                    style: AppTypography.labelM.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    insight.body,
                    style: AppTypography.bodyS
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  if (insight.action != null) ...[
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Text(
                          insight.action!,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(Icons.arrow_forward_rounded, size: 12, color: color),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// İçgörü listesi — başlıkla birlikte. Boşsa hiçbir yer kaplamaz.
class InsightList extends StatelessWidget {
  final List<AssistantInsight> insights;
  final String title;
  final int limit;
  final void Function(AssistantInsight)? onTap;

  const InsightList({
    super.key,
    required this.insights,
    this.title = 'Liqra ne görüyor',
    this.limit = 4,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();
    final shown = insights.take(limit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(title, style: AppTypography.headlineS),
            ],
          ),
        ),
        ...shown.map((i) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: InsightCard(
                insight: i,
                onTap: onTap == null ? null : () => onTap!(i),
              ),
            )),
      ],
    );
  }
}
