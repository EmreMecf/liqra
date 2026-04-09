import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/news_entity.dart';

class NewsDto {
  final String id;
  final String source;
  final String sourceSlug;
  final String sourceColor;
  final String title;
  final String description;
  final String url;
  final String imageUrl;
  final String category;
  final DateTime pubDate;
  final DateTime? fetchedAt;

  const NewsDto({
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

  factory NewsDto.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NewsDto(
      id:          doc.id,
      source:      d['source']      as String? ?? '',
      sourceSlug:  d['sourceSlug']  as String? ?? '',
      sourceColor: d['sourceColor'] as String? ?? '#888888',
      title:       d['title']       as String? ?? '',
      description: d['description'] as String? ?? '',
      url:         d['url']         as String? ?? '',
      imageUrl:    d['imageUrl']    as String? ?? '',
      category:    d['category']    as String? ?? 'genel',
      pubDate:     (d['pubDate']    as Timestamp?)?.toDate() ?? DateTime.now(),
      fetchedAt:   (d['fetchedAt']  as Timestamp?)?.toDate(),
    );
  }

  NewsEntity toEntity() => NewsEntity(
    id:          id,
    source:      source,
    sourceSlug:  sourceSlug,
    sourceColor: sourceColor,
    title:       title,
    description: description,
    url:         url,
    imageUrl:    imageUrl,
    category:    NewsCategory.fromString(category),
    pubDate:     pubDate,
    fetchedAt:   fetchedAt,
  );
}
