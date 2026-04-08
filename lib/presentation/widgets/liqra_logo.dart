import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

/// Liqra wordmark logosu — "Liqra." (nokta teal renginde, glow efektli)
///
/// Kullanım:
///   LiqraLogo()                        — varsayılan boyut
///   LiqraLogo(fontSize: 42)            — büyük (splash/auth)
///   LiqraLogo(fontSize: 18)            — küçük (scaffold header)
///   LiqraLogo(showRing: true)          — arka plan halkası ile (auth/splash)
///   LiqraLogo(showTagline: true)       — "Likit paranın zekası" ile
class LiqraLogo extends StatelessWidget {
  final double fontSize;
  final bool showTagline;
  final bool centered;
  final bool showRing;

  const LiqraLogo({
    super.key,
    this.fontSize    = 36,
    this.showTagline = false,
    this.centered    = true,
    this.showRing    = false,
  });

  @override
  Widget build(BuildContext context) {
    final wordmark = _Wordmark(
      fontSize: fontSize,
      centered: centered,
      showRing: showRing,
    );

    if (!showTagline) return wordmark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        wordmark,
        const SizedBox(height: 6),
        Text(
          'Likit paranın zekası',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.outfit(
            fontSize: fontSize * 0.28,
            fontWeight: FontWeight.w300,
            color: AppColors.textDisabled,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _Wordmark extends StatelessWidget {
  final double fontSize;
  final bool centered;
  final bool showRing;

  const _Wordmark({
    required this.fontSize,
    required this.centered,
    required this.showRing,
  });

  @override
  Widget build(BuildContext context) {
    final text = RichText(
      textAlign: centered ? TextAlign.center : TextAlign.start,
      text: TextSpan(
        style: GoogleFonts.fraunces(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: fontSize * -0.035,
          height: 1.0,
        ),
        children: [
          const TextSpan(text: 'Liqra'),
          TextSpan(
            text: '.',
            style: TextStyle(
              color: AppColors.accentGreen,
              shadows: [
                Shadow(
                  color: AppColors.accentGreen.withValues(alpha: 0.55),
                  blurRadius: fontSize * 0.5,
                ),
                Shadow(
                  color: AppColors.accentGreen.withValues(alpha: 0.25),
                  blurRadius: fontSize * 1.2,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!showRing) return text;

    // Arka plan dekoratif halkası (auth / splash ekranlarında)
    final ringSize = fontSize * 3.8;
    return SizedBox(
      width: ringSize,
      height: ringSize * 0.72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dış halka
          Positioned.fill(
            child: CustomPaint(painter: _RingPainter()),
          ),
          text,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.44;

    // Outer glow ring
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = AppColors.accentGreen.withValues(alpha: 0.05)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = AppColors.accentGreen.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
