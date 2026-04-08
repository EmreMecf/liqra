/// Portföy varlık türleri
enum AssetType { altin, fon, hisse, kripto, tahvil, diger }

extension AssetTypeExt on AssetType {
  String get label {
    switch (this) {
      case AssetType.altin:  return 'Altın';
      case AssetType.fon:    return 'Fon';
      case AssetType.hisse:  return 'Hisse';
      case AssetType.kripto: return 'Kripto';
      case AssetType.tahvil: return 'Tahvil';
      case AssetType.diger:  return 'Diğer';
    }
  }

  String get icon {
    switch (this) {
      case AssetType.altin:  return '🥇';
      case AssetType.fon:    return '📊';
      case AssetType.hisse:  return '📈';
      case AssetType.kripto: return '₿';
      case AssetType.tahvil: return '🏦';
      case AssetType.diger:  return '💼';
    }
  }
}

/// Tek bir portföy varlığı
class AssetModel {
  final String id;
  final AssetType type;
  final String name;
  /// Birim veya lot sayısı (altın için gram, kripto için coin)
  final double quantity;
  final double buyPrice;
  final double currentPrice;
  /// Tarihsel fiyat noktaları (sparkline için)
  final List<double> priceHistory;

  const AssetModel({
    required this.id,
    required this.type,
    required this.name,
    required this.quantity,
    required this.buyPrice,
    required this.currentPrice,
    this.priceHistory = const [],
  });

  double get totalValue       => quantity * currentPrice;
  double get totalCost        => quantity * buyPrice;
  double get gainLoss         => totalValue - totalCost;
  double get gainLossPercent  => ((currentPrice - buyPrice) / buyPrice) * 100;
  bool   get isProfit         => gainLoss >= 0;
}

/// Kullanıcının tüm portföyü
class PortfolioModel {
  final String id;
  final String userId;
  final List<AssetModel> assets;

  const PortfolioModel({
    required this.id,
    required this.userId,
    required this.assets,
  });

  double get totalValue => assets.fold(0, (sum, a) => sum + a.totalValue);
  double get totalCost  => assets.fold(0, (sum, a) => sum + a.totalCost);
  double get totalGainLoss => totalValue - totalCost;
  double get totalGainLossPercent =>
      totalCost > 0 ? ((totalValue - totalCost) / totalCost) * 100 : 0;

  /// Varlık tiplerine göre dağılım (tip → toplam değer)
  Map<AssetType, double> get distribution {
    final Map<AssetType, double> dist = {};
    for (final asset in assets) {
      dist[asset.type] = (dist[asset.type] ?? 0) + asset.totalValue;
    }
    return dist;
  }
}
