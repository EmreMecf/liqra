import '../models/asset_dto.dart';

abstract interface class PortfolioLocalDataSource {
  Future<List<AssetDto>> getAssets(String userId);
  Future<AssetDto> addAsset(AssetDto dto);
  Future<void> updateAsset(AssetDto dto);
  Future<void> deleteAsset(String assetId);
}

class PortfolioLocalDataSourceImpl implements PortfolioLocalDataSource {
  // TODO: SQLite / SharedPreferences ile persist et
  final List<AssetDto> _store = _buildMockAssets();

  @override
  Future<List<AssetDto>> getAssets(String userId) async =>
      List.unmodifiable(_store);

  @override
  Future<AssetDto> addAsset(AssetDto dto) async {
    _store.add(dto);
    return dto;
  }

  @override
  Future<void> updateAsset(AssetDto dto) async {
    final idx = _store.indexWhere((a) => a.id == dto.id);
    if (idx != -1) _store[idx] = dto;
  }

  @override
  Future<void> deleteAsset(String assetId) async {
    _store.removeWhere((a) => a.id == assetId);
  }

  static List<AssetDto> _buildMockAssets() => [
    const AssetDto(id: 'a01', type: 'altin',  name: 'Gram Altın',             quantity: 85.2,  buyPrice: 1010.33, currentPrice: 1140.85, priceHistory: [980, 995, 1010, 1025, 1008, 1050, 1080, 1110, 1098, 1125, 1140]),
    const AssetDto(id: 'a02', type: 'fon',    name: 'Teknoloji Fonu (TEC)',    quantity: 12480, buyPrice: 6.14,    currentPrice: 7.26,    priceHistory: [5.80, 5.95, 6.10, 6.25, 6.40, 6.55, 6.80, 7.00, 6.90, 7.10, 7.26]),
    const AssetDto(id: 'a03', type: 'fon',    name: 'Para Piyasası Fonu (PPF)', quantity: 40000, buyPrice: 1.04,   currentPrice: 1.07,    priceHistory: [1.02, 1.03, 1.03, 1.04, 1.04, 1.05, 1.05, 1.06, 1.06, 1.07, 1.07]),
    const AssetDto(id: 'a04', type: 'hisse',  name: 'S&P500 ETF (Midas)',      quantity: 180,   buyPrice: 195.2,   currentPrice: 211.67,  priceHistory: [182, 188, 192, 195, 198, 202, 205, 208, 206, 210, 212]),
    const AssetDto(id: 'a05', type: 'hisse',  name: 'Temettü Hisseleri (THYAO)', quantity: 650, buyPrice: 32.8,    currentPrice: 34.92,   priceHistory: [30, 31, 32, 32.5, 33, 33.5, 34, 33.8, 34.2, 34.5, 34.9]),
  ];
}
