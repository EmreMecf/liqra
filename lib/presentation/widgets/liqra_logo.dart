import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

// ── Marka renkleri (HTML tasarımından birebir)
const _teal = Color(0xFF0AFFE0);
const _gold = Color(0xFFE4B84A);

// ══════════════════════════════════════════════════════════════════════════════
//  KÜÇÜK LOGO — ₺-L Glow Premium App Icon
//  Yuvarlatılmış kare, koyu arka plan, teal glow, altın nokta.
//  NavBar, liste başlıkları, küçük yerleşimler için.
// ══════════════════════════════════════════════════════════════════════════════
class LiqraLogoMark extends StatefulWidget {
  final double size;
  final bool animated;

  const LiqraLogoMark({super.key, this.size = 48, this.animated = true});

  @override
  State<LiqraLogoMark> createState() => _LiqraLogoMarkState();
}

class _LiqraLogoMarkState extends State<LiqraLogoMark>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animated) {
      return CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _LogoMarkPainter(glowAlpha: 0.55),
      );
    }
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _LogoMarkPainter(glowAlpha: _glow.value),
      ),
    );
  }
}

class _LogoMarkPainter extends CustomPainter {
  final double glowAlpha;
  const _LogoMarkPainter({required this.glowAlpha});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 64.0;

    // ── Arka plan (radial gradient: koyu mavi → siyah)
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(bgRect, Radius.circular(15 * s));
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.5),
          radius: 0.8,
          colors: [Color(0xFF0C1E30), Color(0xFF05080F)],
        ).createShader(bgRect),
    );

    // ── Teal sınır
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = _teal.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * s,
    );

    // ── Glow katmanı (çizimden önce, arkasında)
    final glowBlur = glowAlpha * 7 * s;

    final glowStroke = Paint()
      ..color = _teal
      ..strokeWidth = 3.2 * s
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowBlur);

    final glowFill = Paint()
      ..color = _teal
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowBlur);

    _drawMark(canvas, s, glowStroke, glowFill);

    // ── Keskin katman (üstte)
    final crispStroke = Paint()
      ..color = _teal
      ..strokeWidth = 3.2 * s
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final crispFill = Paint()
      ..color = _teal
      ..style = PaintingStyle.fill;

    _drawMark(canvas, s, crispStroke, crispFill);

    // ── Altın nokta (sağ üst köşe)
    canvas.drawCircle(
      Offset(52 * s, 12 * s),
      7 * s,
      Paint()
        ..color = _gold.withValues(alpha: glowAlpha * 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * s),
    );
    canvas.drawCircle(
      Offset(52 * s, 12 * s),
      4.5 * s,
      Paint()..color = _gold,
    );
  }

  /// ₺-L sembolü: dikey + 2 açılı bar + L ayağı
  void _drawMark(Canvas canvas, double s, Paint stroke, Paint fill) {
    // Dikey stroke
    canvas.drawLine(Offset(26 * s, 12 * s), Offset(26 * s, 52 * s), stroke);
    // ₺ bar 1 (açılı)
    canvas.drawLine(Offset(16 * s, 26 * s), Offset(38 * s, 23 * s), stroke);
    // ₺ bar 2 (açılı)
    canvas.drawLine(Offset(16 * s, 36 * s), Offset(38 * s, 33 * s), stroke);
    // L ayağı
    canvas.drawLine(Offset(26 * s, 52 * s), Offset(44 * s, 52 * s), stroke);
  }

  @override
  bool shouldRepaint(_LogoMarkPainter old) => old.glowAlpha != glowAlpha;
}

// ══════════════════════════════════════════════════════════════════════════════
//  BÜYÜK LOGO — Tam Liqra Wordmark
//  viewBox 0 0 200 58'den birebir çizilir.
//  ₺-L harfi + i + q + r + a + altın imza noktası.
//  Auth, splash, onboarding başlıkları için.
// ══════════════════════════════════════════════════════════════════════════════
class LiqraWordmark extends StatefulWidget {
  final double width;
  final bool animated;
  final bool showTagline;

  const LiqraWordmark({
    super.key,
    this.width = 280,
    this.animated = true,
    this.showTagline = false,
  });

  @override
  State<LiqraWordmark> createState() => _LiqraWordmarkState();
}

class _LiqraWordmarkState extends State<LiqraWordmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.38, end: 0.82).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // viewBox: 0 0 200 58 — oranı koru
    final height = widget.width * (64 / 200); // biraz daha ferah

    Widget logo;
    if (!widget.animated) {
      logo = CustomPaint(
        size: Size(widget.width, height),
        painter: _WordmarkPainter(glowAlpha: 0.55),
      );
    } else {
      logo = AnimatedBuilder(
        animation: _glow,
        builder: (_, __) => CustomPaint(
          size: Size(widget.width, height),
          painter: _WordmarkPainter(glowAlpha: _glow.value),
        ),
      );
    }

    if (!widget.showTagline) return logo;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        const SizedBox(height: 10),
        Text(
          'LİKİT PARANIN ZEKASI',
          style: GoogleFonts.dmMono(
            fontSize: widget.width * 0.038,
            letterSpacing: widget.width * 0.016,
            color: _teal.withValues(alpha: 0.40),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _WordmarkPainter extends CustomPainter {
  final double glowAlpha;
  const _WordmarkPainter({required this.glowAlpha});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 200.0;

    final blur = glowAlpha * 9 * s;

    // ── Glow geçişi
    final glowStroke = Paint()
      ..color = _teal
      ..strokeWidth = 3.6 * s
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

    final glowFill = Paint()
      ..color = _teal
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

    _drawAll(canvas, s, glowStroke, glowFill);

    // ── Keskin geçiş
    final crispStroke = Paint()
      ..color = _teal
      ..strokeWidth = 3.6 * s
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final crispFill = Paint()
      ..color = _teal
      ..style = PaintingStyle.fill;

    _drawAll(canvas, s, crispStroke, crispFill);

    // ── Altın imza noktası
    canvas.drawCircle(
      Offset(160 * s, 48 * s),
      8 * s,
      Paint()
        ..color = _gold.withValues(alpha: glowAlpha * 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * s),
    );
    canvas.drawCircle(
      Offset(160 * s, 48 * s),
      4.8 * s,
      Paint()..color = _gold,
    );
  }

  void _drawAll(Canvas canvas, double s, Paint stroke, Paint fill) {
    // ── ₺-L (dikey + 2 açılı bar + L ayağı)
    canvas.drawLine(Offset(12 * s, 7 * s),  Offset(12 * s, 49 * s), stroke);
    canvas.drawLine(Offset(4 * s,  24 * s), Offset(26 * s, 21 * s), stroke);
    canvas.drawLine(Offset(4 * s,  34 * s), Offset(26 * s, 31 * s), stroke);
    canvas.drawLine(Offset(12 * s, 49 * s), Offset(33 * s, 49 * s), stroke);

    // ── i (nokta + gövde)
    canvas.drawCircle(Offset(47 * s, 11 * s), 3.2 * s, fill);
    canvas.drawLine(Offset(47 * s, 19 * s), Offset(47 * s, 49 * s), stroke);

    // ── q (halka + kuyruk)
    canvas.drawCircle(Offset(67 * s, 34 * s), 14.5 * s, stroke);
    canvas.drawLine(Offset(78 * s, 41 * s), Offset(84 * s, 56 * s), stroke);

    // ── r (gövde + kemer)
    canvas.drawLine(Offset(94 * s, 20 * s), Offset(94 * s, 49 * s), stroke);
    final rArch = Path()
      ..moveTo(94 * s, 29 * s)
      ..quadraticBezierTo(112 * s, 17 * s, 114 * s, 29 * s);
    canvas.drawPath(rArch, stroke);

    // ── a (halka + sağ stroke)
    canvas.drawCircle(Offset(133 * s, 34 * s), 14.5 * s, stroke);
    canvas.drawLine(Offset(147 * s, 20 * s), Offset(147 * s, 49 * s), stroke);
  }

  @override
  bool shouldRepaint(_WordmarkPainter old) => old.glowAlpha != glowAlpha;
}

// ══════════════════════════════════════════════════════════════════════════════
//  GERİYE UYUMLULUK — LiqraLogo
//  Mevcut auth_screen / splash_screen kodları değişmeden çalışmaya devam eder.
//  fontSize → width map: fontSize * 7.2
//  showRing → wordmark'ın arkasına dekoratif halka ekler
// ══════════════════════════════════════════════════════════════════════════════
class LiqraLogo extends StatelessWidget {
  final double fontSize;
  final bool showTagline;
  final bool centered;
  final bool showRing;
  final bool animated;

  const LiqraLogo({
    super.key,
    this.fontSize    = 36,
    this.showTagline = false,
    this.centered    = true,
    this.showRing    = false,
    this.animated    = true,
  });

  @override
  Widget build(BuildContext context) {
    final wordmarkWidth = fontSize * 7.2;
    final wordmark = LiqraWordmark(
      width: wordmarkWidth,
      animated: animated,
      showTagline: showTagline,
    );

    if (!showRing) {
      return centered ? Center(child: wordmark) : wordmark;
    }

    // Auth / splash için dekoratif halka arka planı
    final ringSize = wordmarkWidth * 1.1;
    return SizedBox(
      width: ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(ringSize, ringSize * 0.72),
            painter: _RingPainter(),
          ),
          wordmark,
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
    final r  = size.width * 0.44;

    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()
        ..color = AppColors.accentGreen.withValues(alpha: 0.04)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()
        ..color = AppColors.accentGreen.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    // İkinci daha büyük soluk halka
    canvas.drawCircle(
      Offset(cx, cy), r * 1.3,
      Paint()
        ..color = AppColors.accentGreen.withValues(alpha: 0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
