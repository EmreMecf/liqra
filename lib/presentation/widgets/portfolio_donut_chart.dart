import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../features/portfolio/domain/entities/asset_entity.dart';

/// Portföy dağılımı donut grafiği
/// Kullanım: PortfolioDonutChart(assets: portfolio.assets)
class PortfolioDonutChart extends StatefulWidget {
  final List<AssetEntity> assets;
  final double size;

  const PortfolioDonutChart({
    super.key,
    required this.assets,
    this.size = 180,
  });

  @override
  State<PortfolioDonutChart> createState() => _PortfolioDonutChartState();
}

class _PortfolioDonutChartState extends State<PortfolioDonutChart> {
  int _touchedIndex = -1;

  // Varlık tipi renkler
  static const _typeColors = <String, Color>{
    'altin':   Color(0xFFE4B84A), // Liqra gold
    'fon':     Color(0xFF0AFFE0), // Liqra teal
    'hisse':   Color(0xFF3B82F6), // blue
    'crypto':  Color(0xFFFF4757), // red
    'doviz':   Color(0xFFF7D470), // gold bright
    'mevduat': Color(0xFF00C9B1), // teal 2
  };

  static const _typeLabels = <String, String>{
    'altin': 'Altın', 'fon': 'Fon', 'hisse': 'Hisse',
    'crypto': 'Kripto', 'doviz': 'Döviz', 'mevduat': 'Mevduat',
  };

  // Varlıkları tipe göre grupla
  Map<String, double> _groupByType() {
    final map = <String, double>{};
    for (final a in widget.assets) {
      map[a.type] = (map[a.type] ?? 0) + a.totalValue;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.assets.isEmpty) return const SizedBox.shrink();

    final grouped   = _groupByType();
    final total     = grouped.values.fold(0.0, (s, v) => s + v);
    final entries   = grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        Row(
          children: [
            // Donut
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        _touchedIndex = (event.isInterestedForInteractions &&
                            response?.touchedSection != null)
                            ? response!.touchedSection!.touchedSectionIndex
                            : -1;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: widget.size * 0.28,
                  sections: entries.asMap().entries.map((e) {
                    final isTouched = e.key == _touchedIndex;
                    final pct       = e.value.value / total * 100;
                    return PieChartSectionData(
                      color: _typeColors[e.value.key] ??
                          AppColors.accentBlue,
                      value: e.value.value,
                      title: isTouched
                          ? '${pct.toStringAsFixed(1)}%'
                          : '',
                      radius: widget.size * (isTouched ? 0.24 : 0.22),
                      titleStyle: GoogleFonts.dmMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Legend
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: entries.map((e) {
                  final pct = e.value / total * 100;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            color: _typeColors[e.key] ?? AppColors.accentBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _typeLabels[e.key] ?? e.key,
                            style: AppTypography.labelS.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: GoogleFonts.dmMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
