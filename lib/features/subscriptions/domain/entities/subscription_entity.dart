/// Fatura döngüsü
enum BillingCycle {
  weekly,
  monthly,
  quarterly,
  yearly;

  String get label => switch (this) {
        BillingCycle.weekly    => 'Haftalık',
        BillingCycle.monthly   => 'Aylık',
        BillingCycle.quarterly => '3 Aylık',
        BillingCycle.yearly    => 'Yıllık',
      };

  String get shortLabel => switch (this) {
        BillingCycle.weekly    => '/hf',
        BillingCycle.monthly   => '/ay',
        BillingCycle.quarterly => '/3ay',
        BillingCycle.yearly    => '/yıl',
      };

  /// Aylık eşdeğer çarpanı
  double get monthlyFactor => switch (this) {
        BillingCycle.weekly    => 52 / 12,
        BillingCycle.monthly   => 1.0,
        BillingCycle.quarterly => 1 / 3,
        BillingCycle.yearly    => 1 / 12,
      };

  static BillingCycle fromString(String s) => switch (s) {
        'weekly'    => BillingCycle.weekly,
        'quarterly' => BillingCycle.quarterly,
        'yearly'    => BillingCycle.yearly,
        _           => BillingCycle.monthly,
      };
}

/// Abonelik domain entity
class SubscriptionEntity {
  final String id;
  final String userId;
  final String name;
  final double price;
  final BillingCycle billingCycle;
  final DateTime nextBillingDate;
  final String category;
  final int colorValue;
  final String emoji;
  final bool isActive;
  final String? note;
  final DateTime createdAt;

  const SubscriptionEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.price,
    required this.billingCycle,
    required this.nextBillingDate,
    required this.category,
    required this.colorValue,
    required this.emoji,
    required this.isActive,
    this.note,
    required this.createdAt,
  });

  // ── Hesaplanan alanlar ────────────────────────────────────────────────────

  double get monthlyEquivalent => price * billingCycle.monthlyFactor;
  double get yearlyEquivalent  => monthlyEquivalent * 12;

  int get daysUntilBilling =>
      nextBillingDate.difference(DateTime.now()).inDays;

  bool get isExpiringSoon => daysUntilBilling >= 0 && daysUntilBilling <= 7;
  bool get isOverdue      => daysUntilBilling < 0;
  bool get isDueToday     => daysUntilBilling == 0;

  SubscriptionEntity copyWith({
    String?       id,
    String?       userId,
    String?       name,
    double?       price,
    BillingCycle? billingCycle,
    DateTime?     nextBillingDate,
    String?       category,
    int?          colorValue,
    String?       emoji,
    bool?         isActive,
    String?       note,
    DateTime?     createdAt,
  }) =>
      SubscriptionEntity(
        id:              id              ?? this.id,
        userId:          userId          ?? this.userId,
        name:            name            ?? this.name,
        price:           price           ?? this.price,
        billingCycle:    billingCycle    ?? this.billingCycle,
        nextBillingDate: nextBillingDate ?? this.nextBillingDate,
        category:        category        ?? this.category,
        colorValue:      colorValue      ?? this.colorValue,
        emoji:           emoji           ?? this.emoji,
        isActive:        isActive        ?? this.isActive,
        note:            note            ?? this.note,
        createdAt:       createdAt       ?? this.createdAt,
      );
}
