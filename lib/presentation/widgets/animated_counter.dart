import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';

/// Sayı sayacı animasyonu — parasal değerlerde kullanılır
/// 0'dan başlayıp hedef değere koşar (800ms, easeOutCubic)
class AnimatedCounter extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final bool showCurrency;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.showCurrency = true,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        final text = showCurrency
            ? Formatters.currency(animatedValue)
            : animatedValue.toStringAsFixed(0);
        return Text(
          text,
          style: style ??
              GoogleFonts.dmMono(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
        );
      },
    );
  }
}
