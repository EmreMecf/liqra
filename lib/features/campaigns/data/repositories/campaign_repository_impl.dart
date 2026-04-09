import '../../domain/entities/campaign_entity.dart';
import '../../domain/repositories/campaign_repository.dart';
import '../datasources/campaign_firestore_datasource.dart';

class CampaignRepositoryImpl implements CampaignRepository {
  final CampaignFirestoreDataSource _ds;

  const CampaignRepositoryImpl(this._ds);

  @override
  Stream<List<CampaignEntity>> watchCampaigns() =>
      _ds.watchCampaigns().map((list) => list.map((d) => d.toEntity()).toList());

  @override
  Future<List<CampaignEntity>> getCampaigns() async {
    final list = await _ds.getCampaigns();
    return list.map((d) => d.toEntity()).toList();
  }
}
