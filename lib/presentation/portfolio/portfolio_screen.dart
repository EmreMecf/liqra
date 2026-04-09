import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../features/portfolio/domain/entities/asset_entity.dart';
import '../../features/portfolio/domain/entities/gold_price_entity.dart';
import '../../features/portfolio/domain/entities/market_data_entity.dart';
import '../../features/portfolio/presentation/viewmodel/portfolio_viewmodel.dart';
import '../../features/portfolio/presentation/viewmodel/market_viewmodel.dart';
import '../../features/portfolio/presentation/viewmodel/portfolio_state.dart';
import '../widgets/app_card.dart';
import '../widgets/animated_counter.dart';
import '../widgets/delta_chip.dart';
import 'widgets/add_asset_sheet.dart';

/// Yatırım & Portföy Ekranı — 3 sekme: Portföyüm | Piyasa | Keşfet
class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text('Yatırımlar', style: AppTypography.headlineM),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showAddAssetSheet(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add, color: AppColors.accentGreen, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(9),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTypography.labelS.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: AppTypography.labelS,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Portföyüm'),
                  Tab(text: 'Piyasa'),
                  Tab(text: 'Keşfet'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _PortfolioTab(),
                  _MarketTab(),
                  _DiscoverTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAssetSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddAssetSheet(),
    );
  }
}

// ── Portföyüm Sekmesi ─────────────────────────────────────────────────────────
class _PortfolioTab extends StatefulWidget {
  const _PortfolioTab();

  @override
  State<_PortfolioTab> createState() => _PortfolioTabState();
}

class _PortfolioTabState extends State<_PortfolioTab> {
  String _period = 'Başlangıç';
  final periods = ['Günlük', 'Haftalık', 'Aylık', 'Başlangıç'];

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioViewModel>(
      builder: (context, vm, _) {
        final portfolio = vm.state.portfolio;

        if (vm.state.isLoading) {
          return const Center(child: CircularProgressIndicator(
            color: AppColors.accentGreen, strokeWidth: 2,
          ));
        }

        if (portfolio == null || portfolio.assets.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    color: AppColors.textSecondary, size: 48),
                const SizedBox(height: 12),
                Text('Portföyünüz boş', style: AppTypography.headlineS),
                const SizedBox(height: 6),
                Text('Sağ üstteki + ile varlık ekleyin', style: AppTypography.bodyM),
                const SizedBox(height: 16),
                _QuickAddButtons(),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOPLAM PORTFÖY', style: AppTypography.labelS.copyWith(letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AnimatedCounter(value: portfolio.totalValue),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: DeltaChip(value: portfolio.gainLossPercent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${portfolio.totalGainLoss >= 0 ? "+" : ""}${Formatters.currency(portfolio.totalGainLoss)} başlangıçtan beri',
                    style: AppTypography.labelS.copyWith(
                      color: portfolio.totalGainLoss >= 0
                          ? AppColors.accentGreen : AppColors.accentRed,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: periods.map((p) => GestureDetector(
                      onTap: () => setState(() => _period = p),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _period == p
                              ? AppColors.accentGreen.withOpacity(0.15)
                              : AppColors.bgTertiary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _period == p ? AppColors.accentGreen : AppColors.borderSubtle,
                          ),
                        ),
                        child: Text(p, style: AppTypography.labelS.copyWith(
                          color: _period == p ? AppColors.accentGreen : AppColors.textSecondary,
                          fontWeight: _period == p ? FontWeight.w700 : FontWeight.w500,
                        )),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 12),

            // Tip bazlı dağılım
            _PortfolioDistribution(assets: portfolio.assets),
            const SizedBox(height: 12),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Varlıklar', style: AppTypography.headlineS),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(child: Text('Varlık', style: AppTypography.labelS)),
                      SizedBox(width: 80, child: Text('Değer', style: AppTypography.labelS, textAlign: TextAlign.right)),
                      SizedBox(width: 70, child: Text('G/K%', style: AppTypography.labelS, textAlign: TextAlign.right)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  const SizedBox(height: 8),
                  ...portfolio.assets.asMap().entries.map((e) =>
                    _AssetRow(asset: e.value, index: e.key)
                        .animate(delay: (e.key * 60).ms)
                        .fadeIn(duration: 200.ms),
                  ),
                ],
              ),
            ).animate(delay: 100.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

class _QuickAddButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final types = [
      ('TEFAS Fonu', '📊', 'fon'),
      ('BIST Hisse', '📈', 'hisse'),
      ('Kripto', '₿', 'crypto'),
      ('Altın', '🥇', 'altin'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: types.map((t) => GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AddAssetSheet(initialType: t.$3),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.$2, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(t.$1, style: AppTypography.labelS),
            ],
          ),
        ),
      )).toList(),
    );
  }
}

class _PortfolioDistribution extends StatelessWidget {
  final List<AssetEntity> assets;
  const _PortfolioDistribution({required this.assets});

  @override
  Widget build(BuildContext context) {
    if (assets.length <= 1) return const SizedBox.shrink();

    final totalValue = assets.fold(0.0, (s, a) => s + a.totalValue);
    if (totalValue <= 0) return const SizedBox.shrink();

    // Tip bazlı gruplama
    final byType = <String, double>{};
    for (final a in assets) {
      byType[a.type] = (byType[a.type] ?? 0) + a.totalValue;
    }
    final entries = byType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dağılım', style: AppTypography.headlineS),
          const SizedBox(height: 12),
          ...entries.take(5).toList().asMap().entries.map((e) {
            final color = AppColors.chartColors[e.key % AppColors.chartColors.length];
            final pct   = (e.value.value / totalValue * 100);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(_typeLabel(e.value.key), style: AppTypography.labelS.copyWith(
                        color: AppColors.textPrimary,
                      )),
                      const Spacer(),
                      Text('${pct.toStringAsFixed(1)}%', style: GoogleFonts.dmMono(
                        fontSize: 12, fontWeight: FontWeight.w600, color: color,
                      )),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: AppColors.bgTertiary,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate(delay: 50.ms).fadeIn(duration: 300.ms);
  }

  String _typeLabel(String type) {
    const labels = {
      'altin': '🥇 Altın', 'fon': '📊 TEFAS Fonu',
      'hisse': '📈 Hisse Senedi', 'crypto': '₿ Kripto',
      'doviz': '💵 Döviz', 'mevduat': '🏦 Mevduat',
    };
    return labels[type] ?? '💼 Diğer';
  }
}

class _AssetRow extends StatelessWidget {
  final AssetEntity asset;
  final int index;
  const _AssetRow({required this.asset, required this.index});

  static String _typeIcon(String type) {
    switch (type) {
      case 'altin':   return '🥇';
      case 'fon':     return '📊';
      case 'hisse':   return '📈';
      case 'crypto':  return '₿';
      case 'doviz':   return '💵';
      case 'mevduat': return '🏦';
      default:        return '💼';
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<PortfolioViewModel>();
    return Dismissible(
      key: ValueKey(asset.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.accentRed.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.accentRed, size: 20),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.bgSecondary,
          title: Text('Varlığı Sil', style: AppTypography.headlineS),
          content: Text('${asset.name} portföyden silinecek.', style: AppTypography.bodyM),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('İptal', style: AppTypography.bodyM.copyWith(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Sil', style: AppTypography.bodyM.copyWith(
                color: AppColors.accentRed, fontWeight: FontWeight.w700,
              )),
            ),
          ],
        ),
      ),
      onDismissed: (_) => vm.deleteAsset(asset.id),
      child: GestureDetector(
        onTap: () => _showAssetDetail(context),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            children: [
              Row(
                children: [
                  Text(_typeIcon(asset.type), style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(asset.name,
                          style: AppTypography.bodyM.copyWith(
                            color: AppColors.textPrimary, fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(
                          asset.type == 'altin'
                              ? '${asset.quantity.toStringAsFixed(1)} gr'
                              : '${asset.quantity.toStringAsFixed(
                                    asset.quantity == asset.quantity.toInt() ? 0 : 4)} adet',
                          style: AppTypography.labelS,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      Formatters.currency(asset.totalValue),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.dmMono(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      Formatters.percent(asset.gainLossPercent),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.dmMono(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: asset.isProfit ? AppColors.accentGreen : AppColors.accentRed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (asset.priceHistory.isNotEmpty)
                SizedBox(
                  height: 32,
                  child: LineChart(LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: asset.priceHistory.asMap().entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                        isCurved: true,
                        color: asset.isProfit ? AppColors.accentGreen : AppColors.accentRed,
                        barWidth: 1.5,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: (asset.isProfit ? AppColors.accentGreen : AppColors.accentRed)
                              .withOpacity(0.05),
                        ),
                      ),
                    ],
                  )),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssetDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AssetDetailSheet(asset: asset),
    );
  }
}

class _AssetDetailSheet extends StatelessWidget {
  final AssetEntity asset;
  const _AssetDetailSheet({required this.asset});

  static String _typeLabel(String type) {
    const labels = {
      'altin': 'Altın', 'fon': 'TEFAS Fonu', 'hisse': 'Hisse Senedi',
      'crypto': 'Kripto', 'doviz': 'Döviz', 'mevduat': 'Mevduat',
    };
    return labels[type] ?? 'Varlık';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_AssetRow._typeIcon(asset.type), style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(asset.name, style: AppTypography.headlineS),
                    Text(_typeLabel(asset.type), style: AppTypography.bodyS),
                  ],
                ),
              ),
              DeltaChip(value: asset.gainLossPercent, fontSize: 13),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: 16),
          _detailRow('Mevcut Fiyat', Formatters.currencyDecimal(asset.currentPrice)),
          _detailRow('Alış Fiyatı', Formatters.currencyDecimal(asset.buyPrice)),
          _detailRow('Toplam Değer', Formatters.currency(asset.totalValue)),
          _detailRow('Kâr / Zarar',
              '${asset.gainLoss >= 0 ? "+" : ""}${Formatters.currency(asset.gainLoss)}'),
          _detailRow('Miktar',
            asset.type == 'altin'
                ? '${asset.quantity.toStringAsFixed(1)} gr'
                : '${asset.quantity.toStringAsFixed(
                      asset.quantity == asset.quantity.toInt() ? 0 : 4)} adet'),
          const SizedBox(height: 24),
          if (asset.priceHistory.isNotEmpty) ...[
            Text('Fiyat Geçmişi', style: AppTypography.headlineS),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: LineChart(LineChartData(
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.borderSubtle, strokeWidth: 0.5),
                  drawVerticalLine: false,
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: asset.priceHistory.asMap().entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    color: asset.isProfit ? AppColors.accentGreen : AppColors.accentRed,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: (asset.isProfit ? AppColors.accentGreen : AppColors.accentRed)
                          .withOpacity(0.1),
                    ),
                  ),
                ],
              )),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(label, style: AppTypography.bodyM),
          const Spacer(),
          Text(value, style: GoogleFonts.dmMono(
            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
          )),
        ],
      ),
    );
  }
}

// ── Piyasa Sekmesi ────────────────────────────────────────────────────────────

/// Kategori sabitleri (subLabel değerleriyle eşleşmeli)
class _MarketCat {
  static const all    = 'all';
  static const altin  = 'altin';
  static const doviz  = 'doviz';
  static const bist   = 'bist';
  static const kripto = 'kripto';
  static const emtia  = 'emtia';
  static const fon    = 'fon';
}

class _MarketTab extends StatefulWidget {
  const _MarketTab();

  @override
  State<_MarketTab> createState() => _MarketTabState();
}

class _MarketTabState extends State<_MarketTab> {
  String _selectedCat = _MarketCat.all;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  static const _cats = [
    (_MarketCat.all,    'Tümü'),
    (_MarketCat.altin,  'Altın'),
    (_MarketCat.doviz,  'Döviz'),
    (_MarketCat.bist,   'BIST'),
    (_MarketCat.kripto, 'Kripto'),
    (_MarketCat.emtia,  'Emtia'),
    (_MarketCat.fon,    'Fon'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MarketDataEntity> _filterItems(List<MarketDataEntity> all) {
    List<MarketDataEntity> result = all;

    // Kategori filtresi (subLabel kullanılıyor)
    if (_selectedCat == _MarketCat.all) {
      // "Tümü" görünümünde BIST hisselerini hariç tut
      // (ayrı "En Çok Hacim" widget'ı ile gösterilir)
      result = result.where((e) => e.subLabel != 'bist').toList();
    } else if (_selectedCat == _MarketCat.bist) {
      // BIST sekmesi: hem bist hem bist100 göster, hacme göre sırala
      result = result
          .where((e) => e.subLabel == 'bist' || e.subLabel == 'bist100')
          .toList()
        ..sort((a, b) => b.volume.compareTo(a.volume));
    } else {
      result = result.where((e) => e.subLabel == _selectedCat).toList();
    }

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((e) =>
          e.name.toLowerCase().contains(q) ||
          e.symbol.toLowerCase().contains(q)).toList();
    }

    return result;
  }

  /// "Tümü" sekmesinde gösterilecek top 5 BIST hissesi (hacme göre)
  List<MarketDataEntity> _topBistByVolume(List<MarketDataEntity> all) {
    final bist = all.where((e) => e.subLabel == 'bist').toList()
      ..sort((a, b) => b.volume.compareTo(a.volume));
    return bist.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketViewModel>(
      builder: (context, vm, _) {
        final state    = vm.state;
        final allData  = state.marketData;
        final isLoading = state.isLoading;
        final lastUpd  = vm.lastUpdated;

        String subtitle;
        if (isLoading && allData.isEmpty) {
          subtitle = 'Veriler yükleniyor...';
        } else if (lastUpd != null) {
          final diff = DateTime.now().difference(lastUpd).inSeconds;
          subtitle = diff < 60
              ? 'Son güncelleme: $diff sn önce'
              : 'Son güncelleme: ${(diff / 60).floor()} dk önce';
        } else {
          subtitle = 'Veriler alınamadı';
        }

        final filtered   = _filterItems(allData);
        final goldPrices = vm.goldPrices;

        // TEFAS top fonları (sadece "fon" kategorisinde göster)
        final topFunds = switch (state) {
          MarketLoaded(:final topFunds) => topFunds,
          _ => const <dynamic>[],
        };

        return RefreshIndicator(
          color: AppColors.accentGreen,
          onRefresh: () => vm.refresh(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              // ── Başlık ──────────────────────────────────────────────────────
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Canlı Piyasa', style: AppTypography.headlineS),
                      Text(subtitle, style: AppTypography.labelS),
                    ],
                  ),
                  const Spacer(),
                  if (isLoading)
                    const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentGreen),
                    )
                  else
                    GestureDetector(
                      onTap: () => vm.refresh(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6, height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.accentGreen, shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text('Canlı', style: AppTypography.labelS.copyWith(
                              color: AppColors.accentGreen,
                            )),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Hata Banner ──────────────────────────────────────────────────
              if (state case MarketError(:final message))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_outlined,
                            color: AppColors.accentRed, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(message, style: AppTypography.labelS.copyWith(
                            color: AppColors.accentRed,
                          )),
                        ),
                        TextButton(
                          onPressed: () => vm.refresh(),
                          child: Text('Yenile', style: AppTypography.labelS.copyWith(
                            color: AppColors.accentRed, fontWeight: FontWeight.w700,
                          )),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Kategori Filtreleri ────────────────────────────────────────
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _cats.map((cat) {
                    final isSelected = _selectedCat == cat.$1;
                    // Bu kategoride veri var mı?
                    final hasData = cat.$1 == _MarketCat.all
                        ? allData.isNotEmpty
                        : cat.$1 == _MarketCat.altin
                            ? goldPrices.isNotEmpty
                            : cat.$1 == _MarketCat.fon
                                ? topFunds.isNotEmpty
                                : cat.$1 == _MarketCat.bist
                                    ? allData.any((e) => e.subLabel == 'bist' || e.subLabel == 'bist100')
                                    : allData.any((e) => e.subLabel == cat.$1);
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedCat = cat.$1;
                        _searchCtrl.clear();
                        _searchQuery = '';
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accentGreen
                              : AppColors.bgSecondary,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accentGreen
                                : AppColors.borderSubtle,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(cat.$2, style: AppTypography.labelS.copyWith(
                              color: isSelected
                                  ? Colors.black
                                  : hasData
                                      ? AppColors.textPrimary
                                      : AppColors.textDisabled,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            )),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // ── Arama Kutusu ──────────────────────────────────────────────
              if (_selectedCat == _MarketCat.bist || _selectedCat == _MarketCat.all) ...[
                TextFormField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Hisse ara... (GARAN, THYAO...)',
                    hintStyle: GoogleFonts.outfit(color: AppColors.textDisabled, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                            onPressed: () => setState(() {
                              _searchCtrl.clear();
                              _searchQuery = '';
                            }),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.bgSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Altın Ekranı ───────────────────────────────────────────────
              if (_selectedCat == _MarketCat.altin) ...[
                _GoldView(goldPrices: goldPrices, lastUpdated: vm.goldLastUpdated),
              ],

              // ── En Çok Hacim (sadece "Tümü" görünümünde) ──────────────────
              if (_selectedCat == _MarketCat.all) ...[
                _BistTopVolumeSection(
                  items: _topBistByVolume(allData),
                  onTapAll: () => setState(() {
                    _selectedCat = _MarketCat.bist;
                    _searchCtrl.clear();
                    _searchQuery = '';
                  }),
                ),
                const SizedBox(height: 16),
              ],

              // ── Piyasa Listesi ─────────────────────────────────────────────
              if (_selectedCat != _MarketCat.fon && _selectedCat != _MarketCat.altin) ...[
                if (filtered.isEmpty && isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(color: AppColors.accentGreen),
                    ),
                  )
                else if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('Veri bulunamadı', style: AppTypography.bodyM),
                    ),
                  )
                else
                  ...filtered.asMap().entries.map((e) {
                    final item = e.value;
                    final isUsd = item.currency == 'USD';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Text(item.icon, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: AppTypography.bodyM.copyWith(
                                    color: AppColors.textPrimary, fontWeight: FontWeight.w500,
                                  )),
                                  Text(
                                    _catLabel(item.subLabel ?? ''),
                                    style: AppTypography.labelS.copyWith(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatPrice(item.price, item.symbol, isUsd),
                                  style: GoogleFonts.dmMono(
                                    fontSize: 14, fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                DeltaChip(value: item.changePercent),
                              ],
                            ),
                          ],
                        ),
                      ).animate(delay: (e.key * 30).ms).fadeIn(duration: 200.ms),
                    );
                  }),
              ],

              // ── Altın Özeti (Tümü görünümünde) ────────────────────────────
              if (_selectedCat == _MarketCat.all && goldPrices.isNotEmpty) ...[
                const SizedBox(height: 16),
                _GoldSummaryRow(goldPrices: goldPrices),
              ],

              // ── TEFAS Fon Listesi ─────────────────────────────────────────
              if (_selectedCat == _MarketCat.fon || _selectedCat == _MarketCat.all) ...[
                if (topFunds.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('TEFAS — En İyi Fonlar (1 Yıllık)', style: AppTypography.headlineS),
                  const SizedBox(height: 4),
                  Text('Cloud Functions · Hafta içi 19:00 güncellenir',
                      style: AppTypography.bodyS),
                  const SizedBox(height: 10),
                  AppCard(
                    child: Column(
                      children: topFunds.asMap().entries.map((e) {
                        final fund  = e.value;
                        final color = AppColors.chartColors[e.key % AppColors.chartColors.length];
                        return Padding(
                          padding: EdgeInsets.only(bottom: e.key < topFunds.length - 1 ? 12 : 0),
                          child: Row(
                            children: [
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text('${e.key + 1}',
                                    style: AppTypography.labelS.copyWith(
                                      color: color, fontWeight: FontWeight.w700,
                                    )),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(fund.code, style: GoogleFonts.dmMono(
                                      fontSize: 12, fontWeight: FontWeight.w700,
                                      color: AppColors.accentBlue,
                                    )),
                                    Text(fund.name, style: AppTypography.labelS.copyWith(
                                      color: AppColors.textSecondary, fontSize: 10,
                                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              Text(
                                '+${fund.returnPercent.toStringAsFixed(2)}%',
                                style: GoogleFonts.dmMono(
                                  color: AppColors.accentGreen,
                                  fontSize: 13, fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ).animate(delay: 300.ms).fadeIn(duration: 300.ms),
                ] else if (_selectedCat == _MarketCat.fon)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.access_time, color: AppColors.textSecondary, size: 32),
                          const SizedBox(height: 8),
                          Text('TEFAS verileri hafta içi 19:00\'da güncellenir',
                              style: AppTypography.bodyM, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  String _catLabel(String subLabel) {
    switch (subLabel) {
      case 'doviz':  return 'Döviz · Liqra';
      case 'emtia':  return 'Emtia · Liqra';
      case 'bist100':return 'BIST · Liqra';
      case 'kripto': return 'Kripto · Liqra';
      case 'bist':   return 'BIST Hisse · Liqra';
      default:       return 'Liqra';
    }
  }

  String _formatPrice(double price, String symbol, bool isUsd) {
    if (isUsd) {
      // ABD hisseleri USD cinsinden
      return '\$${price.toStringAsFixed(price >= 100 ? 0 : price >= 10 ? 2 : 2)}';
    }
    if (symbol == 'XU100') return Formatters.currencyDecimal(price, showSymbol: false);
    if (price >= 1000) return Formatters.currency(price);
    if (price >= 10) {
      final s = price.toStringAsFixed(2);
      final parts = s.split('.');
      return '${parts[0]},${parts[1]} TL';
    }
    return '${price.toStringAsFixed(4)} TL';
  }
}

// ── Altın Fiyatları Ekranı ────────────────────────────────────────────────────

class _GoldSummaryRow extends StatelessWidget {
  final List<GoldPriceData> goldPrices;
  const _GoldSummaryRow({required this.goldPrices});

  @override
  Widget build(BuildContext context) {
    // Sadece ana altın tiplerini göster
    final mainTypes = ['gram', 'ceyrek', 'tam'];
    final items = goldPrices.where((g) => mainTypes.contains(g.code)).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('🥇 Altın Fiyatları', style: AppTypography.headlineS),
            const Spacer(),
            GestureDetector(
              onTap: () {/* TODO: navigate to gold tab */},
              child: Text('Tümünü Gör →', style: AppTypography.labelS.copyWith(
                color: AppColors.accentGreen, fontWeight: FontWeight.w600,
              )),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: items.map((g) => Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.name, style: AppTypography.labelS.copyWith(
                    color: AppColors.textSecondary, fontSize: 10,
                  )),
                  const SizedBox(height: 4),
                  Text(_fmt(g.satis), style: GoogleFonts.dmMono(
                    fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                  )),
                  const SizedBox(height: 2),
                  Text(
                    '${g.isUp ? "+" : ""}${g.degisim.toStringAsFixed(2)}%',
                    style: GoogleFonts.dmMono(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: g.isUp ? AppColors.accentGreen : AppColors.accentRed,
                    ),
                  ),
                ],
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1000) {
      final s = v.toStringAsFixed(0);
      return s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    }
    return v.toStringAsFixed(2);
  }
}

class _GoldView extends StatelessWidget {
  final List<GoldPriceData> goldPrices;
  final DateTime? lastUpdated;
  const _GoldView({required this.goldPrices, this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    if (goldPrices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentGreen),
              ),
              const SizedBox(height: 12),
              Text('Altın fiyatları yükleniyor...', style: AppTypography.bodyM),
              const SizedBox(height: 6),
              Text('Cloud Functions · 5dk\'da bir güncellenir',
                  style: AppTypography.labelS),
            ],
          ),
        ),
      );
    }

    final gram       = goldPrices.firstWhere((g) => g.code == 'gram', orElse: () => goldPrices.first);
    final madeniList = goldPrices.where((g) => g.category == 'madeni').toList();
    final bilezikList = goldPrices.where((g) => g.category == 'bilezik').toList();
    final digerList  = goldPrices.where((g) => g.category == 'diger').toList();

    String updateStr = '';
    if (lastUpdated != null) {
      final diff = DateTime.now().difference(lastUpdated!).inMinutes;
      updateStr = diff < 1 ? 'Az önce güncellendi' : '$diff dk önce güncellendi';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Gram Altın Hero Kartı ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFD4A017).withOpacity(0.25),
                const Color(0xFFB8860B).withOpacity(0.10),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFD4A017).withOpacity(0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🥇', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gram Altın', style: AppTypography.labelS.copyWith(
                        color: const Color(0xFFD4A017), fontWeight: FontWeight.w700,
                      )),
                      if (updateStr.isNotEmpty)
                        Text(updateStr, style: AppTypography.labelS.copyWith(fontSize: 10)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (gram.isUp ? AppColors.accentGreen : AppColors.accentRed)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${gram.isUp ? "+" : ""}${gram.degisim.toStringAsFixed(2)}%',
                      style: GoogleFonts.dmMono(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: gram.isUp ? AppColors.accentGreen : AppColors.accentRed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _GoldPriceColumn('Satış', gram.satis),
                  const SizedBox(width: 24),
                  _GoldPriceColumn('Alış', gram.alis),
                  const Spacer(),
                  if (gram.degisimTutar != 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Değişim', style: AppTypography.labelS.copyWith(
                          color: AppColors.textSecondary, fontSize: 10,
                        )),
                        Text(
                          '${gram.isUp ? "+" : ""}${_fmtMoney(gram.degisimTutar)} TL',
                          style: GoogleFonts.dmMono(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: gram.isUp ? AppColors.accentGreen : AppColors.accentRed,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 16),

        // ── Madeni Altınlar ──────────────────────────────────────────────
        _GoldSection(
          title: 'Madeni Altınlar',
          subtitle: 'Çeyrek, Yarım, Tam ve Cumhuriyet',
          items: madeniList.where((g) => g.code != 'gram').toList(),
        ),

        // ── Bilezik Fiyatları ────────────────────────────────────────────
        if (bilezikList.isNotEmpty) ...[
          const SizedBox(height: 16),
          _GoldSection(
            title: 'Bilezik Fiyatları',
            subtitle: 'Gram başı alış / satış fiyatı',
            items: bilezikList,
            isBilezik: true,
          ),
        ],

        // ── Gümüş ────────────────────────────────────────────────────────
        if (digerList.isNotEmpty) ...[
          const SizedBox(height: 16),
          _GoldSection(title: 'Diğer', subtitle: '', items: digerList),
        ],

        // ── Bilgilendirme ────────────────────────────────────────────────
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Fiyatlar kuyumcu alış/satış referans fiyatlarıdır. '
                  'Gerçek işlem fiyatları farklılık gösterebilir.',
                  style: AppTypography.labelS.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  String _fmtMoney(double v) {
    final s = v.abs().toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$intPart,${parts[1]}';
  }
}

class _GoldPriceColumn extends StatelessWidget {
  final String label;
  final double price;
  const _GoldPriceColumn(this.label, this.price);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelS.copyWith(
          color: AppColors.textSecondary, fontSize: 10,
        )),
        Text(
          _fmt(price),
          style: GoogleFonts.dmMono(
            fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
          ),
        ),
        Text(' TL', style: AppTypography.labelS.copyWith(fontSize: 10)),
      ],
    );
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$intPart,${parts[1]}';
  }
}

class _GoldSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<GoldPriceData> items;
  final bool isBilezik;
  const _GoldSection({
    required this.title,
    required this.subtitle,
    required this.items,
    this.isBilezik = false,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.headlineS),
                    if (subtitle.isNotEmpty)
                      Text(subtitle, style: AppTypography.labelS.copyWith(fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Tablo başlığı
          Row(
            children: [
              const Expanded(child: SizedBox()),
              SizedBox(
                width: 90,
                child: Text('Alış', style: AppTypography.labelS.copyWith(
                  color: AppColors.textSecondary, fontSize: 10,
                ), textAlign: TextAlign.right),
              ),
              SizedBox(
                width: 90,
                child: Text('Satış', style: AppTypography.labelS.copyWith(
                  color: AppColors.textSecondary, fontSize: 10,
                ), textAlign: TextAlign.right),
              ),
              SizedBox(
                width: 60,
                child: Text('Değişim', style: AppTypography.labelS.copyWith(
                  color: AppColors.textSecondary, fontSize: 10,
                ), textAlign: TextAlign.right),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(color: AppColors.borderSubtle, height: 1),
          ...items.asMap().entries.map((e) {
            final g = e.value;
            final isLast = e.key == items.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Text(g.icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.name, style: AppTypography.bodyM.copyWith(
                              color: AppColors.textPrimary, fontWeight: FontWeight.w500,
                              fontSize: 13,
                            )),
                            Text(g.unit, style: AppTypography.labelS.copyWith(fontSize: 10)),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: Text(
                          _fmtPrice(isBilezik ? g.alis : g.alis),
                          textAlign: TextAlign.right,
                          style: GoogleFonts.dmMono(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: Text(
                          _fmtPrice(g.satis),
                          textAlign: TextAlign.right,
                          style: GoogleFonts.dmMono(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '${g.isUp ? "+" : ""}${g.degisim.toStringAsFixed(2)}%',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.dmMono(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: g.isUp ? AppColors.accentGreen : AppColors.accentRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: (e.key * 40).ms).fadeIn(duration: 200.ms),
                if (!isLast)
                  const Divider(color: AppColors.borderSubtle, height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }

  String _fmtPrice(double v) {
    if (v <= 0) return '—';
    final s = v >= 10000
        ? v.toStringAsFixed(0)
        : v >= 100
            ? v.toStringAsFixed(2)
            : v.toStringAsFixed(4);
    // binlik ayırıcı
    final parts = s.split('.');
    final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return parts.length > 1 ? '$intPart,${parts[1]}' : intPart;
  }
}

// ── Keşfet Sekmesi ────────────────────────────────────────────────────────────
class _DiscoverTab extends StatelessWidget {
  const _DiscoverTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketViewModel>(
      builder: (context, vm, _) {
        final allData = vm.state.marketData;
        // En çok değişen 3 BIST hissesi
        final topMovers = allData
            .where((e) => e.subLabel == 'bist')
            .toList()
          ..sort((a, b) => b.changePercent.abs().compareTo(a.changePercent.abs()));

        final opportunities = [
          {
            'instrument': 'Gram Altın',
            'icon': '🥇',
            'reason': 'Küresel belirsizlik dönemlerinde altın güvenli liman. Portföy ağırlığı %10 altındaysa değerlendirin.',
            'risk': 'Düşük Risk',
            'riskColor': AppColors.accentGreen,
            'tag': 'GÜVENLI LIMAN',
            'tagColor': AppColors.accentGreen,
          },
          {
            'instrument': 'Para Piyasası Fonu',
            'icon': '🏦',
            'reason': 'Yüksek faiz ortamında PPF getirileri cazibeli. Kısa vadeli birikim için TEFAS PPF fonlarını inceleyin.',
            'risk': 'Çok Düşük Risk',
            'riskColor': AppColors.accentGreen,
            'tag': 'DÜŞÜK RİSK',
            'tagColor': AppColors.accentGreen,
          },
          {
            'instrument': 'Teknoloji Fonu (TEC/YAT)',
            'icon': '💻',
            'reason': 'TEFAS teknoloji ve inovasyon fonları uzun vadede piyasa üzerinde getiri potansiyeli sunar.',
            'risk': 'Orta Risk',
            'riskColor': AppColors.accentAmber,
            'tag': 'UZUN VADE',
            'tagColor': AppColors.accentAmber,
          },
        ];

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            Row(
              children: [
                Text('Keşfet', style: AppTypography.headlineS),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('AI Destekli', style: AppTypography.labelS.copyWith(
                    color: AppColors.accentBlue, fontWeight: FontWeight.w700,
                  )),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Risk profilinize göre kişiselleştirilmiş fırsatlar',
                style: AppTypography.bodyS),
            const SizedBox(height: 16),

            // En çok hareket eden BIST hisseleri
            if (topMovers.isNotEmpty) ...[
              Text('Günün Öne Çıkanları', style: AppTypography.headlineS),
              const SizedBox(height: 8),
              SizedBox(
                height: 88,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: topMovers.take(6).length,
                  itemBuilder: (_, i) {
                    final m = topMovers[i];
                    final isUp = m.changePercent >= 0;
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (isUp ? AppColors.accentGreen : AppColors.accentRed)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(m.symbol, style: GoogleFonts.dmMono(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          )),
                          Text(
                            '${m.price.toStringAsFixed(m.price >= 10 ? 2 : 4)} TL',
                            style: GoogleFonts.dmMono(
                              fontSize: 12, color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${isUp ? "+" : ""}${m.changePercent.toStringAsFixed(2)}%',
                            style: GoogleFonts.dmMono(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: isUp ? AppColors.accentGreen : AppColors.accentRed,
                            ),
                          ),
                        ],
                      ),
                    ).animate(delay: (i * 50).ms).fadeIn(duration: 200.ms);
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            ...opportunities.asMap().entries.map((e) {
              final opp = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(opp['icon'] as String, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(opp['instrument'] as String,
                              style: AppTypography.bodyM.copyWith(
                                color: AppColors.textPrimary, fontWeight: FontWeight.w600,
                              )),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (opp['tagColor'] as Color).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(opp['tag'] as String,
                              style: AppTypography.labelS.copyWith(
                                color: opp['tagColor'] as Color, fontWeight: FontWeight.w700,
                              )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(opp['reason'] as String, style: AppTypography.bodyM),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (opp['riskColor'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: (opp['riskColor'] as Color).withOpacity(0.3),
                              ),
                            ),
                            child: Text(opp['risk'] as String, style: AppTypography.labelS.copyWith(
                              color: opp['riskColor'] as Color,
                            )),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {},
                            child: Text('Detaylı Analiz →',
                              style: AppTypography.labelM.copyWith(
                                color: AppColors.accentBlue, fontWeight: FontWeight.w600,
                              )),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate(delay: (e.key * 80).ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
              );
            }),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

// ── En Çok Hacim BIST Widget'ı ───────────────────────────────────────────────

class _BistTopVolumeSection extends StatelessWidget {
  final List<MarketDataEntity> items;
  final VoidCallback onTapAll;

  const _BistTopVolumeSection({required this.items, required this.onTapAll});

  String _formatHacim(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}Mr';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(0)}Mn';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text('En Çok Hacim · BIST', style: AppTypography.headlineS),
            const Spacer(),
            GestureDetector(
              onTap: onTapAll,
              child: Text(
                'Tümünü Gör →',
                style: AppTypography.labelS.copyWith(
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: items.asMap().entries.map((e) {
              final item    = e.value;
              final isLast  = e.key == items.length - 1;
              final change  = item.changePercent;
              final changeColor = change >= 0 ? AppColors.accentGreen : AppColors.accentRed;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Text('${e.key + 1}', style: AppTypography.labelS.copyWith(
                            color: AppColors.textDisabled, fontWeight: FontWeight.w700,
                          )),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(item.symbol, style: GoogleFonts.dmMono(
                            color: AppColors.accentBlue, fontSize: 11, fontWeight: FontWeight.w700,
                          )),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: AppTypography.labelS.copyWith(
                                color: AppColors.textPrimary, fontWeight: FontWeight.w500,
                              ), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('Hacim: ₺${_formatHacim(item.volume)}',
                                style: AppTypography.labelS.copyWith(
                                  color: AppColors.textDisabled, fontSize: 10,
                                )),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              item.price >= 1000
                                  ? Formatters.currency(item.price)
                                  : '${item.price.toStringAsFixed(2)} TL',
                              style: GoogleFonts.dmMono(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: changeColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                                style: GoogleFonts.dmMono(
                                  color: changeColor, fontSize: 10, fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(height: 1, color: AppColors.borderSubtle.withOpacity(0.5)),
                ],
              );
            }).toList(),
          ),
        ).animate().fadeIn(duration: 250.ms),
      ],
    );
  }
}
