import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../models/account_transaction_dto.dart';
import '../models/financial_account_dto.dart';

/// Hesaplar datasource sözleşmesi
abstract class AccountsFirestoreDataSource {
  Future<List<FinancialAccountDto>> getAccounts();
  Future<FinancialAccountDto> addAccount(FinancialAccountDto dto);
  Future<void> updateAccount(FinancialAccountDto dto);
  Future<void> deleteAccount(String id);
  Future<List<AccountTransactionDto>> getTransactions(String accountId);
  Future<AccountTransactionDto> addTransaction(AccountTransactionDto dto);
  Future<void> addTransactions(List<AccountTransactionDto> dtos);
  Future<void> deleteTransaction(String accountId, String txId);

  // ── Atomik muhasebe işlemleri ──────────────────────────────────────────────
  Future<void> addTransactionWithBalanceUpdate({
    required AccountTransactionDto tx,
    required String accountId,
    required double balanceDelta,
    String balanceField,
  });
  Future<void> addCreditPaymentBatch({
    required String bankAccountId,
    required String creditCardId,
    required double amount,
    required String txId,
    required DateTime date,
    required String uid,
  });
  Future<void> addTransferBatch({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required String txId,
    required DateTime date,
    required String description,
  });
  Future<void> updateStatementBalance({
    required String cardId,
    required double statementBalance,
    required double minimumPayment,
  });
  Future<void> updateBankBalance({
    required String accountId,
    required double newBalance,
  });
}

/// Firestore tabanlı hesap veri kaynağı
/// users/{uid}/accounts/{accountId}/accountTransactions/{txId}
class AccountsFirestoreDataSourceImpl implements AccountsFirestoreDataSource {
  final _fs = FirestoreService.instance;

  String get _uid => AuthService.instance.userId ?? '';

  @override
  Future<List<FinancialAccountDto>> getAccounts() async {
    if (_uid.isEmpty) return [];
    final snap = await _fs.accounts(_uid).orderBy('createdAt').get();
    return snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data() as Map);
      data['id'] = doc.id;
      return FinancialAccountDto.fromJson(data);
    }).toList();
  }

  @override
  Future<FinancialAccountDto> addAccount(FinancialAccountDto dto) async {
    if (_uid.isEmpty) return dto;
    final data = dto.toJson();
    data.remove('id');
    await _fs.accounts(_uid).doc(dto.id).set(data);
    return dto;
  }

  @override
  Future<void> updateAccount(FinancialAccountDto dto) async {
    if (_uid.isEmpty) return;
    final data = dto.toJson();
    data.remove('id');
    await _fs.accounts(_uid).doc(dto.id).update(data);
  }

  @override
  Future<void> deleteAccount(String id) async {
    if (_uid.isEmpty) return;
    // Önce alt koleksiyonu (accountTransactions) sil
    final txSnap = await _fs.accountTransactions(_uid, id).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in txSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_fs.accounts(_uid).doc(id));
    await batch.commit();
  }

  @override
  Future<List<AccountTransactionDto>> getTransactions(String accountId) async {
    if (_uid.isEmpty) return [];
    final snap = await _fs
        .accountTransactions(_uid, accountId)
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data() as Map);
      data['id'] = doc.id;
      return AccountTransactionDto.fromJson(data);
    }).toList();
  }

  @override
  Future<AccountTransactionDto> addTransaction(
      AccountTransactionDto dto) async {
    if (_uid.isEmpty) return dto;
    final data = dto.toJson();
    data.remove('id');
    await _fs
        .accountTransactions(_uid, dto.accountId)
        .doc(dto.id)
        .set(data);
    return dto;
  }

  @override
  Future<void> addTransactions(List<AccountTransactionDto> dtos) async {
    if (_uid.isEmpty || dtos.isEmpty) return;
    final db = FirebaseFirestore.instance;
    // Firestore batch 500 doc limiti — chunklara böl
    const chunkSize = 400;
    for (var i = 0; i < dtos.length; i += chunkSize) {
      final chunk = dtos.skip(i).take(chunkSize).toList();
      final batch = db.batch();
      for (final dto in chunk) {
        final data = dto.toJson();
        data.remove('id');
        final ref =
            _fs.accountTransactions(_uid, dto.accountId).doc(dto.id);
        batch.set(ref, data);
      }
      await batch.commit();
    }
  }

  @override
  Future<void> deleteTransaction(String accountId, String txId) async {
    if (_uid.isEmpty) return;
    await _fs.accountTransactions(_uid, accountId).doc(txId).delete();
  }

  // ── Atomik muhasebe işlemleri ──────────────────────────────────────────────

  /// Atomik: işlem yaz + hesap bakiyesini güncelle
  @override
  Future<void> addTransactionWithBalanceUpdate({
    required AccountTransactionDto tx,
    required String accountId,
    required double balanceDelta,
    String balanceField = 'balance',
  }) async {
    if (_uid.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    final data = tx.toJson()..remove('id');
    batch.set(_fs.accountTransactions(_uid, accountId).doc(tx.id), data);
    batch.update(_fs.accounts(_uid).doc(accountId), {
      balanceField: FieldValue.increment(balanceDelta),
    });
    await batch.commit();
  }

  /// Atomik: kredi kartı ödemesi — banka bakiyesi düşer, kart borcu azalır
  @override
  Future<void> addCreditPaymentBatch({
    required String bankAccountId,
    required String creditCardId,
    required double amount,
    required String txId,
    required DateTime date,
    required String uid,
  }) async {
    if (_uid.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    final now = Timestamp.fromDate(date);

    // Banka: gider işlemi
    batch.set(_fs.accountTransactions(_uid, bankAccountId).doc('${txId}_b'), {
      'accountId': bankAccountId,
      'userId': _uid,
      'amount': amount,
      'description': 'Kredi Kartı Ödemesi',
      'date': now,
      'type': 'creditPayment',
      'category': creditCardId,
      'isInstallment': false,
      'installmentCount': 1,
      'installmentNumber': 1,
      'source': 'manual',
    });
    batch.update(_fs.accounts(_uid).doc(bankAccountId), {
      'balance': FieldValue.increment(-amount),
    });

    // Kart: ödeme alındı işlemi
    batch.set(_fs.accountTransactions(_uid, creditCardId).doc('${txId}_c'), {
      'accountId': creditCardId,
      'userId': _uid,
      'amount': amount,
      'description': 'Ödeme Alındı',
      'date': now,
      'type': 'income',
      'category': 'odeme',
      'isInstallment': false,
      'installmentCount': 1,
      'installmentNumber': 1,
      'source': 'manual',
    });
    batch.update(_fs.accounts(_uid).doc(creditCardId), {
      'usedAmount': FieldValue.increment(-amount),
      'statementBalance': FieldValue.increment(-amount),
    });

    await batch.commit();
  }

  /// Atomik: iki banka hesabı arasında transfer
  @override
  Future<void> addTransferBatch({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required String txId,
    required DateTime date,
    required String description,
  }) async {
    if (_uid.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    final now = Timestamp.fromDate(date);

    // Gönderen hesap: gider
    batch.set(
        _fs.accountTransactions(_uid, fromAccountId).doc('${txId}_from'), {
      'accountId': fromAccountId,
      'userId': _uid,
      'amount': amount,
      'description': description.isEmpty ? 'Transfer Gönderildi' : description,
      'date': now,
      'type': 'transfer',
      'category': toAccountId,
      'isInstallment': false,
      'installmentCount': 1,
      'installmentNumber': 1,
      'source': 'manual',
    });
    batch.update(_fs.accounts(_uid).doc(fromAccountId), {
      'balance': FieldValue.increment(-amount),
    });

    // Alıcı hesap: gelir
    batch.set(_fs.accountTransactions(_uid, toAccountId).doc('${txId}_to'), {
      'accountId': toAccountId,
      'userId': _uid,
      'amount': amount,
      'description': description.isEmpty ? 'Transfer Alındı' : description,
      'date': now,
      'type': 'income',
      'category': fromAccountId,
      'isInstallment': false,
      'installmentCount': 1,
      'installmentNumber': 1,
      'source': 'manual',
    });
    batch.update(_fs.accounts(_uid).doc(toAccountId), {
      'balance': FieldValue.increment(amount),
    });

    await batch.commit();
  }

  /// Ekstre değerlerini güncelle
  @override
  Future<void> updateStatementBalance({
    required String cardId,
    required double statementBalance,
    required double minimumPayment,
  }) async {
    if (_uid.isEmpty) return;
    await _fs.accounts(_uid).doc(cardId).update({
      'statementBalance': statementBalance,
      'minimumPayment': minimumPayment,
    });
  }

  /// Banka bakiyesini direkt güncelle
  @override
  Future<void> updateBankBalance({
    required String accountId,
    required double newBalance,
  }) async {
    if (_uid.isEmpty) return;
    await _fs.accounts(_uid).doc(accountId).update({'balance': newBalance});
  }
}
