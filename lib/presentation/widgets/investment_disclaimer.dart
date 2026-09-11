import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';

/// "Yatırım tavsiyesi değildir" uyarısı.
///
/// ── Neden görünür olmak zorunda ────────────────────────────────────────────
/// Türkiye'de kişiye özel yatırım danışmanlığı SPK lisansı gerektirir
/// (6362 sayılı Sermaye Piyasası Kanunu). Liqra lisanslı bir kurum değil;
/// asistanın hisse analizi ve portföy yorumları bilgilendirme amaçlıdır.
///
/// Bu cümle eskiden yalnızca gizlilik politikasında ve modele giden prompt'ta
/// vardı — kullanıcı hiçbir ekranda görmüyordu. Mağaza incelemesi finans
/// uygulamalarında bunu arar; yasal olarak da uyarının kullanıcının analizi
/// okuduğu yerde durması gerekir, başka bir sayfada değil.
///
/// Asistanın ürettiği her yatırım içeriğinin altında kullanılmalı.
class InvestmentDisclaimer extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const InvestmentDisclaimer({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
  });

  static const text = 'Liqra\'nın analizleri bilgilendirme amaçlıdır, '
      'yatırım tavsiyesi değildir. Yatırım kararlarının sorumluluğu sana aittir.';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline_rounded,
                size: 13, color: AppColors.textDisabled),
          ),
          const SizedBox(width: AppSpacing.xxs + 2),
          Expanded(
            child: Text(
              text,
              style: AppTypography.labelS.copyWith(
                color: AppColors.textDisabled,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
