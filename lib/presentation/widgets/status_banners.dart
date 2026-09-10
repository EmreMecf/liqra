import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';

/// Ekranın üstünde duran ince durum bandı.
class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Verilirse sağda bir kapatma düğmesi çıkar. Kalıcı bantlar kullanıcıyı
  /// bunaltıyor; kapatılabilir olması gerekiyor.
  final VoidCallback? onDismiss;

  const _Banner({
    required this.icon,
    required this.color,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        // Bant kaydırılabilir alanın dışında sabit duruyor. Kenarlık olmadan
        // altından geçen içerikle görsel olarak birbirine karışıyordu.
        border: Border(
          bottom: BorderSide(color: color.withValues(alpha: 0.25)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 9, 8, 9),
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
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    // Dokunma alanını büyütmek için — ikon 14px, hedef 36px.
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 11),
                    child: Icon(Icons.close_rounded,
                        size: 14, color: color.withValues(alpha: 0.7)),
                  ),
                )
              else
                const SizedBox(width: 8),
            ],
          ),
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
  /// Kapatma zamanı — SharedPreferences anahtarı.
  static const _kapatmaAnahtari = 'email_banner_kapatildi';

  /// Kapatıldıktan sonra bu süre boyunca gösterilmez. Tamamen susturmuyoruz:
  /// doğrulanmamış hesapta şifre sıfırlama çalışmıyor, bir süre sonra
  /// hatırlatmak gerekiyor.
  static const _erteleme = Duration(days: 3);

  bool _sending = false;
  bool _sent = false;
  bool _kapatildi = false;

  /// Tercih okunana kadar bant çizilmez — aksi halde her açılışta bir an
  /// görünüp kayboluyor.
  bool _durumYuklendi = false;

  @override
  void initState() {
    super.initState();
    _kapatmaDurumunuYukle();
  }

  Future<void> _kapatmaDurumunuYukle() async {
    bool kapali = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_kapatmaAnahtari);
      if (ms != null) {
        final kapatmaZamani = DateTime.fromMillisecondsSinceEpoch(ms);
        kapali = DateTime.now().difference(kapatmaZamani) < _erteleme;
      }
    } catch (e) {
      debugPrint('[EmailBanner] kapatma durumu okunamadı: $e');
    }
    if (!mounted) return;
    setState(() {
      _kapatildi = kapali;
      _durumYuklendi = true;
    });
  }

  Future<void> _kapat() async {
    setState(() => _kapatildi = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _kapatmaAnahtari, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Kaydedilemezse yalnızca bu oturum boyunca kapalı kalır — kabul edilir.
      debugPrint('[EmailBanner] kapatma kaydedilemedi: $e');
    }
  }

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
    if (!_durumYuklendi || _kapatildi) return const SizedBox.shrink();

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
          onDismiss: _kapat,
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
