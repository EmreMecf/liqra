import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../models/asset_dto.dart';
import 'portfolio_local_datasource.dart';

/// Firestore tabanlı portföy veri kaynağı
/// Kullanıcı varlıkları users/{uid}/assets koleksiyonunda saklanır
class PortfolioFirestoreDataSource implements PortfolioLocalDataSource {
  final _fs = FirestoreService.instance;

  String get _uid => AuthService.instance.userId ?? '';

  @override
  Future<List<AssetDto>> getAssets(String userId) async {
    final uid = userId.isNotEmpty ? userId : _uid;
    if (uid.isEmpty) return [];
    final snap = await _fs.assets(uid).get();
    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return AssetDto.fromJson(data);
    }).toList();
  }

  @override
  Future<AssetDto> addAsset(AssetDto dto) async {
    if (_uid.isEmpty) return dto;
    final data = dto.toJson();
    data.remove('id');
    await _fs.assets(_uid).doc(dto.id).set(data);
    return dto;
  }

  @override
  Future<void> updateAsset(AssetDto dto) async {
    if (_uid.isEmpty) return;
    final data = dto.toJson();
    data.remove('id');
    await _fs.assets(_uid).doc(dto.id).update(data);
  }

  @override
  Future<void> deleteAsset(String assetId) async {
    if (_uid.isEmpty) return;
    await _fs.assets(_uid).doc(assetId).delete();
  }
}
