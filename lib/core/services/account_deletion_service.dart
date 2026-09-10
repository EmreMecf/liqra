import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// KVKK — Hesap ve veri silme servisi
///
/// Silme sırası önemlidir: önce Firestore verisi (kimlik doğrulama hâlâ
/// geçerliyken, güvenlik kuralları yazmaya izin verirken), sonra Auth hesabı.
///
/// Firebase Auth `user.delete()` **yakın zamanlı giriş** ister. Kullanıcı uzun
/// süredir oturumdaysa `requires-recent-login` döner; bu durumda
/// [DeletionResult.requiresReauth] true gelir ve UI kullanıcıdan yeniden
/// giriş yapmasını istemelidir.
class AccountDeletionService {
  AccountDeletionService._();
  static final instance = AccountDeletionService._();

  final _db = FirebaseFirestore.instance;

  /// `users/{uid}` altındaki **tüm** alt koleksiyonlar.
  ///
  /// Firestore'da bir dokümanı silmek alt koleksiyonlarını **silmez**; her biri
  /// tek tek gezilmek zorundadır. Bu liste eksik kalırsa kullanıcı "hesabımı
  /// sil" dediği hâlde verisi sunucuda kalır — hem KVKK/GDPR ihlali hem de
  /// App Store yönergesi 5.1.1(v) ihlalidir.
  ///
  /// Yeni bir alt koleksiyon eklendiğinde **buraya da** eklenmeli;
  /// `account_deletion_test.dart` listeyi kod tabanıyla karşılaştırır.
  ///
  /// `accounts` listede yok: kendi altında `accountTransactions` taşıdığı için
  /// ondan önce ayrıca temizlenir.
  @visibleForTesting
  static const subcollections = <String>[
    'transactions',
    'assets',
    'goals',
    'subscriptions',
    'loans',
    // Bütçe limitleri burada durur (settings/budgets). Eskiden listede yoktu:
    // hesap silindikten sonra Firestore'da yetim kalıyordu.
    'settings',
  ];

  /// Hesabı ve tüm verilerini kalıcı olarak siler.
  Future<DeletionResult> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const DeletionResult.failure('Oturum bulunamadı.');
    }
    final uid = user.uid;

    try {
      // 1) Firestore verisi
      await _deleteUserData(uid);

      // 2) Auth hesabı
      await user.delete();

      return const DeletionResult.success();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return const DeletionResult.reauthRequired();
      }
      debugPrint('[AccountDeletion] Auth hatası: ${e.code}');
      return DeletionResult.failure(
        'Hesap silinemedi (${e.code}). Lütfen tekrar deneyin.',
      );
    } catch (e) {
      debugPrint('[AccountDeletion] Hata: $e');
      return DeletionResult.failure('Hesap silinemedi: $e');
    }
  }

  /// users/{uid} altındaki tüm veriyi siler (Auth hesabına dokunmaz).
  Future<void> _deleteUserData(String uid) async {
    final userDoc = _db.collection('users').doc(uid);

    // accounts → her hesabın accountTransactions alt koleksiyonu önce silinir
    final accountsSnap = await userDoc.collection('accounts').get();
    for (final acc in accountsSnap.docs) {
      await _deleteCollection(acc.reference.collection('accountTransactions'));
    }
    await _deleteCollection(userDoc.collection('accounts'));

    for (final name in subcollections) {
      await _deleteCollection(userDoc.collection(name));
    }

    await userDoc.delete();
  }

  /// Bir koleksiyonu 400'lük batch'ler hâlinde siler (Firestore limiti 500).
  Future<void> _deleteCollection(CollectionReference<Object?> ref) async {
    const pageSize = 400;
    while (true) {
      final snap = await ref.limit(pageSize).get();
      if (snap.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snap.docs.length < pageSize) return;
    }
  }

  /// E-posta + şifre ile yeniden kimlik doğrulama (requires-recent-login sonrası)
  Future<bool> reauthenticateWithPassword(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) return false;
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
      return true;
    } catch (e) {
      debugPrint('[AccountDeletion] Yeniden doğrulama başarısız: $e');
      return false;
    }
  }
}

/// Silme işleminin sonucu
class DeletionResult {
  final bool succeeded;
  final bool requiresReauth;
  final String? errorMessage;

  const DeletionResult.success()
      : succeeded = true,
        requiresReauth = false,
        errorMessage = null;

  const DeletionResult.reauthRequired()
      : succeeded = false,
        requiresReauth = true,
        errorMessage =
            'Güvenlik için hesabınızı silmeden önce yeniden giriş yapmanız gerekiyor.';

  const DeletionResult.failure(String message)
      : succeeded = false,
        requiresReauth = false,
        errorMessage = message;
}
