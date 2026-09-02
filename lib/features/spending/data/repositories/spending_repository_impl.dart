import 'package:uuid/uuid.dart';
import '../../../../core/utils/result.dart';
import '../../../../data/models/money_flow.dart';
import '../../../../data/models/transaction_model.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/spending_repository.dart';
import '../datasources/spending_local_datasource.dart';
import '../models/transaction_dto.dart';

class SpendingRepositoryImpl implements SpendingRepository {
  final SpendingLocalDataSource _local;
  static const _uuid = Uuid();

  const SpendingRepositoryImpl(this._local);

  @override
  Future<Result<List<TransactionEntity>>> getTransactions({
    String? userId,
    DateTime? from,
    DateTime? to,
    String? category,
  }) async {
    try {
      final dtos = await _local.getTransactions();
      var entities = dtos.map(_dtoToEntity).toList();

      if (from != null) {
        entities = entities.where((t) => !t.date.isBefore(from)).toList();
      }
      if (to != null) {
        entities = entities.where((t) => t.date.isBefore(to)).toList();
      }
      if (category != null) {
        // İki tarafı da slug'a normalize et — etiket/slug karışımı olabilir
        final wanted = TransactionCategoryX.slugOf(category);
        entities = entities
            .where((t) => TransactionCategoryX.slugOf(t.category) == wanted)
            .toList();
      }

      return Success(entities);
    } catch (e) {
      return Failure(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<TransactionEntity>> addTransaction(TransactionEntity tx) async {
    try {
      final dto = _entityToDto(tx);
      final saved = await _local.addTransaction(dto);
      return Success(_dtoToEntity(saved));
    } catch (e) {
      return Failure(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteTransaction(String id) async {
    try {
      await _local.deleteTransaction(id);
      return const Success(null);
    } catch (e) {
      return Failure(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<MonthlySummaryEntity>> getMonthlySummary(
      int year, int month) async {
    try {
      final dtos = await _local.getTransactions();
      final entities = dtos.map(_dtoToEntity).toList();

      final monthly = entities.where(
        (t) => t.date.year == year && t.date.month == month,
      );

      double income = 0, expenses = 0;
      final Map<String, double> byCategory = {};

      // TEK gider tanımı: flow.countsAsExpense.
      // Yatırım, transfer ve kart ödemesi gider sayılmaz; kategori dağılımına
      // da girmez — böylece pastanın dilimleri ortadaki toplamı tutar.
      for (final tx in monthly) {
        if (tx.flow.countsAsIncome) {
          income += tx.amount;
          continue;
        }
        if (!tx.flow.countsAsExpense) continue;

        expenses += tx.amount;
        final slug = TransactionCategoryX.slugOf(tx.category);
        byCategory[slug] = (byCategory[slug] ?? 0) + tx.amount;
      }

      return Success(MonthlySummaryEntity(
        totalIncome: income,
        totalExpenses: expenses,
        netCash: income - expenses,
        byCategory: byCategory,
        year: year,
        month: month,
      ));
    } catch (e) {
      return Failure(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<TransactionEntity>>> getCurrentMonthTransactions() {
    final now = DateTime.now();
    return getTransactions(
      from: DateTime(now.year, now.month, 1),
      to: DateTime(now.year, now.month + 1, 1),
    );
  }

  // ── Dönüşümler ────────────────────────────────────────────────────────────

  TransactionEntity _dtoToEntity(TransactionDto dto) => TransactionEntity(
        id: dto.id,
        userId: dto.userId,
        amount: dto.amount,
        category: dto.category,
        type: dto.type,
        source: dto.source,
        date: DateTime.tryParse(dto.date) ?? DateTime.now(),
        note: dto.note,
        // Eski kayıtlarda `flow` yok — type + kategoriden türetilir.
        flow: MoneyFlowParser.parse(
          rawFlow: dto.flow,
          rawType: dto.type,
          categorySlug: TransactionCategoryX.slugOf(dto.category),
        ),
        accountId: dto.accountId,
      );

  TransactionDto _entityToDto(TransactionEntity entity) => TransactionDto(
        id: entity.id.isEmpty ? _uuid.v4() : entity.id,
        userId: entity.userId,
        amount: entity.amount,
        category: entity.category,
        type: entity.type,
        source: entity.source,
        date: entity.date.toIso8601String(),
        note: entity.note,
        flow: entity.flow.slug,
        accountId: entity.accountId,
      );
}
