import '../billing_cycle.dart';
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

  /// Son taksit ödemesinin yapıldığı tarih. Gecikme tespiti buna dayanır;
  /// null ise henüz hiç ödeme yapılmamıştır.
  final DateTime? lastPaymentDate;

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
    this.lastPaymentDate,
  });

  // ── Computed getters ──────────────────────────────────────────────────────

  double get paidAmount => totalAmount - remainingAmount;

  double get progressPercent =>
      totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;

  /// Kredi taksit takvimi — kart ekstre döngüsüyle aynı tarih mantığı.
  /// `dueDay > closingDay` koşulunun kredide anlamı olmadığı için kesim günü =
  /// ödeme günü verilir; böylece her ay tek bir taksit tarihi üretilir.
  BillingCycle get _cycle =>
      BillingCycle(closingDay: paymentDueDay, dueDay: paymentDueDay);

  /// Bu ay ödenmesi gereken taksidin tarihi (geçmişte olabilir).
  DateTime get currentDueDate => _cycle.lastClosingDate;

  /// Bugün dahil, gelecekteki ilk taksit tarihi.
  DateTime get nextPaymentDate {
    final current = currentDueDate;
    final today = BillingCycle.dateOnly(DateTime.now());
    if (!current.isBefore(today)) return current;
    return _cycle.nextClosingDate;
  }

  /// Bir sonraki taksite kalan tam gün sayısı (bugün son gün ise 0).
  int get daysUntilPayment =>
      nextPaymentDate.difference(BillingCycle.dateOnly(DateTime.now())).inDays;

  bool get isDueSoon =>
      status == 'active' &&
      remainingInstallments > 0 &&
      daysUntilPayment <= 3 &&
      !isOverdue;

  /// Taksit gecikti mi?
  ///
  /// Ödeme tarihi geçmiş VE o tarihten sonra ödeme yapılmamışsa gecikmedir.
  /// Eskiden `daysUntilPayment < 0` diye tanımlıydı; taksit tarihi her zaman
  /// gelecekte üretildiği için bu koşul asla sağlanmıyordu.
  bool get isOverdue {
    if (status != 'active' || remainingInstallments <= 0) return false;
    final due = currentDueDate;
    final today = BillingCycle.dateOnly(DateTime.now());
    if (!today.isAfter(due)) return false;
    // Taksit takvimi kredinin başlangıcından önce işlemez
    if (due.isBefore(BillingCycle.dateOnly(startDate))) return false;
    final paid = lastPaymentDate;
    return paid == null || BillingCycle.dateOnly(paid).isBefore(due);
  }

  /// Gecikme kaç gündür sürüyor (gecikme yoksa 0).
  int get daysPastDue => isOverdue
      ? BillingCycle.dateOnly(DateTime.now()).difference(currentDueDate).inDays
      : 0;

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
    DateTime? lastPaymentDate,
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
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
    );
  }
}
