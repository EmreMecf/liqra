import '../models/transaction_dto.dart';

/// Yerel veri kaynağı — şimdilik legacy AppProvider mock datası
/// TODO: PostgreSQL REST API ile değiştirilecek (FAZ 4)
abstract interface class SpendingLocalDataSource {
  Future<List<TransactionDto>> getTransactions();
  Future<TransactionDto> addTransaction(TransactionDto dto);
  Future<void> deleteTransaction(String id);
}

class SpendingLocalDataSourceImpl implements SpendingLocalDataSource {
  /// Kullanıcıya ait işlem deposu — boş başlar, kullanıcı kendi ekler
  final List<TransactionDto> _store = [];

  @override
  Future<List<TransactionDto>> getTransactions() async {
    await Future.delayed(const Duration(milliseconds: 50)); // gerçekçi gecikme
    return List.unmodifiable(_store);
  }

  @override
  Future<TransactionDto> addTransaction(TransactionDto dto) async {
    _store.insert(0, dto);
    return dto;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _store.removeWhere((t) => t.id == id);
  }

}
