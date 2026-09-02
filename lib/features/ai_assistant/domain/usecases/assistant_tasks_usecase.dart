import '../../../../core/utils/result.dart';
import '../assistant_context.dart';
import '../assistant_prompts.dart';
import '../campaign_matcher.dart';
import '../repositories/ai_repository.dart';
import '../savings_plan.dart';

/// Tek bir hissenin çok değişkenli analizi.
///
/// Fiyat davranışı, haber akışı, sektör/makro duyarlılık ve kullanıcının kendi
/// pozisyonu birlikte değerlendirilir. İlgili haberler burada **kod tarafında**
/// filtrelenir — modele tüm haber akışını verip "ilgilisini sen bul" demek hem
/// token israfı hem de alakasız haber üzerinden yorum riski.
class AnalyzeStockUseCase {
  final AiRepository _repository;
  const AnalyzeStockUseCase(this._repository);

  Future<Result<String>> call({
    required String symbol,
    required String companyName,
    required AssistantContext context,
  }) {
    final quote = _findQuote(context, symbol);
    final position = _findPosition(context, symbol, companyName);
    final news = relevantNews(context, symbol, companyName);

    return _repository.complete(
      systemPrompt: AssistantPrompts.stockAnalysis(
        symbol: symbol,
        ctx: context,
        quote: quote,
        position: position,
        relatedNews: news,
      ),
      userPrompt: '$symbol ($companyName) için derin analiz yap.',
      maxTokens: 4096,
    );
  }

  MarketQuote? _findQuote(AssistantContext ctx, String symbol) {
    for (final q in ctx.market) {
      if (q.symbol.toUpperCase() == symbol.toUpperCase()) return q;
    }
    return null;
  }

  HoldingSnapshot? _findPosition(
      AssistantContext ctx, String symbol, String companyName) {
    for (final h in ctx.portfolio.holdings) {
      final name = h.name.toUpperCase();
      if (name == symbol.toUpperCase() ||
          name.contains(symbol.toUpperCase()) ||
          name == companyName.toUpperCase()) {
        return h;
      }
    }
    return null;
  }

  /// Haber başlığında sembol, şirket adı veya anlamlı bir kelimesi geçenler.
  ///
  /// Hiçbiri eşleşmezse borsa/ekonomi/faiz kategorisindeki başlıklar
  /// makro bağlam olarak verilir — model bunları "sektör koşulları" için
  /// kullanır, şirkete özgü haber gibi sunmaz (prompt bunu söyler).
  static List<NewsHeadline> relevantNews(
    AssistantContext ctx,
    String symbol,
    String companyName,
  ) {
    final needles = <String>{
      symbol.toUpperCase(),
      ...companyName
          .toUpperCase()
          .split(RegExp(r'[\s.]+'))
          .where((w) => w.length >= 4),
    };

    final direct = ctx.news
        .where((n) => needles.any((x) => n.title.toUpperCase().contains(x)))
        .toList();

    if (direct.isNotEmpty) return direct;

    return ctx.news
        .where((n) =>
            n.category.contains('Borsa') ||
            n.category.contains('Ekonomi') ||
            n.category.contains('Faiz'))
        .take(8)
        .toList();
  }
}

/// Harcama denetimi raporu.
class AuditSpendingUseCase {
  final AiRepository _repository;
  const AuditSpendingUseCase(this._repository);

  Future<Result<String>> call(AssistantContext context) => _repository.complete(
        systemPrompt: AssistantPrompts.spendingAudit(context),
        userPrompt: 'Bu ayki harcamalarımı denetle.',
        maxTokens: 3072,
      );
}

/// Birikim planı — rakamlar [SavingsPlanBuilder] ile hesaplanır, model anlatır.
class BuildSavingsPlanUseCase {
  final AiRepository _repository;
  const BuildSavingsPlanUseCase(this._repository);

  /// Hesaplanmış planı ve modelin anlatımını birlikte döner.
  Future<Result<({SavingsPlan plan, String narrative})>> call({
    required AssistantContext context,
    required String goalTitle,
    required double targetAmount,
    required double currentAmount,
    required DateTime deadline,
  }) async {
    final plan = SavingsPlanBuilder.build(
      ctx: context,
      goalTitle: goalTitle,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      deadline: deadline,
    );

    final result = await _repository.complete(
      systemPrompt: AssistantPrompts.savingsPlan(plan, context),
      userPrompt: '$goalTitle hedefim için birikim planımı anlat.',
      maxTokens: 3072,
    );

    return result.when(
      success: (narrative) => Success((plan: plan, narrative: narrative)),
      // Model çağrısı düşse bile hesaplanmış plan geçerlidir — kullanıcı en
      // azından rakamları görsün.
      failure: (f) => Success((plan: plan, narrative: '')),
    );
  }
}

/// Kampanya önerisi — eşleştirme kodda, anlatım modelde.
class RecommendCampaignsUseCase {
  final AiRepository _repository;
  const RecommendCampaignsUseCase(this._repository);

  Future<Result<({List<CampaignMatch> matches, String narrative})>> call({
    required AssistantContext context,
    Set<String> userBanks = const {},
  }) async {
    final matches = CampaignMatcher.match(context, userBanks: userBanks);

    if (matches.isEmpty) {
      return const Success((matches: <CampaignMatch>[], narrative: ''));
    }

    final result = await _repository.complete(
      systemPrompt: AssistantPrompts.campaignBriefing(context),
      userPrompt: 'Harcamalarıma uyan kampanyaları anlat.',
      maxTokens: 2048,
    );

    return result.when(
      success: (narrative) => Success((matches: matches, narrative: narrative)),
      failure: (f) => Success((matches: matches, narrative: '')),
    );
  }
}
