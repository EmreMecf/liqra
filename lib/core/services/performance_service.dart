import 'package:flutter/foundation.dart';

/// Performans yardımcıları
/// - Ağır hesaplamaları isolate'e taşı
/// - Bellek optimizasyonu için yardımcılar
class PerformanceService {
  PerformanceService._();
  static final instance = PerformanceService._();

  /// Ağır hesaplamayı arka plan isolate'inde çalıştır
  /// Örnek: büyük liste filtreleme, CSV parse, JSON işleme
  static Future<R> runInBackground<T, R>(
    ComputeCallback<T, R> callback,
    T message,
  ) =>
      compute(callback, message);

  /// Portföy kâr/zarar hesaplama — büyük veri için isolate'e taşınabilir
  static Future<Map<String, double>> computePortfolioStats(
    List<Map<String, dynamic>> assets,
  ) =>
      compute(_calcPortfolioStats, assets);

  /// Harcama kategori dağılımı — büyük liste için
  static Future<Map<String, double>> computeSpendingDistribution(
    List<Map<String, dynamic>> transactions,
  ) =>
      compute(_calcSpendingDistribution, transactions);
}

// ── Isolate'de çalışan saf fonksiyonlar (top-level) ──────────────────────────

Map<String, double> _calcPortfolioStats(List<Map<String, dynamic>> assets) {
  double totalValue = 0;
  double totalCost  = 0;

  for (final a in assets) {
    final qty          = (a['quantity'] as num).toDouble();
    final currentPrice = (a['currentPrice'] as num).toDouble();
    final buyPrice     = (a['buyPrice'] as num).toDouble();
    totalValue += qty * currentPrice;
    totalCost  += qty * buyPrice;
  }

  return {
    'totalValue':    totalValue,
    'totalCost':     totalCost,
    'gainLoss':      totalValue - totalCost,
    'gainLossPct':   totalCost > 0
        ? ((totalValue - totalCost) / totalCost) * 100
        : 0,
  };
}

Map<String, double> _calcSpendingDistribution(
    List<Map<String, dynamic>> txs) {
  final map = <String, double>{};
  for (final t in txs) {
    final cat    = t['category'] as String? ?? 'Diğer';
    final amount = (t['amount'] as num).toDouble();
    map[cat] = (map[cat] ?? 0) + amount;
  }
  return map;
}
