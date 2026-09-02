import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';

/// Ekranın üstünde duran ince durum bandı.
class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Banner({
    required this.icon,
    required this.color,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      color: color.withValues(alpha: 0.12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.outfit(fontSize: 12.5, color: color),
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onAction,
                child: Text(
                  actionLabel!,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// E-postası doğrulanmamış kullanıcıya gösterilen band.
///
/// Kayıt sırasında doğrulama e-postası gönderiliyor ama kullanıcı tıklamayı
/// unutabiliyor. Doğrulanmamış hesapta şifre sıfırlama işe yaramaz, bu yüzden
/// hatırlatma görünür yerde durur.
class EmailVerificationBanner extends StatefulWidget {
  const EmailVerificationBanner({super.key});

  @override
  State<EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState extends State<EmailVerificationBanner> {
  bool _sending = false;
  bool _sent = false;

  Future<void> _resend() async {
    setState(() => _sending = true);
    final result = await AuthService.instance.resendEmailVerification();
    if (!mounted) return;

    setState(() {
      _sending = false;
      _sent = result.success;
    });

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'E-posta gönderilemedi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        if (AuthService.instance.isEmailVerified) {
          return const SizedBox.shrink();
        }

        return _Banner(
          icon: Icons.mark_email_unread_outlined,
          color: AppColors.accentAmber,
          message: _sent
              ? 'Doğrulama e-postası gönderildi. Gelen kutunu kontrol et.'
              : 'E-posta adresin doğrulanmadı.',
          actionLabel: _sending
              ? '…'
              : _sent
                  ? 'Kontrol et'
                  : 'Tekrar gönder',
          onAction: _sending
              ? null
              : _sent
                  ? () => AuthService.instance.reloadUser()
                  : _resend,
        );
      },
    );
  }
}

/// Piyasa verisi bayatladığında gösterilen band.
///
/// Firestore offline persistence açık olduğu için uygulama internetsiz de
/// çalışıyor — ama kullanıcıya verinin eski olduğu hiç söylenmiyordu; iki gün
/// önceki fiyatlar güncel gibi görünüyordu.
class StaleDataBanner extends StatelessWidget {
  final DateTime? lastUpdated;

  /// Bu süreden eskiyse bayat sayılır. Piyasa verisi 2 dakikada bir
  /// güncelleniyor; 30 dakika sessizlik bağlantı sorununa işaret eder.
  static const staleAfter = Duration(minutes: 30);

  const StaleDataBanner({super.key, required this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    final updated = lastUpdated;
    if (updated == null) return const SizedBox.shrink();

    final age = DateTime.now().difference(updated);
    if (age < staleAfter) return const SizedBox.shrink();

    return _Banner(
      icon: Icons.cloud_off_rounded,
      color: AppColors.textSecondary,
      message: 'Piyasa verisi ${_ago(age)} güncellenmedi — '
          'bağlantını kontrol et.',
    );
  }

  static String _ago(Duration d) {
    if (d.inDays >= 1) return '${d.inDays} gündür';
    if (d.inHours >= 1) return '${d.inHours} saattir';
    return '${d.inMinutes} dakikadır';
  }
}
