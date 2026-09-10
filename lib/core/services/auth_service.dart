import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Firebase Authentication servisi
/// Giriş, kayıt, çıkış ve profil persist işlemlerini yönetir
class AuthService extends ChangeNotifier {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();

  User? get firebaseUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  String? get userId => _auth.currentUser?.uid;
  String? get userEmail => _auth.currentUser?.email;

  // Profil tamamlandı mı? (onboarding geçildi mi?)
  bool _profileComplete = false;
  bool get profileComplete => _profileComplete;

  // Auth state stream — main.dart'ta dinlenir
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Başlangıçta SharedPreferences'tan profil durumunu yükle
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        _profileComplete = prefs.getBool('profile_complete_$uid') ?? false;
      }
    } catch (e) {
      debugPrint('[AuthService] init error: $e');
    }
  }

  /// E-posta + şifre ile kayıt
  Future<AuthResult> register({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Doğrulama e-postası gönder. Eskiden hiç gönderilmiyordu: var olmayan
      // bir adresle kayıt olunabiliyor ve o hesap için şifre sıfırlama
      // çalışmıyordu. Gönderim başarısız olsa bile kayıt iptal edilmez —
      // kullanıcı daha sonra tekrar gönderebilir.
      try {
        await cred.user?.sendEmailVerification();
      } catch (e) {
        debugPrint('[AuthService] doğrulama e-postası gönderilemedi: \$e');
      }

      _profileComplete = false;
      notifyListeners();
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_firebaseErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('Beklenmeyen bir hata oluştu.');
    }
  }

  /// E-posta + şifre ile giriş
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Daha önce onboarding geçmişse yükle
      final prefs = await SharedPreferences.getInstance();
      final uid = _auth.currentUser?.uid;
      _profileComplete = uid != null
          ? (prefs.getBool('profile_complete_$uid') ?? false)
          : false;
      notifyListeners();
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_firebaseErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('Beklenmeyen bir hata oluştu.');
    }
  }

  /// Google ile giriş
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Önceki oturumu temizle
      await _googleSignIn.signOut().catchError((_) => null);

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Kullanıcı kendi iptal etti — sessiz hata
        return AuthResult.error('Google girişi iptal edildi.');
      }

      final googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        debugPrint('[AuthService] Google idToken null — OAuth client eksik olabilir');
        return AuthResult.error(
          'Google yapılandırması eksik. Firebase Console\'da SHA-1 ve OAuth client kontrol edin.');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);

      final prefs = await SharedPreferences.getInstance();
      final uid = _auth.currentUser?.uid;
      _profileComplete = uid != null
          ? (prefs.getBool('profile_complete_$uid') ?? false)
          : false;
      notifyListeners();
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] Google FirebaseAuthException: ${e.code} — ${e.message}');
      return AuthResult.error(_firebaseErrorMessage(e.code));
    } on PlatformException catch (e) {
      debugPrint('[AuthService] Google PlatformException: ${e.code} — ${e.message}');
      // sign_in_canceled = kullanıcı iptal etti
      if (e.code == 'sign_in_canceled') {
        return AuthResult.error('Google girişi iptal edildi.');
      }
      // sign_in_failed = yapılandırma sorunu
      return AuthResult.error('Google girişi başarısız: ${e.message}');
    } catch (e) {
      debugPrint('[AuthService] Google error: $e');
      return AuthResult.error('Google girişi başarısız: $e');
    }
  }

  /// Apple ile giriş (sadece iOS)
  /// Apple ile giriş — iOS yerel akışı.
  ///
  /// Daha önce `_auth.signInWithProvider(AppleAuthProvider())` kullanılıyordu.
  /// O yöntem iOS'ta bile tarayıcı tabanlı OAuth akışını açar ve Firebase
  /// Console'da Services ID + yönlendirme URL'si yapılandırılmasını ister;
  /// yapılandırılmadığı için giriş başarısız oluyordu.
  ///
  /// Yerel akışta Apple'ın kendi Face ID'li penceresi açılır, ek yapılandırma
  /// gerekmez. Firebase Console'da yalnızca Apple sağlayıcısının etkin olması
  /// yeterlidir.
  Future<AuthResult> signInWithApple() async {
    try {
      // Apple'a nonce'un SHA-256 özetini gönderiyoruz; Firebase ise ham
      // değeri isteyip kendisi özetleyerek tokenin bu isteğe ait olduğunu
      // doğruluyor. Araya girme saldırılarına karşı zorunlu adım.
      final rawNonce = _generateNonce();

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null) {
        return AuthResult.error('Apple kimlik doğrulaması alınamadı.');
      }

      final userCredential = await _auth.signInWithCredential(
        OAuthProvider('apple.com').credential(
          idToken: idToken,
          rawNonce: rawNonce,
        ),
      );

      final user = userCredential.user;
      if (user == null) {
        return AuthResult.error('Apple girişi başarısız.');
      }

      // Apple ad soyadı YALNIZCA ilk yetkilendirmede döner; sonraki
      // girişlerde null gelir. İlk seferde yakalamazsak bir daha alamayız.
      final ad = [appleCredential.givenName, appleCredential.familyName]
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .join(' ');
      if (ad.isNotEmpty && (user.displayName == null || user.displayName!.isEmpty)) {
        await user.updateDisplayName(ad);
      }

      final prefs = await SharedPreferences.getInstance();
      _profileComplete = prefs.getBool('profile_complete_${user.uid}') ?? false;
      notifyListeners();
      return AuthResult.success();
    } on SignInWithAppleAuthorizationException catch (e) {
      // Kullanıcı pencereyi kapattıysa hata gösterme.
      if (e.code == AuthorizationErrorCode.canceled) {
        return AuthResult.error('Apple girişi iptal edildi.');
      }
      debugPrint('[AuthService] Apple yetkilendirme hatası: ${e.code} — ${e.message}');
      return AuthResult.error('Apple girişi başarısız: ${e.message}');
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] Apple FirebaseAuthException: ${e.code} — ${e.message}');
      // Firebase Console'da Apple sağlayıcısı kapalıysa bu kod gelir.
      if (e.code == 'operation-not-allowed') {
        return AuthResult.error(
          'Apple ile giriş etkin değil. Firebase Console → Authentication → '
          'Sign-in method altından Apple sağlayıcısını açın.',
        );
      }
      return AuthResult.error(_firebaseErrorMessage(e.code));
    } on PlatformException catch (e) {
      debugPrint('[AuthService] Apple PlatformException: ${e.code} — ${e.message}');
      return AuthResult.error(e.message ?? 'Apple girişi başarısız.');
    } catch (e) {
      debugPrint('[AuthService] Apple beklenmeyen hata: $e');
      return AuthResult.error('Apple girişi başarısız.');
    }
  }

  /// Apple'ın istediği rastgele nonce.
  String _generateNonce([int uzunluk = 32]) {
    const karakterler =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final rastgele = Random.secure();
    return List.generate(
      uzunluk,
      (_) => karakterler[rastgele.nextInt(karakterler.length)],
    ).join();
  }

  // ── E-posta doğrulama ──────────────────────────────────────────────────────

  /// Girişli kullanıcının e-postası doğrulanmış mı?
  ///
  /// Google ve Apple ile girenler sağlayıcı tarafından zaten doğrulanmıştır.
  bool get isEmailVerified {
    final user = _auth.currentUser;
    if (user == null) return false;
    if (user.emailVerified) return true;
    // Sosyal girişlerde e-posta sağlayıcı tarafından doğrulanmış sayılır
    return user.providerData.any((p) => p.providerId != 'password');
  }

  /// Doğrulama e-postasını yeniden gönderir.
  Future<AuthResult> resendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return AuthResult.error('Oturum bulunamadı.');
    if (user.emailVerified) return AuthResult.success();

    try {
      await user.sendEmailVerification();
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      // Çok sık istenirse Firebase 'too-many-requests' döner
      return AuthResult.error(_firebaseErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('E-posta gönderilemedi.');
    }
  }

  /// Firebase'den kullanıcıyı yeniden okur — kullanıcı e-postadaki bağlantıya
  /// tıkladıktan sonra uygulamanın bunu görmesi için gerekir.
  Future<bool> reloadUser() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.reload();
      notifyListeners();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      debugPrint('[AuthService] reload hatası: $e');
      return false;
    }
  }

  /// Şifre sıfırlama e-postası gönder
  Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_firebaseErrorMessage(e.code));
    }
  }

  /// Onboarding/profil tamamlandı — kaydet
  Future<void> markProfileComplete() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profile_complete_$uid', true);
    _profileComplete = true;
    notifyListeners();
  }

  /// Çıkış
  Future<void> signOut() async {
    _profileComplete = false;
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut().catchError((_) => null),
    ]);
    notifyListeners();
  }

  /// Firebase hata kodlarını Türkçe mesaja çevir
  String _firebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bu e-posta adresiyle kayıtlı hesap bulunamadı.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'weak-password':
        return 'Şifre en az 6 karakter olmalıdır.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'too-many-requests':
        return 'Çok fazla deneme. Lütfen biraz bekleyin.';
      case 'network-request-failed':
        return 'İnternet bağlantısı yok.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      default:
        return 'Giriş yapılamadı. Lütfen tekrar deneyin.';
    }
  }
}

/// Auth işlemi sonucu
class AuthResult {
  final bool success;
  final String? errorMessage;

  const AuthResult._({required this.success, this.errorMessage});

  factory AuthResult.success() => const AuthResult._(success: true);
  factory AuthResult.error(String msg) =>
      AuthResult._(success: false, errorMessage: msg);
}
