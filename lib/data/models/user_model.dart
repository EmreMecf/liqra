/// Kullanıcı modeli
class UserModel {
  final String id;
  final String name;
  final String email;
  /// low | mid | high | very_high
  final String riskProfile;
  final double monthlyIncome;
  final String currency;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.riskProfile,
    required this.monthlyIncome,
    required this.currency,
  });

  String get riskLabel {
    switch (riskProfile) {
      case 'low':       return 'Düşük Risk';
      case 'mid':       return 'Orta Risk';
      case 'high':      return 'Yüksek Risk';
      case 'very_high': return 'Çok Yüksek Risk';
      default:          return 'Bilinmiyor';
    }
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? riskProfile,
    double? monthlyIncome,
    String? currency,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      riskProfile: riskProfile ?? this.riskProfile,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      currency: currency ?? this.currency,
    );
  }
}
