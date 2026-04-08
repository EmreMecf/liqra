import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../auth/auth_screen.dart';

/// Uygulamayı tanıtan 4 slaytlı intro ekranı.
/// Sadece ilk kurulumda gösterilir (SharedPreferences kontrolü main.dart'ta).
class IntroOnboardingScreen extends StatefulWidget {
  const IntroOnboardingScreen({super.key});

  @override
  State<IntroOnboardingScreen> createState() => _IntroOnboardingScreenState();
}

class _IntroOnboardingScreenState extends State<IntroOnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _IntroPage(
      badge: 'Hoş Geldin',
      title: 'Liqra ile\nfinansını yönet',
      subtitle:
          'Harcamalarını takip et, yatırımlarını büyüt, yapay zeka destekli tavsiyeler al.',
      accent: AppColors.accentGreen,
      illustration: _IllustrationHero(),
    ),
    _IntroPage(
      badge: 'Dashboard',
      title: 'Her şey tek\nbir ekranda',
      subtitle:
          'Aylık gelir-gider özeti, bütçe uyarıları ve portföy değeri anlık olarak önünde.',
      accent: AppColors.accentGreen,
      illustration: _IllustrationDashboard(),
    ),
    _IntroPage(
      badge: 'Yatırım',
      title: 'Portföyün her\nan güncel',
      subtitle:
          'Altın, döviz, kripto, hisse ve TEFAS fonlarını tek portföyde izle, gerçek zamanlı kar/zarar gör.',
      accent: AppColors.accentGold,
      illustration: _IllustrationPortfolio(),
    ),
    _IntroPage(
      badge: 'Yapay Zeka',
      title: 'AI danışmanın\nher zaman yanında',
      subtitle:
          'Finansal sorularını sor, harcama alışkanlıklarını analiz ettir, kişiselleştirilmiş öneriler al.',
      accent: AppColors.accentGreen,
      illustration: _IllustrationAI(),
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToAuth();
    }
  }

  Future<void> _goToAuth() async {
    // Intro bir kez görüldü — bir daha gösterilmesin
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('liqra_intro_seen', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const AuthScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          // Background glow — renk slayta göre değişir
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            top: -100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _pages[_currentPage].accent.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Skip butonu
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 16),
                    child: TextButton(
                      onPressed: _goToAuth,
                      child: Text(
                        'Geç',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, i) => _pages[i],
                  ),
                ),

                // Dots + CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    children: [
                      // Dot indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _currentPage ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: i == _currentPage
                                  ? _pages[_currentPage].accent
                                  : AppColors.textDisabled.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // CTA button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: isLast
                                ? AppColors.accentGreen
                                : AppColors.bgSecondary,
                            border: isLast
                                ? null
                                : Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _next,
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: Text(
                                    isLast ? 'Hadi Başlayalım' : 'Devam Et',
                                    key: ValueKey(isLast),
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isLast
                                          ? AppColors.bgPrimary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slide Model ───────────────────────────────────────────────────────────────

class _IntroPage extends StatelessWidget {
  final String badge;
  final String title;
  final String subtitle;
  final Color accent;
  final Widget illustration;

  const _IntroPage({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.illustration,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 1),

          // Illustration
          Center(child: illustration)
              .animate()
              .fadeIn(duration: 500.ms, delay: 50.ms)
              .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1),
                  duration: 500.ms, delay: 50.ms, curve: Curves.easeOutCubic),

          const Spacer(flex: 2),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            child: Text(
              badge,
              style: GoogleFonts.dmMono(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: accent,
                letterSpacing: 1.0,
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 150.ms),

          const SizedBox(height: 14),

          // Title
          Text(
            title,
            style: GoogleFonts.fraunces(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.15,
              letterSpacing: -1,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideX(begin: 0.04, end: 0, duration: 400.ms, delay: 200.ms,
                  curve: Curves.easeOut),

          const SizedBox(height: 14),

          // Subtitle
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: AppColors.textSecondary,
              height: 1.65,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 300.ms),

          const Spacer(flex: 1),
        ],
      ),
    );
  }
}

// ── Illustrations ─────────────────────────────────────────────────────────────

class _IllustrationHero extends StatelessWidget {
  const _IllustrationHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 180,
      child: CustomPaint(painter: _HeroPainter()),
    );
  }
}

class _HeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Outer ring
    canvas.drawCircle(
      Offset(cx, cy),
      82,
      Paint()
        ..color = AppColors.accentGreen.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      82,
      Paint()
        ..color = AppColors.accentGreen.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Inner ring
    canvas.drawCircle(
      Offset(cx, cy),
      54,
      Paint()
        ..color = AppColors.bgSecondary
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      54,
      Paint()
        ..color = AppColors.accentGreen.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Liqra teal dot
    canvas.drawCircle(
      Offset(cx, cy),
      20,
      Paint()
        ..color = AppColors.accentGreen.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      8,
      Paint()
        ..color = AppColors.accentGreen
        ..style = PaintingStyle.fill,
    );

    // Orbit dots
    final dotPaint = Paint()
      ..color = AppColors.accentGold
      ..style = PaintingStyle.fill;
    final angles = [0.0, math.pi * 0.7, math.pi * 1.4];
    for (final a in angles) {
      canvas.drawCircle(
        Offset(cx + 82 * math.cos(a), cy + 82 * math.sin(a)),
        5,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Dashboard Illustration ────────────────────────────────────────────────────

class _IllustrationDashboard extends StatelessWidget {
  const _IllustrationDashboard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mock
          Row(
            children: [
              Container(
                width: 28, height: 6,
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const Spacer(),
              Container(
                width: 40, height: 6,
                decoration: BoxDecoration(
                  color: AppColors.textDisabled.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Balance mock
          Container(
            width: 120, height: 18,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 80, height: 8,
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 14),

          // Bar chart mini
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final h in [0.4, 0.7, 0.5, 1.0, 0.6, 0.8, 0.45])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      height: 48 * h,
                      decoration: BoxDecoration(
                        color: h == 1.0
                            ? AppColors.accentGreen.withValues(alpha: 0.8)
                            : AppColors.textDisabled.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Portfolio Illustration ────────────────────────────────────────────────────

class _IllustrationPortfolio extends StatelessWidget {
  const _IllustrationPortfolio();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Donut ring
          CustomPaint(
            size: const Size(160, 160),
            painter: _DonutPainter(),
          ),

          // Center text mock
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '₺248K',
                style: GoogleFonts.dmMono(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                '+4.2%',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppColors.accentGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Asset tags
          Positioned(
            right: 0,
            top: 20,
            child: _AssetTag('Altın', AppColors.accentGold),
          ),
          Positioned(
            right: 0,
            bottom: 20,
            child: _AssetTag('Kripto', AppColors.accentRed),
          ),
        ],
      ),
    );
  }
}

class _AssetTag extends StatelessWidget {
  final String label;
  final Color color;
  const _AssetTag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cx = 80.0;
    const cy = 80.0;
    const r = 68.0;
    const strokeW = 18.0;

    final segments = [
      (AppColors.accentGold, 0.30),
      (AppColors.accentGreen, 0.25),
      (AppColors.accentRed, 0.20),
      (const Color(0xFF3B82F6), 0.15),
      (AppColors.textDisabled, 0.10),
    ];

    double startAngle = -math.pi / 2;
    for (final seg in segments) {
      final sweep = 2 * math.pi * seg.$2;
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(cx, cy), radius: r),
        startAngle,
        sweep - 0.04,
        false,
        Paint()
          ..color = seg.$1
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── AI Illustration ───────────────────────────────────────────────────────────

class _IllustrationAI extends StatelessWidget {
  const _IllustrationAI();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 180,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // AI bubble
          _AIChatBubble(
            text: 'Bu ay eğlence harcamanız %40 arttı.',
            isAi: true,
          ),
          const SizedBox(height: 8),
          _AIChatBubble(
            text: 'Bütçemi nasıl optimize edebilirim?',
            isAi: false,
          ),
          const SizedBox(height: 8),
          _AIChatBubble(
            text: 'Yeme-içme için aylık ₺2.500 limit önerilir.',
            isAi: true,
          ),
        ],
      ),
    );
  }
}

class _AIChatBubble extends StatelessWidget {
  final String text;
  final bool isAi;
  const _AIChatBubble({required this.text, required this.isAi});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isAi
              ? AppColors.bgSecondary
              : AppColors.accentGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isAi ? 4 : 14),
            bottomRight: Radius.circular(isAi ? 14 : 4),
          ),
          border: Border.all(
            color: isAi
                ? AppColors.borderSubtle
                : AppColors.accentGreen.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w300,
            color: isAi ? AppColors.textSecondary : AppColors.accentGreen,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
