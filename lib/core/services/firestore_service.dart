import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore koleksiyon yardımcısı
/// users/{uid}/transactions, users/{uid}/assets, users/{uid}/goals
class FirestoreService {
  FirestoreService._() {
    // Offline cache — internet olmadan da çalışır, veriler cihazda saklanır
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes:     Settings.CACHE_SIZE_UNLIMITED,
    );
  }
  static final instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  // ── Koleksiyon referansları ────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> transactions(String uid) =>
      _db.collection('users').doc(uid).collection('transactions');

  CollectionReference<Map<String, dynamic>> assets(String uid) =>
      _db.collection('users').doc(uid).collection('assets');

  CollectionReference<Map<String, dynamic>> goals(String uid) =>
      _db.collection('users').doc(uid).collection('goals');

  CollectionReference<Map<String, dynamic>> accounts(String uid) =>
      _db.collection('users').doc(uid).collection('accounts');

  CollectionReference<Map<String, dynamic>> accountTransactions(
          String uid, String accountId) =>
      _db
          .collection('users')
          .doc(uid)
          .collection('accounts')
          .doc(accountId)
          .collection('accountTransactions');

  CollectionReference<Map<String, dynamic>> subscriptions(String uid) =>
      _db.collection('users').doc(uid).collection('subscriptions');

  // ── Yardımcı ──────────────────────────────────────────────────────────────

  /// Timestamp → ISO string
  static String tsToIso(Timestamp ts) => ts.toDate().toIso8601String();

  /// DateTime → Timestamp
  static Timestamp dateToTs(DateTime dt) => Timestamp.fromDate(dt);
}
