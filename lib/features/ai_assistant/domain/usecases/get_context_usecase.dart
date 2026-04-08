import '../../data/models/ai_request_dto.dart';

/// Uygulama verilerinden Claude bağlam objesi oluşturur
/// Her AI isteğinden önce çağrılır
class GetContextUseCase {
  const GetContextUseCase();

  /// Mevcut uygulama state'inden bağlam toplar
  /// [transactions] son 30 günlük işlemler özeti
  /// [portfolio] portföy özeti
  AiContextDto call({
    required String riskProfile,
    required double monthlyIncome,
    required double monthlyExpenses,
    required String transactionsSummary,
    required String portfolioSummary,
    String? goalTitle,
    double? goalProgress,
    String? goalDeadline,
  }) {
    return AiContextDto(
      riskProfile: riskProfile,
      monthlyIncome: monthlyIncome,
      monthlyExpenses: monthlyExpenses,
      netCash: monthlyIncome - monthlyExpenses,
      transactionsSummary: transactionsSummary,
      portfolioSummary: portfolioSummary,
      goalTitle: goalTitle,
      goalProgress: goalProgress,
      goalDeadline: goalDeadline,
    );
  }
}
