import 'package:uuid/uuid.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/account_transaction_entity.dart';
import '../../domain/entities/financial_account_entity.dart';
import '../../domain/repositories/accounts_repository.dart';
import '../datasources/accounts_firestore_datasource.dart';
import '../models/account_transaction_dto.dart';
import '../models/financial_account_dto.dart';

class AccountsRepositoryImpl implements AccountsRepository {
  final AccountsFirestoreDataSource _ds;
  static const _uuid = Uuid();

  const AccountsRepositoryImpl(this._ds);

  String get _uid => AuthService.instance.userId ?? '';

  // ── Accounts ──────────────────────────────────────────────────────────────

  @override
  Future<Result<List<FinancialAccountEntity>>> getAccounts() async {
    try {
      final dtos = await _ds.getAccounts();
      final entities = dtos.map(_dtoToEntity).whereType<FinancialAccountEntity>().toList();
      return Success(entities);
    } catch (e) {
      return Failure(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<FinancialAccountEntity>> addAccount(
      FinancialAccountEntity account) async {
    try {
      final dto = _entityToDto(account);
      final saved = await _ds.addAccount(dto);
      final entity = _dtoToEntity(saved);
      if (entity == null) {
        return Failure(const CacheFailure('Hesap dönüştürülemedi'));
      }
      return Success(entity);
    } catch (e) {
      return Failure(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateAccount(FinancialAccountEntity account) async {
    try {
      final dto = _entityToDto(account);
      await _ds.updateAccount(dto);
      return const Success(null);
    } catch (e) {
      return Failure(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteAccount(String id) async {
    try {
      await _ds.deleteAccount(id);
      return const Success(null);
    } catch (e) {
      return Failure(CacheFailure(e.toString()));
    }
  }

  // ── Transactions ──────────────────────────────────────────────────────────

  @override
  Future<Result<List<AccountTransactionEntity>>> getTransactions(
      String accountId) async {
    try {
      final dtos = await _ds.getTransactions(accountId);
      final entities = dtos.map(_txDtoToEntity).toList();
      return Success(entities);
    } catch (e) {
      return Failure(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<AccountTransactionEntity>> addTransaction(
      AccountTransactionEntity tx) async {
    try {
      final dto = _txEntityToDto(tx);
      final saved = await _ds.addTransaction(dto);
      return Success(_txDtoToEntity(saved));
    } catch (e) {
      return Failure(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> importStatementTransactions(
      String accountId, List<AccountTransactionEntity> transactions) async {
    try {
      final dtos = transactions.map(_txEntityToDto).toList();
      await _ds.addTransactions(dtos);
      return const Success(null);
    } catch (e) {
      return Failure(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteTransaction(
      String accountId, String txId) async {
    try {
      await _ds.deleteTransaction(accountId, txId);
      return const Success(null);
    } catch (e) {
      return Failure(CacheFailure(e.toString()));
    }
  }

  // ── DTO <-> Entity dönüşümleri ─────────────────────────────────────────────

  FinancialAccountEntity? _dtoToEntity(FinancialAccountDto dto) {
    try {
      final bank = BankName.values.firstWhere(
        (b) => b.name == dto.bank,
        orElse: () => BankName.other,
      );
      final createdAt = DateTime.tryParse(dto.createdAt) ?? DateTime.now();

      if (dto.type == 'bankAccount') {
        return FinancialAccountEntity.bankAccount(
          id: dto.id,
          userId: dto.userId,
          name: dto.name,
          bank: bank,
          balance: dto.balance ?? 0.0,
          currency: dto.currency,
          iban: dto.iban,
          maskedAccountNumber: dto.maskedAccountNumber,
          createdAt: createdAt,
        );
      } else if (dto.type == 'creditCard') {
        return FinancialAccountEntity.creditCard(
          id: dto.id,
          userId: dto.userId,
          name: dto.name,
          bank: bank,
          creditLimit: dto.creditLimit ?? 0.0,
          usedAmount: dto.usedAmount ?? 0.0,
          statementBalance: dto.statementBalance ?? 0.0,
          minimumPayment: dto.minimumPayment ?? 0.0,
          statementClosingDay: dto.statementClosingDay ?? 1,
          paymentDueDay: dto.paymentDueDay ?? 1,
          maskedCardNumber: dto.maskedCardNumber,
          currency: dto.currency,
          createdAt: createdAt,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  FinancialAccountDto _entityToDto(FinancialAccountEntity entity) {
    return entity.when(
      bankAccount: (id, userId, name, bank, balance, currency, iban,
              maskedAccountNumber, createdAt) =>
          FinancialAccountDto(
        id: id.isEmpty ? _uuid.v4() : id,
        userId: userId.isEmpty ? _uid : userId,
        type: 'bankAccount',
        name: name,
        bank: bank.name,
        currency: currency,
        createdAt: createdAt.toIso8601String(),
        balance: balance,
        iban: iban,
        maskedAccountNumber: maskedAccountNumber,
      ),
      creditCard: (id, userId, name, bank, creditLimit, usedAmount,
              statementBalance, minimumPayment, statementClosingDay,
              paymentDueDay, maskedCardNumber, currency, createdAt) =>
          FinancialAccountDto(
        id: id.isEmpty ? _uuid.v4() : id,
        userId: userId.isEmpty ? _uid : userId,
        type: 'creditCard',
        name: name,
        bank: bank.name,
        currency: currency,
        createdAt: createdAt.toIso8601String(),
        creditLimit: creditLimit,
        usedAmount: usedAmount,
        statementBalance: statementBalance,
        minimumPayment: minimumPayment,
        statementClosingDay: statementClosingDay,
        paymentDueDay: paymentDueDay,
        maskedCardNumber: maskedCardNumber,
      ),
    );
  }

  AccountTransactionEntity _txDtoToEntity(AccountTransactionDto dto) =>
      AccountTransactionEntity(
        id: dto.id,
        accountId: dto.accountId,
        userId: dto.userId,
        amount: dto.amount,
        description: dto.description,
        date: DateTime.tryParse(dto.date) ?? DateTime.now(),
        type: dto.type,
        category: dto.category,
        isInstallment: dto.isInstallment,
        installmentCount: dto.installmentCount,
        installmentNumber: dto.installmentNumber,
        merchantName: dto.merchantName,
        statementId: dto.statementId,
        source: dto.source,
      );

  AccountTransactionDto _txEntityToDto(AccountTransactionEntity entity) =>
      AccountTransactionDto(
        id: entity.id.isEmpty ? _uuid.v4() : entity.id,
        accountId: entity.accountId,
        userId: entity.userId.isEmpty ? _uid : entity.userId,
        amount: entity.amount,
        description: entity.description,
        date: entity.date.toIso8601String(),
        type: entity.type,
        category: entity.category,
        isInstallment: entity.isInstallment,
        installmentCount: entity.installmentCount,
        installmentNumber: entity.installmentNumber,
        merchantName: entity.merchantName,
        statementId: entity.statementId,
        source: entity.source,
      );
}
