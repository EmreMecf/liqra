import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../models/transaction_dto.dart';
import 'spending_local_datasource.dart';

/// Firestore tabanlı işlem veri kaynağı
/// Kullanıcı verisi users/{uid}/transactions koleksiyonunda saklanır
class SpendingFirestoreDataSource implements SpendingLocalDataSource {
  final _fs = FirestoreService.instance;

  String get _uid => AuthService.instance.userId ?? '';

  @override
  Future<List<TransactionDto>> getTransactions() async {
    if (_uid.isEmpty) return [];
    final snap = await _fs.transactions(_uid)
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return TransactionDto.fromJson(data);
    }).toList();
  }

  @override
  Future<TransactionDto> addTransaction(TransactionDto dto) async {
    if (_uid.isEmpty) return dto;
    final data = dto.toJson();
    data.remove('id'); // Firestore kendi ID'sini atar
    await _fs.transactions(_uid).doc(dto.id).set(data);
    return dto;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    if (_uid.isEmpty) return;
    await _fs.transactions(_uid).doc(id).delete();
  }
}
