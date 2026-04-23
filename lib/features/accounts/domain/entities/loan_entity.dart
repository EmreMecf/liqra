import 'financial_account_entity.dart';

/// Kredi takip varlığı — Firestore users/{uid}/loans/{loanId}
class LoanEntity {
  final String id;
  final String userId;
  final String name;
  final BankName bank;
  final double totalAmount;
  final double remainingAmount;
  final double monthlyPayment;
  final double interestRate; // yıllık %
  final int totalInstallments;
  final int remainingInstallments;
  final int paymentDueDay;
  final DateTime startDate;
  final DateTime createdAt;
  final String currency;
  final String? note;
  final String status; // 'active' | 'completed'

  const LoanEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.bank,
    required this.totalAmount,
    required this.remainingAmount,
    required this.monthlyPayment,
    required this.interestRate,
    required this.totalInstallments,
    required this.remainingInstallments,
    required this.paymentDueDay,
    required this.startDate,
    required this.createdAt,
    this.currency = 'TRY',
    this.note,
    this.status = 'active',
  });

  // ── Computed getters ──────────────────────────────────────────────────────

  double get paidAmount => totalAmount - remainingAmount;

  double get progressPercent =>
      totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;

  DateTime get nextPaymentDate {
    final now = DateTime.now();
    var due = DateTime(now.year, now.month, paymentDueDay);
    if (!due.isAfter(now)) {
      // Bir sonraki aya geç
      final next = DateTime(now.year, now.month + 1, 1);
      due = DateTime(next.year, next.month, paymentDueDay);
    }
    return due;
  }

  int get daysUntilPayment =>
      nextPaymentDate.difference(DateTime.now()).inDays;

  bool get isDueSoon => daysUntilPayment >= 0 && daysUntilPayment <= 3;

  bool get isOverdue => daysUntilPayment < 0;

  // ── copyWith ──────────────────────────────────────────────────────────────

  LoanEntity copyWith({
    String? id,
    String? userId,
    String? name,
    BankName? bank,
    double? totalAmount,
    double? remainingAmount,
    double? monthlyPayment,
    double? interestRate,
    int? totalInstallments,
    int? remainingInstallments,
    int? paymentDueDay,
    DateTime? startDate,
    DateTime? createdAt,
    String? currency,
    String? note,
    String? status,
  }) {
    return LoanEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      bank: bank ?? this.bank,
      totalAmount: totalAmount ?? this.totalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      interestRate: interestRate ?? this.interestRate,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      remainingInstallments:
          remainingInstallments ?? this.remainingInstallments,
      paymentDueDay: paymentDueDay ?? this.paymentDueDay,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt ?? this.createdAt,
      currency: currency ?? this.currency,
      note: note ?? this.note,
      status: status ?? this.status,
    );
  }
}
