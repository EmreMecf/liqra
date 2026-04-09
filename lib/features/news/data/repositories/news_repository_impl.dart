import '../../domain/entities/news_entity.dart';
import '../../domain/repositories/news_repository.dart';
import '../datasources/news_firestore_datasource.dart';

class NewsRepositoryImpl implements NewsRepository {
  final NewsFirestoreDataSource _ds;

  const NewsRepositoryImpl(this._ds);

  @override
  Stream<List<NewsEntity>> watchNews({
    NewsCategory? category,
    String? source,
  }) =>
      _ds
          .watchNews(
            category:   category?.name,
            sourceSlug: source,
          )
          .map((list) => list.map((d) => d.toEntity()).toList());
}
