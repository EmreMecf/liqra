/// Finansal hedef modeli
///
/// [currentAmount] iki bileşenden oluşur:
///   • [manualAmount]  — kullanıcının "Para Ekle" ile eklediği nakit birikim
///   • portföy değeri  — yatırımlara aktarılan tutar (portföyden türetilir)
///
/// Eskiden portföy senkronu [currentAmount]'ı doğrudan EZİYORDU; kullanıcının
/// elle eklediği birikim uygulama her açıldığında siliniyordu. Artık senkron
/// yalnızca portföy bileşenini günceller, manuel birikim korunur.
class GoalModel {
  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  /// active | completed | paused
  final String status;
  final String? emoji;

  /// Kullanıcının elle eklediği birikim — portföy senkronu buna dokunmaz.
  final double manualAmount;

  const GoalModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.status,
    this.emoji,
    this.manualAmount = 0,
  });

  double get progress => (currentAmount / targetAmount).clamp(0.0, 1.0);
  double get progressPercent => progress * 100;
  double get remaining => targetAmount - currentAmount;
  bool get isCompleted => currentAmount >= targetAmount;

  /// Aylık birikim hızına göre kalan ay tahmini
  double estimatedMonthsRemaining(double monthlyAvg) {
    if (monthlyAvg <= 0) return double.infinity;
    return remaining / monthlyAvg;
  }

  GoalModel copyWith({
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? status,
    String? emoji,
    double? manualAmount,
  }) {
    return GoalModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      emoji: emoji ?? this.emoji,
      manualAmount: manualAmount ?? this.manualAmount,
    );
  }
}
