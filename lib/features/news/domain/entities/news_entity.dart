import '../../../../core/utils/category_slug.dart';

enum NewsCategory {
  borsa,
  doviz,
  altin,
  kripto,
  faiz,
  ekonomi,
  sirket,
  genel;

  String get label => switch (this) {
    NewsCategory.borsa   => '📈 Borsa',
    NewsCategory.doviz   => '💱 Döviz',
    NewsCategory.altin   => '🥇 Altın',
    NewsCategory.kripto  => '₿ Kripto',
    NewsCategory.faiz    => '🏦 Faiz',
    NewsCategory.ekonomi => '🌍 Ekonomi',
    NewsCategory.sirket  => '🏢 Şirket',
    NewsCategory.genel   => '📰 Genel',
  };

  /// Firestore'daki slug'ı enum'a çevirir. Türkçe karakterli ve ASCII
  /// yazımların ikisini de tanır (bkz. [normalizeCategorySlug]).
  static NewsCategory fromString(String? s) =>
      switch (normalizeCategorySlug(s)) {
        'borsa'   => NewsCategory.borsa,
        'doviz'   => NewsCategory.doviz,
        'altin'   => NewsCategory.altin,
        'kripto'  => NewsCategory.kripto,
        'faiz'    => NewsCategory.faiz,
        'ekonomi' => NewsCategory.ekonomi,
        'sirket'  => NewsCategory.sirket,
        _         => NewsCategory.genel,
      };
}

class NewsEntity {
  final String id;
  final String source;
  final String sourceSlug;
  final String sourceColor;
  final String title;
  final String description;
  final String url;
  final String imageUrl;
  final NewsCategory category;
  final DateTime pubDate;
  final DateTime? fetchedAt;

  const NewsEntity({
    required this.id,
    required this.source,
    required this.sourceSlug,
    required this.sourceColor,
    required this.title,
    required this.description,
    required this.url,
    required this.imageUrl,
    required this.category,
    required this.pubDate,
    this.fetchedAt,
  });
}
