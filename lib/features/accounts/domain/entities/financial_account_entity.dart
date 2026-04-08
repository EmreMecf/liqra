import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'financial_account_entity.freezed.dart';

enum AccountType { bankAccount, creditCard }

enum BankName {
  ziraat,
  garanti,
  isbank,
  akbank,
  yapikredi,
  vakifbank,
  halkbank,
  denizbank,
  teb,
  ing,
  other,
}

@freezed
class FinancialAccountEntity with _$FinancialAccountEntity {
  const factory FinancialAccountEntity.bankAccount({
    required String id,
    required String userId,
    required String name,
    required BankName bank,
    required double balance,
    @Default('TRY') String currency,
    String? iban,
    String? maskedAccountNumber,
    required DateTime createdAt,
  }) = BankAccountEntity;

  const factory FinancialAccountEntity.creditCard({
    required String id,
    required String userId,
    required String name,
    required BankName bank,
    required double creditLimit,
    required double usedAmount,
    required double statementBalance,
    required double minimumPayment,
    required int statementClosingDay,
    required int paymentDueDay,
    String? maskedCardNumber,
    @Default('TRY') String currency,
    required DateTime createdAt,
  }) = CreditCardEntity;
}

// ── BankName Extensions ────────────────────────────────────────────────────

extension BankNameExt on BankName {
  String get displayName {
    switch (this) {
      case BankName.ziraat:
        return 'Ziraat Bankası';
      case BankName.garanti:
        return 'Garanti BBVA';
      case BankName.isbank:
        return 'İş Bankası';
      case BankName.akbank:
        return 'Akbank';
      case BankName.yapikredi:
        return 'Yapı Kredi';
      case BankName.vakifbank:
        return 'VakıfBank';
      case BankName.halkbank:
        return 'Halkbank';
      case BankName.denizbank:
        return 'DenizBank';
      case BankName.teb:
        return 'TEB';
      case BankName.ing:
        return 'ING';
      case BankName.other:
        return 'Diğer';
    }
  }

  String get emoji {
    switch (this) {
      case BankName.ziraat:
        return '🌾';
      case BankName.garanti:
        return '💚';
      case BankName.isbank:
        return '🔷';
      case BankName.akbank:
        return '🔴';
      case BankName.yapikredi:
        return '🟣';
      case BankName.vakifbank:
        return '🟤';
      case BankName.halkbank:
        return '⚫';
      case BankName.denizbank:
        return '🌊';
      case BankName.teb:
        return '🔵';
      case BankName.ing:
        return '🟠';
      case BankName.other:
        return '🏦';
    }
  }

  Color get primaryColor {
    switch (this) {
      case BankName.ziraat:
        return const Color(0xFF00A650);
      case BankName.garanti:
        return const Color(0xFF00A850);
      case BankName.isbank:
        return const Color(0xFF004B9E);
      case BankName.akbank:
        return const Color(0xFFD01919);
      case BankName.yapikredi:
        return const Color(0xFF6B2D8B);
      case BankName.vakifbank:
        return const Color(0xFF1B4F8A);
      case BankName.halkbank:
        return const Color(0xFF004A97);
      case BankName.denizbank:
        return const Color(0xFF0072BC);
      case BankName.teb:
        return const Color(0xFF0070BA);
      case BankName.ing:
        return const Color(0xFFFF6200);
      case BankName.other:
        return const Color(0xFF4A5570);
    }
  }
}

// ── CreditCard Extensions ──────────────────────────────────────────────────

extension CreditCardEntityX on CreditCardEntity {
  double get availableLimit => creditLimit - usedAmount;

  double get usagePercent =>
      creditLimit > 0 ? (usedAmount / creditLimit).clamp(0.0, 1.0) : 0.0;

  DateTime get nextPaymentDueDate {
    final now = DateTime.now();
    var due = DateTime(now.year, now.month, paymentDueDay);
    if (due.isBefore(now)) {
      due = DateTime(now.year, now.month + 1, paymentDueDay);
    }
    return due;
  }

  int get daysUntilDue =>
      nextPaymentDueDate.difference(DateTime.now()).inDays;

  bool get isOverdue => daysUntilDue < 0;
  bool get isDueSoon => daysUntilDue >= 0 && daysUntilDue <= 3;
}
