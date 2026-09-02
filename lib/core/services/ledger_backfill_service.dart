import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/money_flow.dart';
import 'auth_service.dart';
import 'firestore_service.dart';

/// Geçmiş cüzdan hareketlerini ana deftere taşır — kullanıcı başına BİR KEZ.
///
/// ── Neden gerekli ───────────────────────────────────────────────────────────
/// Cüzdan hareketleri (banka/kart harcaması, gelir, transfer) eskiden yalnızca
/// `accounts/{id}/accountTransactions` altına yazılıyordu. Dashboard bu
/// koleksiyonu okumadığı için kredi kartı harcamaları hiçbir toplamda
/// görünmüyordu. Artık her hareket ana deftere de yazılıyor — ancak
/// GEÇMİŞ kayıtlar orada olmadığı için Dashboard eksik bir tarih gösterirdi.
///
/// ── Neden güvenli ───────────────────────────────────────────────────────────
/// Ana defter kaydı, hesap hareketiyle **aynı doküman ID'sini** kullanır.
/// Bu yüzden işlem **idempotenttir**: iki kez çalışsa bile aynı dokümanların
/// üzerine yazar, kopya oluşturmaz. Yarıda kalırsa bayrak yazılmaz ve bir
/// sonraki açılışta kaldığı yerden değil baştan — ama yine güvenle — çalışır.
class LedgerBackfillService {
  LedgerBackfillService._();
  static final instance = LedgerBackfillService._();

  static const _flagPrefix = 'ledger_backfill_v1_';

  /// Firestore batch 500 doküman limiti
  static const _chunkSize = 400;

  /// Gerekiyorsa taşımayı yapar. Zaten yapıldıysa hiçbir şey yapmaz.
  Future<void> runIfNeeded() async {
    final uid = AuthService.instance.userId;
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = '$_flagPrefix$uid';
    if (prefs.getBool(key) ?? false) return;

    try {
      final moved = await _backfill(uid);
      await prefs.setBool(key, true);
      debugPrint('[LedgerBackfill] ✓ $moved hareket ana deftere taşındı.');
    } catch (e) {
      // Bayrak yazılmaz — bir sonraki açılışta tekrar denenir.
      debugPrint('[LedgerBackfill] ✗ Taşıma başarısız: $e');
    }
  }

  Future<int> _backfill(String uid) async {
    final fs = FirestoreService.instance;
    final db = FirebaseFirestore.instance;

    final accountsSnap = await fs.accounts(uid).get();
    if (accountsSnap.docs.isEmpty) return 0;

    // Ana defterde zaten bulunan id'ler — gereksiz yazma yapma
    final existing = <String>{};
    final ledgerSnap = await fs.transactions(uid).get();
    for (final d in ledgerSnap.docs) {
      existing.add(d.id);
    }

    final pending = <MapEntry<String, Map<String, dynamic>>>[];

    for (final acc in accountsSnap.docs) {
      final txSnap = await fs.accountTransactions(uid, acc.id).get();
      for (final tx in txSnap.docs) {
        if (existing.contains(tx.id)) continue;

        final d = tx.data();
        final amount = (d['amount'] as num?)?.toDouble() ?? 0;
        if (amount <= 0) continue;

        final category = d['category'] as String? ?? 'diger';
        final flow = MoneyFlowParser.parse(
          rawFlow: d['flow'] as String?,
          rawType: d['type'] as String?,
          categorySlug: category,
        );

        pending.add(MapEntry(tx.id, {
          'userId':    uid,
          'amount':    amount,
          'category':  category,
          'type':      flow.countsAsIncome ? 'income' : 'expense',
          'source':    d['source'] as String? ?? 'wallet',
          'date':      _isoDate(d['date']),
          'note':      d['description'] as String?,
          'flow':      flow.slug,
          'accountId': acc.id,
        }));
      }
    }

    for (var i = 0; i < pending.length; i += _chunkSize) {
      final chunk = pending.skip(i).take(_chunkSize);
      final batch = db.batch();
      for (final e in chunk) {
        batch.set(fs.transactions(uid).doc(e.key), e.value);
      }
      await batch.commit();
    }

    return pending.length;
  }

  /// Eski kayıtlarda tarih hem ISO string hem Timestamp olabilir.
  String _isoDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate().toIso8601String();
    if (raw is String && raw.isNotEmpty) return raw;
    return DateTime.now().toIso8601String();
  }
}
