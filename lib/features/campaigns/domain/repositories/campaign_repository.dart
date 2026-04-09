import '../entities/campaign_entity.dart';

abstract class CampaignRepository {
  Stream<List<CampaignEntity>> watchCampaigns();
  Future<List<CampaignEntity>> getCampaigns();
}
