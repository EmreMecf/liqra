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
}
