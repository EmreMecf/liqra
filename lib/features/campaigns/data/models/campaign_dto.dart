import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/campaign_entity.dart';

class CampaignDto {
  final String id;
  final String bank;
  final String bankSlug;
  final String bankColor;
  final String title;
  final String description;
  final String detailUrl;
  final String category;
  final String imageUrl;
  final String endDate;
  final DateTime? fetchedAt;

  const CampaignDto({
    required this.id,
    required this.bank,
    required this.bankSlug,
    required this.bankColor,
    required this.title,
    required this.description,
    required this.detailUrl,
    required this.category,
    required this.imageUrl,
    required this.endDate,
    this.fetchedAt,
  });

  factory CampaignDto.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CampaignDto(
      id:          doc.id,
      bank:        d['bank']        as String? ?? '',
      bankSlug:    d['bankSlug']    as String? ?? '',
      bankColor:   d['bankColor']   as String? ?? '#888888',
      title:       d['title']       as String? ?? '',
      description: d['description'] as String? ?? '',
      detailUrl:   d['detailUrl']   as String? ?? '',
      category:    d['category']    as String? ?? 'diğer',
      imageUrl:    d['imageUrl']    as String? ?? '',
      endDate:     d['endDate']     as String? ?? '',
      fetchedAt:   (d['fetchedAt'] as Timestamp?)?.toDate(),
    );
  }

  CampaignEntity toEntity() => CampaignEntity(
    id:          id,
    bank:        bank,
    bankSlug:    bankSlug,
    bankColor:   bankColor,
    title:       title,
    description: description,
    detailUrl:   detailUrl,
    category:    CampaignCategory.fromString(category),
    imageUrl:    imageUrl.isEmpty ? null : imageUrl,
    endDate:     endDate.isEmpty  ? null : endDate,
    fetchedAt:   fetchedAt,
  );
}
