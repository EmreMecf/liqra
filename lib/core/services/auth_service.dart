import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
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
  Future<AuthResult> signInWithApple() async {
    try {
      final appleProvider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('fullName');
      final userCredential = await _auth.signInWithProvider(appleProvider);
      if (userCredential.user == null) {
        return AuthResult.error('Apple girişi başarısız.');
      }
      final prefs = await SharedPreferences.getInstance();
      final uid = _auth.currentUser?.uid;
      _profileComplete = uid != null
          ? (prefs.getBool('profile_complete_$uid') ?? false)
          : false;
      notifyListeners();
      return AuthResult.success();
    } on PlatformException catch (e) {
      return AuthResult.error(e.message ?? 'Apple girişi başarısız.');
    } catch (e) {
      return AuthResult.error('Apple girişi başarısız.');
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
