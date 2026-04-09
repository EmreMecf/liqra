import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_dto.dart';

abstract interface class NewsFirestoreDataSource {
  Stream<List<NewsDto>> watchNews({String? category, String? sourceSlug});
}

class NewsFirestoreDataSourceImpl implements NewsFirestoreDataSource {
  final _col = FirebaseFirestore.instance.collection('news');

  @override
  Stream<List<NewsDto>> watchNews({String? category, String? sourceSlug}) {
    Query query = _col.orderBy('pubDate', descending: true).limit(100);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    if (sourceSlug != null) {
      query = query.where('sourceSlug', isEqualTo: sourceSlug);
    }

    return query.snapshots().map(
          (snap) => snap.docs.map((d) => NewsDto.fromFirestore(d)).toList(),
        );
  }
}
