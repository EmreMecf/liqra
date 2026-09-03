import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../billing_cycle.dart';

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
    /// Kayıtlı `statementBalance` değerinin ait olduğu kesim tarihi.
    /// Ekstre devrinin ayda bir kez çalışmasını sağlar.
    DateTime? statementClosedAt,
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
        return AppColors.textDisabled;
    }
  }
}

// ── CreditCard Extensions ──────────────────────────────────────────────────

extension CreditCardEntityX on CreditCardEntity {
  /// Kartın ekstre döngüsü — tüm tarih hesapları buradan gelir.
  BillingCycle get cycle =>
      BillingCycle(closingDay: statementClosingDay, dueDay: paymentDueDay);

  /// Harcanabilir limit. Limit aşımında NEGATİF döner — gizlenmez.
  double get availableLimit => creditLimit - usedAmount;

  /// Limit aşılmış mı? (kart borcu limitten büyük)
  bool get isOverLimit => usedAmount > creditLimit;

  /// Kullanım oranı. Göstergeler için 0–1 arasına kırpılır; aşımı görmek için
  /// [isOverLimit] veya [rawUsagePercent] kullanın.
  double get usagePercent => rawUsagePercent.clamp(0.0, 1.0);

  /// Kırpılmamış kullanım oranı — %100'ü aşabilir.
  double get rawUsagePercent =>
      creditLimit > 0 ? usedAmount / creditLimit : 0.0;

  /// Kesimden sonra yapılan, henüz ekstreye girmemiş harcamalar —
  /// toplam borcun ekstreye yansımamış kısmı.
  double get unbilledAmount =>
      (usedAmount - statementBalance).clamp(0.0, double.infinity);

  // ── Tarihler (bkz. BillingCycle) ─────────────────────────────────────────

  DateTime get lastClosingDate => cycle.lastClosingDate;
  DateTime get nextClosingDate => cycle.nextClosingDate;

  /// Bir sonraki son ödeme tarihi — bugün son gün ise BUGÜNÜ döner.
  DateTime get nextPaymentDueDate => cycle.nextDueDate;

  /// Son ödeme tarihine kalan tam gün sayısı (bugün son gün ise 0).
  int get daysUntilDue => cycle.daysUntilDue;

  /// Ödeme gecikti mi? Son ödeme tarihi geçtiyse VE hâlâ ekstre borcu varsa.
  ///
  /// Eskiden `daysUntilDue < 0` diye tanımlıydı; son ödeme tarihi her zaman
  /// gelecekte üretildiği için bu koşul asla sağlanmıyordu.
  bool get isOverdue => statementBalance > 0 && cycle.isPastDue;

  /// Gecikme kaç gündür sürüyor (gecikme yoksa 0).
  int get daysPastDue => isOverdue ? cycle.daysPastDue : 0;

  /// Son ödeme yaklaştı mı? (3 gün veya daha az kaldı ve ödenecek borç var)
  bool get isDueSoon =>
      statementBalance > 0 && !isOverdue && daysUntilDue <= 3;
}
