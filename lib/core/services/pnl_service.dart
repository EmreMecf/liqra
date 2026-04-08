/// PnL (Kâr/Zarar) Hesaplama Servisi
///
/// WAC (Weighted Average Cost — Ağırlıklı Ortalama Maliyet) yöntemi kullanır.
///
/// Kullanım:
///   final result = PnlService.calculate(
///     quantity:      10,
///     avgCost:       3900.0,
///     currentPrice:  4250.0,
///     changePercent: 0.85,
///   );
///
/// WAC güncelleme (alım yaparken):
///   final newAvg = PnlService.recalculateAvgCost(
///     existingQty:    5,
///     existingAvgCost:3800,
///     newQty:         3,
///     newPrice:       4000,
///   );
class PnlService {
  PnlService._();

  // ── Ana hesaplama ─────────────────────────────────────────────────────────

  /// Pozisyon P&L hesapla
  ///
  /// [quantity]      — elinde kaç birim var
  /// [avgCost]       — Ağırlıklı Ortalama Maliyet (WAC) per unit
  /// [currentPrice]  — güncel piyasa fiyatı per unit
  /// [changePercent] — bugünkü değişim % (Cloud Functions'dan gelen)
  static PnlResult calculate({
    required double quantity,
    required double avgCost,
    required double currentPrice,
    double changePercent = 0,
  }) {
    if (quantity <= 0 || currentPrice <= 0) {
      return const PnlResult.zero();
    }

    final currentValue = quantity * currentPrice;
    final totalCost    = quantity * avgCost;
    final absolutePnl  = currentValue - totalCost;
    final percentPnl   = totalCost > 0 ? (absolutePnl / totalCost) * 100 : 0.0;
    final dailyChange  = currentValue * (changePercent / 100);

    return PnlResult(
      currentValue:  currentValue,
      totalCost:     totalCost,
      absolutePnl:   absolutePnl,
      percentPnl:    percentPnl,
      dailyChange:   dailyChange,
      changePercent: changePercent,
    );
  }

  // ── WAC güncelleme ────────────────────────────────────────────────────────

  /// Alım sonrası yeni WAC hesapla
  ///
  /// Formül: (mevcut_adet × mevcut_wac + yeni_adet × yeni_fiyat) / toplam_adet
  static double recalculateAvgCost({
    required double existingQty,
    required double existingAvgCost,
    required double newQty,
    required double newPrice,
  }) {
    final totalQty  = existingQty + newQty;
    if (totalQty <= 0) return 0;
    return ((existingQty * existingAvgCost) + (newQty * newPrice)) / totalQty;
  }

  /// Satış sonrası WAC (satışta WAC değişmez, sadece miktar azalır)
  static double avgCostAfterSell({
    required double existingQty,
    required double existingAvgCost,
    required double soldQty,
  }) {
    // WAC satıştan etkilenmez; sadece geçerlilik kontrolü
    if (soldQty >= existingQty) return 0;
    return existingAvgCost;
  }

  // ── Portföy toplam P&L ────────────────────────────────────────────────────

  /// Birden fazla pozisyonu birleştir
  static PnlResult aggregate(List<PnlResult> positions) {
    if (positions.isEmpty) return const PnlResult.zero();

    double totalCurrentValue = 0;
    double totalCost         = 0;
    double totalDailyChange  = 0;

    for (final p in positions) {
      totalCurrentValue += p.currentValue;
      totalCost         += p.totalCost;
      totalDailyChange  += p.dailyChange;
    }

    final absolutePnl = totalCurrentValue - totalCost;
    final percentPnl  = totalCost > 0 ? (absolutePnl / totalCost) * 100 : 0.0;
    final changePercent = totalCurrentValue > 0
        ? (totalDailyChange / (totalCurrentValue - totalDailyChange)) * 100
        : 0.0;

    return PnlResult(
      currentValue:  totalCurrentValue,
      totalCost:     totalCost,
      absolutePnl:   absolutePnl,
      percentPnl:    percentPnl,
      dailyChange:   totalDailyChange,
      changePercent: changePercent,
    );
  }
}

// ── PnlResult ─────────────────────────────────────────────────────────────────

class PnlResult {
  const PnlResult({
    required this.currentValue,
    required this.totalCost,
    required this.absolutePnl,
    required this.percentPnl,
    required this.dailyChange,
    required this.changePercent,
  });

  const PnlResult.zero()
      : currentValue  = 0,
        totalCost     = 0,
        absolutePnl   = 0,
        percentPnl    = 0,
        dailyChange   = 0,
        changePercent = 0;

  /// Güncel piyasa değeri (adet × güncel fiyat)
  final double currentValue;

  /// Toplam maliyet (adet × WAC)
  final double totalCost;

  /// Kâr/Zarar (TL) — negatif ise zarar
  final double absolutePnl;

  /// Kâr/Zarar (%) — maliyet bazlı
  final double percentPnl;

  /// Bugünkü değişim (TL)
  final double dailyChange;

  /// Bugünkü değişim (%) — piyasadan gelen
  final double changePercent;

  bool get isProfit  => absolutePnl >= 0;
  bool get isLoss    => absolutePnl < 0;

  @override
  String toString() =>
      'PnlResult(value: $currentValue, cost: $totalCost, '
      'pnl: $absolutePnl (${percentPnl.toStringAsFixed(2)}%), '
      'daily: $dailyChange)';
}
