import '../entities/news_entity.dart';

abstract interface class NewsRepository {
  Stream<List<NewsEntity>> watchNews({NewsCategory? category, String? source});
}
