import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../features/news/domain/entities/news_entity.dart';
import '../../features/news/presentation/viewmodel/news_viewmodel.dart';
import '../widgets/app_card.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Consumer<NewsViewModel>(
          builder: (context, vm, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Başlık ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Piyasa Haberleri', style: AppTypography.headlineM),
                          Text('Canlı finansal haber akışı',
                              style: AppTypography.labelS.copyWith(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                      const Spacer(),
                      if (vm.selectedCategory != null || vm.selectedSource != null)
                        GestureDetector(
                          onTap: vm.clearFilters,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.accentRed.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Sıfırla',
                                style: AppTypography.labelS.copyWith(
                                    color: AppColors.accentRed,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Arama ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: vm.setSearch,
                    style: GoogleFonts.outfit(
                        color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Haber veya kaynak ara...',
                      hintStyle: GoogleFonts.outfit(
                          color: AppColors.textDisabled, fontSize: 14),
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.textSecondary, size: 18),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close,
                                  size: 16,
                                  color: AppColors.textSecondary),
                              onPressed: () {
                                _searchCtrl.clear();
                                vm.setSearch('');
                              })
                          : null,
                      filled: true,
                      fillColor: AppColors.bgSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Kategori Filtreleri ──────────────────────────────────
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _CategoryChip(
                        label: 'Tümü',
                        selected: vm.selectedCategory == null,
                        color: AppColors.accentGreen,
                        onTap: () => vm.selectCategory(null),
                      ),
                      ...NewsCategory.values.map((cat) => _CategoryChip(
                            label: cat.label,
                            selected: vm.selectedCategory == cat,
                            color: AppColors.accentBlue,
                            onTap: () => vm.selectedCategory == cat
                                ? vm.selectCategory(null)
                                : vm.selectCategory(cat),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── Kaynak Filtreleri ────────────────────────────────────
                if (vm.sources.isNotEmpty)
                  SizedBox(
                    height: 30,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: vm.sources.map((src) {
                        final sel = vm.selectedSource == src;
                        return GestureDetector(
                          onTap: () => vm.selectedSource == src
                              ? vm.selectSource(null)
                              : vm.selectSource(src),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.accentAmber.withValues(alpha: 0.15)
                                  : AppColors.bgSecondary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: sel
                                    ? AppColors.accentAmber
                                    : AppColors.borderSubtle,
                              ),
                            ),
                            child: Text(src,
                                style: AppTypography.labelS.copyWith(
                                  color: sel
                                      ? AppColors.accentAmber
                                      : AppColors.textSecondary,
                                  fontWeight: sel
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  fontSize: 11,
                                )),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 10),

                // ── Liste ────────────────────────────────────────────────
                Expanded(child: _buildBody(vm)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(NewsViewModel vm) {
    if (vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentGreen),
      );
    }

    if (vm.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined,
                color: AppColors.textSecondary, size: 48),
            const SizedBox(height: 12),
            Text(vm.error!, style: AppTypography.bodyM),
            const SizedBox(height: 8),
            Text('Her saat güncellenir',
                style: AppTypography.labelS.copyWith(
                    color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    final list = vm.news;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📰', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Haber bulunamadı', style: AppTypography.bodyM),
            const SizedBox(height: 6),
            Text('Filtre veya arama değiştir',
                style: AppTypography.labelS.copyWith(
                    color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: list.length,
      itemBuilder: (_, i) => _NewsCard(news: list[i])
          .animate(delay: (i * 30).ms)
          .fadeIn(duration: 200.ms)
          .slideY(begin: 0.04, end: 0, duration: 200.ms),
    );
  }
}

// ── Kategori Chip ─────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? color : AppColors.borderSubtle),
        ),
        child: Text(label,
            style: AppTypography.labelS.copyWith(
              color: selected ? color : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              fontSize: 11,
            )),
      ),
    );
  }
}

// ── Haber Kartı ───────────────────────────────────────────────────────────────

class _NewsCard extends StatelessWidget {
  final NewsEntity news;

  const _NewsCard({required this.news});

  Color get _sourceColor {
    try {
      final hex = news.sourceColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.accentBlue;
    }
  }

  static const _months = ['Oca','Şub','Mar','Nis','May','Haz','Tem','Ağu','Eyl','Eki','Kas','Ara'];

  String get _timeAgo {
    final diff = DateTime.now().difference(news.pubDate);
    if (diff.inMinutes < 60) return '${diff.inMinutes}d önce';
    if (diff.inHours < 24)   return '${diff.inHours}s önce';
    return '${news.pubDate.day} ${_months[news.pubDate.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _sourceColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openUrl(news.url),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Renkli üst bant (kaynak rengi)
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kaynak + kategori + zaman
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(news.source,
                              style: AppTypography.labelS.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              )),
                        ),
                        const SizedBox(width: 6),
                        Text(news.category.label,
                            style: AppTypography.labelS.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10)),
                        const Spacer(),
                        Text(_timeAgo,
                            style: AppTypography.labelS.copyWith(
                                color: AppColors.textDisabled,
                                fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Başlık
                    Text(
                      news.title,
                      style: AppTypography.bodyM.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Özet
                    if (news.description.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        news.description,
                        style: AppTypography.labelS.copyWith(
                            color: AppColors.textSecondary, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Oku butonu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Haberi Oku',
                            style: AppTypography.labelS.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            )),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, size: 9, color: color),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
