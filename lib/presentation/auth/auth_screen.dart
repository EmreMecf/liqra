import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/auth_service.dart';
import '../widgets/liqra_logo.dart';

/// Giriş / Kayıt ekranı
/// Tab 1: Giriş Yap | Tab 2: Kayıt Ol
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          // Arka plan ışıma efekti (brand identity'den)
          Positioned(
            top: -120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentGreen.withValues(alpha: 0.07),
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
                const SizedBox(height: 56),

                // ── Liqra Wordmark Logo ───────────────────────────────
                Column(
                  children: [
                    // Glow halkası
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accentGreen.withValues(alpha: 0.18),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.liqraBg,
                            border: Border.all(
                              color: AppColors.liqraBdr,
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.currency_exchange_rounded,
                            color: AppColors.accentGreen,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const LiqraLogo(fontSize: 44, showTagline: true, centered: true, showRing: true),
                  ],
                ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.08, end: 0),

            const SizedBox(height: 40),

            // ── Tab Bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.accentGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.bgPrimary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: AppTypography.bodyM
                      .copyWith(fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Giriş Yap'),
                    Tab(text: 'Kayıt Ol'),
                  ],
                ),
              ),
            ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

            const SizedBox(height: 24),

            // ── Form Alanı ────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _LoginForm(onSwitchToRegister: () => _tabController.animateTo(1)),
                  _RegisterForm(onSwitchToLogin: () => _tabController.animateTo(0)),
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

// ── Giriş Formu ──────────────────────────────────────────────────────────────
class _LoginForm extends StatefulWidget {
  final VoidCallback onSwitchToRegister;
  const _LoginForm({required this.onSwitchToRegister});

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final result = await AuthService.instance.login(
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );

    if (!mounted) return;
    if (!result.success) {
      setState(() { _loading = false; _error = result.errorMessage; });
    }
    // Başarıda main.dart'taki StreamBuilder otomatik yönlendirir
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    final result = await AuthService.instance.signInWithGoogle();
    if (!mounted) return;
    if (!result.success) {
      setState(() { _loading = false; _error = result.errorMessage; });
    }
  }

  Future<void> _signInWithApple() async {
    setState(() { _loading = true; _error = null; });
    final result = await AuthService.instance.signInWithApple();
    if (!mounted) return;
    if (!result.success) {
      setState(() { _loading = false; _error = result.errorMessage; });
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Şifre sıfırlamak için e-posta girin.');
      return;
    }
    final result = await AuthService.instance.sendPasswordReset(_emailCtrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? 'Şifre sıfırlama e-postası gönderildi.'
              : result.errorMessage ?? 'Hata oluştu.',
        ),
        backgroundColor: result.success ? AppColors.accentGreen : AppColors.accentRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hata mesajı
            if (_error != null) ...[
              _ErrorBanner(message: _error!),
              const SizedBox(height: 16),
            ],

            _AuthField(
              controller: _emailCtrl,
              label: 'E-posta',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            const SizedBox(height: 14),

            _AuthField(
              controller: _passCtrl,
              label: 'Şifre',
              icon: Icons.lock_outline,
              obscure: _obscure,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary, size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'En az 6 karakter' : null,
            ),
            const SizedBox(height: 8),

            // Şifremi unuttum
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _forgotPassword,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Şifremi unuttum',
                    style: AppTypography.bodyS.copyWith(
                      color: AppColors.accentBlue,
                    )),
              ),
            ),
            const SizedBox(height: 24),

            // Giriş Yap butonu
            _SubmitButton(
              label: 'Giriş Yap',
              loading: _loading,
              onPressed: _submit,
            ),

            const SizedBox(height: 24),

            // OR divider
            _OrDivider(),

            const SizedBox(height: 20),

            // Google giriş
            _SocialButton(
              label: 'Google ile Giriş Yap',
              icon: _GoogleIcon(),
              onPressed: _loading ? null : _signInWithGoogle,
            ),

            // Apple giriş — yalnızca iOS'ta
            if (Platform.isIOS) ...[
              const SizedBox(height: 12),
              _SocialButton(
                label: 'Apple ile Giriş Yap',
                icon: const Icon(Icons.apple, color: Colors.white, size: 20),
                onPressed: _loading ? null : _signInWithApple,
              ),
            ],

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Hesabın yok mu? ', style: AppTypography.bodyS),
                GestureDetector(
                  onTap: widget.onSwitchToRegister,
                  child: Text('Kayıt Ol',
                      style: AppTypography.bodyS.copyWith(
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Kayıt Formu ──────────────────────────────────────────────────────────────
class _RegisterForm extends StatefulWidget {
  final VoidCallback onSwitchToLogin;
  const _RegisterForm({required this.onSwitchToLogin});

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final result = await AuthService.instance.register(
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );

    if (!mounted) return;
    if (!result.success) {
      setState(() { _loading = false; _error = result.errorMessage; });
    }
    // Başarıda main.dart'taki StreamBuilder onboarding'e yönlendirir
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              _ErrorBanner(message: _error!),
              const SizedBox(height: 16),
            ],

            _AuthField(
              controller: _emailCtrl,
              label: 'E-posta',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            const SizedBox(height: 14),

            _AuthField(
              controller: _passCtrl,
              label: 'Şifre',
              icon: Icons.lock_outline,
              obscure: _obscure,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary, size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'En az 6 karakter' : null,
            ),
            const SizedBox(height: 14),

            _AuthField(
              controller: _passConfirmCtrl,
              label: 'Şifre Tekrar',
              icon: Icons.lock_outline,
              obscure: _obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary, size: 20,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) =>
                  v != _passCtrl.text ? 'Şifreler eşleşmiyor' : null,
            ),
            const SizedBox(height: 24),

            // Gizlilik notu
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.accentBlue.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined,
                      color: AppColors.accentBlue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Verileriniz yalnızca sizin cihazınızda saklanır. '
                      'Üçüncü taraflarla paylaşılmaz.',
                      style: AppTypography.labelS.copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _SubmitButton(
              label: 'Hesap Oluştur',
              loading: _loading,
              onPressed: _submit,
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Zaten hesabın var mı? ', style: AppTypography.bodyS),
                GestureDetector(
                  onTap: widget.onSwitchToLogin,
                  child: Text('Giriş Yap',
                      style: AppTypography.bodyS.copyWith(
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Ortak Widget'lar ─────────────────────────────────────────────────────────
class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: AppTypography.bodyM.copyWith(color: AppColors.textPrimary),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodyS,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.bgSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.accentGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.accentRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.accentRed, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGreen,
          foregroundColor: AppColors.bgPrimary,
          disabledBackgroundColor: AppColors.accentGreen.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: GoogleFonts.outfit(
            fontSize: 15, fontWeight: FontWeight.w700,
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.accentRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: AppTypography.bodyS.copyWith(
                  color: AppColors.accentRed,
                  height: 1.4,
                )),
          ),
        ],
      ),
    );
  }
}

// ── OR Divider ────────────────────────────────────────────────────────────────
class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: AppColors.borderSubtle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'veya',
            style: AppTypography.labelS.copyWith(color: AppColors.textDisabled),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: AppColors.borderSubtle),
        ),
      ],
    );
  }
}

// ── Social Sign-In Button ─────────────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.borderSubtle),
          backgroundColor: AppColors.bgSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          foregroundColor: AppColors.textPrimary,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Google Icon (SVG-free minimal) ───────────────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleIconPainter()),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final segments = [
      (const Color(0xFF4285F4), -0.1, 0.5),
      (const Color(0xFFEA4335), 0.4, 0.5),
      (const Color(0xFFFBBC05), 0.9, 0.5),
      (const Color(0xFF34A853), 1.4, 0.5),
    ];

    for (final seg in segments) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        seg.$2 * 3.14159,
        seg.$3 * 3.14159,
        true,
        Paint()..color = seg.$1,
      );
    }

    // White center
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.62,
      Paint()..color = AppColors.bgSecondary,
    );

    // Blue right bar
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.28, r * 0.9, r * 0.56),
      Paint()..color = const Color(0xFF4285F4),
    );
    canvas.drawCircle(
      Offset(cx + r * 0.46, cy),
      r * 0.28,
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

String? _validateEmail(String? v) {
  if (v == null || v.trim().isEmpty) return 'E-posta gerekli';
  final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$');
  if (!emailRegex.hasMatch(v.trim())) return 'Geçerli bir e-posta girin';
  return null;
}
