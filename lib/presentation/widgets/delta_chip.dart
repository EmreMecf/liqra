import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

/// Pozitif/Negatif/Nötr delta göstergesi
/// Örn: ▲ +12,4% (yeşil) | ▼ -3,2% (kırmızı) | ─ 0,0% (gri)
class DeltaChip extends StatelessWidget {
  final double value;
  final bool showPercent;
  final double? fontSize;

  const DeltaChip({
    super.key,
    required this.value,
    this.showPercent = true,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPositive = value > 0;
    final bool isNeutral  = value == 0;

    final Color bg   = isNeutral  ? AppColors.bgTertiary
                     : isPositive ? AppColors.accentGreen.withOpacity(0.15)
                                  : AppColors.accentRed.withOpacity(0.15);

    final Color text = isNeutral  ? AppColors.textSecondary
                     : isPositive ? AppColors.accentGreen
                                  : AppColors.accentRed;

    final String icon = isNeutral  ? '─'
                      : isPositive ? '▲'
                                   : '▼';

    final String label = isNeutral
        ? '─'
        : '${isPositive ? "+" : ""}${value.toStringAsFixed(1).replaceAll(".", ",")}${showPercent ? "%" : ""}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$icon ',
            style: TextStyle(color: text, fontSize: fontSize ?? 11),
          ),
          Text(
            label,
            style: GoogleFonts.dmMono(
              color: text,
              fontSize: fontSize ?? 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
