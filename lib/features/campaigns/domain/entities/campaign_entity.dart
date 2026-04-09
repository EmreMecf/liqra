import 'package:freezed_annotation/freezed_annotation.dart';

part 'campaign_entity.freezed.dart';

enum CampaignCategory {
  yemek,
  market,
  akaryakit,
  seyahat,
  alisveris,
  fatura,
  diger;

  String get label => switch (this) {
    CampaignCategory.yemek     => '🍽️ Yemek',
    CampaignCategory.market    => '🛒 Market',
    CampaignCategory.akaryakit => '⛽ Akaryakıt',
    CampaignCategory.seyahat   => '✈️ Seyahat',
    CampaignCategory.alisveris => '🛍️ Alışveriş',
    CampaignCategory.fatura    => '💡 Fatura',
    CampaignCategory.diger     => '🏷️ Diğer',
  };

  static CampaignCategory fromString(String? s) => switch (s) {
    'yemek'      => CampaignCategory.yemek,
    'market'     => CampaignCategory.market,
    'akaryakit'  => CampaignCategory.akaryakit,
    'seyahat'    => CampaignCategory.seyahat,
    'alışveriş'  => CampaignCategory.alisveris,
    'fatura'     => CampaignCategory.fatura,
    _            => CampaignCategory.diger,
  };
}

@freezed
class CampaignEntity with _$CampaignEntity {
  const factory CampaignEntity({
    required String id,
    required String bank,
    required String bankSlug,
    required String bankColor,
    required String title,
    required String description,
    required String detailUrl,
    required CampaignCategory category,
    String? imageUrl,
    String? endDate,
    DateTime? fetchedAt,
  }) = _CampaignEntity;
}
