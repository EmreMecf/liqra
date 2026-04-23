import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/auth_service.dart';
import '../../domain/entities/financial_account_entity.dart';
import '../../domain/entities/loan_entity.dart';

/// Kredi Firestore veri kaynağı
/// users/{uid}/loans/{loanId}
class LoanFirestoreDataSource {
  final _db = FirebaseFirestore.instance;

  String get _uid => AuthService.instance.userId ?? '';

  CollectionReference<Map<String, dynamic>> _loans(String uid) =>
      _db.collection('users').doc(uid).collection('loans');

  // ── Okuma ─────────────────────────────────────────────────────────────────

  Future<List<LoanEntity>> getLoans(String uid) async {
    if (uid.isEmpty) return [];
    final snap =
        await _loans(uid).orderBy('createdAt', descending: false).get();
    return snap.docs
        .map((doc) => _fromDoc(doc.id, doc.data(), uid))
        .toList();
  }

  // ── Yazma ─────────────────────────────────────────────────────────────────

  Future<void> addLoan(LoanEntity loan) async {
    final uid = loan.userId.isNotEmpty ? loan.userId : _uid;
    if (uid.isEmpty) return;
    await _loans(uid).doc(loan.id).set(_toMap(loan));
  }

  Future<void> updateLoan(LoanEntity loan) async {
    final uid = loan.userId.isNotEmpty ? loan.userId : _uid;
    if (uid.isEmpty) return;
    await _loans(uid).doc(loan.id).update(_toMap(loan));
  }

  Future<void> deleteLoan(String uid, String loanId) async {
    if (uid.isEmpty) return;
    await _loans(uid).doc(loanId).delete();
  }

  /// Taksit ödemesi — batch ile atomik güncelleme
  Future<void> recordPayment({
    required String uid,
    required LoanEntity loan,
    required double amount,
  }) async {
    if (uid.isEmpty) return;
    final docRef = _loans(uid).doc(loan.id);
    final batch = _db.batch();

    final newRemaining = loan.remainingInstallments - 1;
    final isCompleted = newRemaining <= 0;

    batch.update(docRef, {
      'remainingAmount': FieldValue.increment(-amount),
      'remainingInstallments': isCompleted ? 0 : FieldValue.increment(-1),
      if (isCompleted) 'status': 'completed',
    });

    await batch.commit();
  }

  // ── Dönüşüm yardımcıları ─────────────────────────────────────────────────

  Map<String, dynamic> _toMap(LoanEntity loan) {
    return {
      'name': loan.name,
      'bank': loan.bank.name,
      'totalAmount': loan.totalAmount,
      'remainingAmount': loan.remainingAmount,
      'monthlyPayment': loan.monthlyPayment,
      'interestRate': loan.interestRate,
      'totalInstallments': loan.totalInstallments,
      'remainingInstallments': loan.remainingInstallments,
      'paymentDueDay': loan.paymentDueDay,
      'startDate': Timestamp.fromDate(loan.startDate),
      'createdAt': Timestamp.fromDate(loan.createdAt),
      'currency': loan.currency,
      'note': loan.note,
      'status': loan.status,
    };
  }

  LoanEntity _fromDoc(
      String id, Map<String, dynamic> data, String uid) {
    BankName bank;
    try {
      bank = BankName.values.firstWhere(
        (b) => b.name == (data['bank'] as String? ?? ''),
        orElse: () => BankName.other,
      );
    } catch (_) {
      bank = BankName.other;
    }

    DateTime parseTs(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return DateTime.now();
    }

    return LoanEntity(
      id: id,
      userId: uid,
      name: data['name'] as String? ?? '',
      bank: bank,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (data['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      monthlyPayment: (data['monthlyPayment'] as num?)?.toDouble() ?? 0.0,
      interestRate: (data['interestRate'] as num?)?.toDouble() ?? 0.0,
      totalInstallments: (data['totalInstallments'] as num?)?.toInt() ?? 0,
      remainingInstallments:
          (data['remainingInstallments'] as num?)?.toInt() ?? 0,
      paymentDueDay: (data['paymentDueDay'] as num?)?.toInt() ?? 1,
      startDate: parseTs(data['startDate']),
      createdAt: parseTs(data['createdAt']),
      currency: data['currency'] as String? ?? 'TRY',
      note: data['note'] as String?,
      status: data['status'] as String? ?? 'active',
    );
  }
}
