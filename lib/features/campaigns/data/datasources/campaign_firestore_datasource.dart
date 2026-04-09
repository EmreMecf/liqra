import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/campaign_dto.dart';

class CampaignFirestoreDataSource {
  final FirebaseFirestore _db;

  CampaignFirestoreDataSource() : _db = FirebaseFirestore.instance;

  static const _col = 'bank_campaigns';

  Stream<List<CampaignDto>> watchCampaigns() => _db
      .collection(_col)
      .orderBy('fetchedAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(CampaignDto.fromFirestore).toList());

  Future<List<CampaignDto>> getCampaigns() async {
    final snap = await _db
        .collection(_col)
        .orderBy('fetchedAt', descending: true)
        .get();
    return snap.docs.map(CampaignDto.fromFirestore).toList();
  }
}
