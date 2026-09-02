import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/category_slug.dart';

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

  /// Firestore'daki slug'ı enum'a çevirir.
  ///
  /// Cloud Functions ASCII slug yazar (`alisveris`); eski kayıtlarda ve elle
  /// girilen veride Türkçe karakterli hâli (`alışveriş`) de bulunabilir.
  /// [normalizeCategorySlug] ikisini de tanır — eskiden yalnızca Türkçe hâl
  /// eşleşiyordu ve **tüm alışveriş kampanyaları `diger`e düşüyordu**.
  static CampaignCategory fromString(String? s) =>
      switch (normalizeCategorySlug(s)) {
        'yemek'     => CampaignCategory.yemek,
        'market'    => CampaignCategory.market,
        'akaryakit' => CampaignCategory.akaryakit,
        'seyahat'   => CampaignCategory.seyahat,
        'alisveris' => CampaignCategory.alisveris,
        'fatura'    => CampaignCategory.fatura,
        _           => CampaignCategory.diger,
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
    /// true = Cloud Functions seed verisi (gerçek banka API'sinden gelmedi).
    /// UI bunu "Örnek" rozetiyle gösterir.
    @Default(false) bool isSample,
  }) = _CampaignEntity;
}
