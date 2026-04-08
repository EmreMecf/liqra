/// Sabit kalem modeli (kira, abonelik, fatura vb.)
class RecurringItemModel {
  final String id;
  final String userId;
  final String label;
  final double amount;
  /// income | expense
  final String type;
  /// monthly | annual | weekly
  final String frequency;
  final DateTime nextDueDate;
  /// active | cancelled
  final String status;

  const RecurringItemModel({
    required this.id,
    required this.userId,
    required this.label,
    required this.amount,
    required this.type,
    required this.frequency,
    required this.nextDueDate,
    required this.status,
  });

  bool get isActive => status == 'active';

  /// Yıllık maliyet hesabı
  double get annualCost {
    switch (frequency) {
      case 'monthly': return amount * 12;
      case 'annual':  return amount;
      case 'weekly':  return amount * 52;
      default:        return amount * 12;
    }
  }

  RecurringItemModel copyWith({
    String? label,
    double? amount,
    String? frequency,
    DateTime? nextDueDate,
    String? status,
  }) {
    return RecurringItemModel(
      id: id,
      userId: userId,
      label: label ?? this.label,
      amount: amount ?? this.amount,
      type: type,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      status: status ?? this.status,
    );
  }
}
