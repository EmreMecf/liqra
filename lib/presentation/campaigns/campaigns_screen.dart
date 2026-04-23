import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../features/campaigns/domain/entities/campaign_entity.dart';
import '../../features/campaigns/presentation/viewmodel/campaign_viewmodel.dart';
import '../widgets/app_card.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
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
        child: Consumer<CampaignViewModel>(
          builder: (context, vm, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Başlık ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kampanyalar', style: AppTypography.headlineM),
                          Text('Banka fırsatları · Günlük güncellenir',
                              style: AppTypography.labelS.copyWith(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                      const Spacer(),
                      if (vm.selectedBank != null || vm.selectedCategory != null)
                        GestureDetector(
                          onTap: vm.clearFilters,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.accentRed.withOpacity(0.12),
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

                // ── Arama ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: vm.setSearch,
                    style: GoogleFonts.outfit(
                        color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Kampanya veya banka ara...',
                      hintStyle: GoogleFonts.outfit(
                          color: AppColors.textDisabled, fontSize: 14),
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.textSecondary, size: 18),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 16, color: AppColors.textSecondary),
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

                // ── Banka filtreleri ────────────────────────────────────────
                if (vm.banks.isNotEmpty)
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // "Tümü" chip
                        _BankChip(
                          label: 'Tümü',
                          selected: vm.selectedBank == null,
                          color: AppColors.accentGreen,
                          onTap: () => vm.selectBank(null),
                        ),
                        ...vm.banks.map((bank) => _BankChip(
                              label: bank,
                              selected: vm.selectedBank == bank,
                              color: _bankColor(vm, bank),
                              onTap: () => vm.selectedBank == bank
                                  ? vm.selectBank(null)
                                  : vm.selectBank(bank),
                            )),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),

                // ── Kategori filtreleri ─────────────────────────────────────
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: CampaignCategory.values.map((cat) {
                      final sel = vm.selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => vm.selectedCategory == cat
                            ? vm.selectCategory(null)
                            : vm.selectCategory(cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.accentBlue.withOpacity(0.15)
                                : AppColors.bgSecondary,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: sel
                                  ? AppColors.accentBlue
                                  : AppColors.borderSubtle,
                            ),
                          ),
                          child: Text(cat.label,
                              style: AppTypography.labelS.copyWith(
                                color: sel
                                    ? AppColors.accentBlue
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

                // ── Liste ───────────────────────────────────────────────────
                Expanded(child: _buildBody(vm)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(CampaignViewModel vm) {
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
            Text('Veriler akşam güncellenir',
                style: AppTypography.labelS.copyWith(
                    color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    final list = vm.campaigns;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Kampanya bulunamadı', style: AppTypography.bodyM),
            const SizedBox(height: 6),
            Text('Filtrele veya arama değiştir',
                style: AppTypography.labelS.copyWith(
                    color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: list.length,
      itemBuilder: (_, i) => _CampaignCard(
        campaign: list[i],
      ).animate(delay: (i * 40).ms).fadeIn(duration: 250.ms).slideY(
            begin: 0.05, end: 0, duration: 250.ms),
    );
  }

  Color _bankColor(CampaignViewModel vm, String bank) {
    if (vm.campaigns.isEmpty) return AppColors.accentBlue;
    final c = vm.campaigns.firstWhere(
      (x) => x.bank == bank,
      orElse: () => vm.campaigns.first,
    );
    try {
      final hex = c.bankColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.accentBlue;
    }
  }
}

// ── Banka Chip ────────────────────────────────────────────────────────────────

class _BankChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _BankChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? color : AppColors.borderSubtle),
        ),
        child: Text(label,
            style: AppTypography.labelS.copyWith(
              color: selected ? color : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            )),
      ),
    );
  }
}

// ── Kampanya Kartı ────────────────────────────────────────────────────────────

class _CampaignCard extends StatelessWidget {
  final CampaignEntity campaign;

  const _CampaignCard({required this.campaign});

  Color get _bankColor {
    try {
      final hex = campaign.bankColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.accentBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _bankColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openUrl(campaign.detailUrl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst renkli bant — banka rengi
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banka adı + kategori
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(campaign.bank,
                              style: AppTypography.labelS.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              )),
                        ),
                        const SizedBox(width: 6),
                        Text(campaign.category.label,
                            style: AppTypography.labelS.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11)),
                        const Spacer(),
                        if (campaign.endDate != null &&
                            campaign.endDate!.isNotEmpty)
                          Row(children: [
                            const Icon(Icons.schedule,
                                size: 11,
                                color: AppColors.textDisabled),
                            const SizedBox(width: 3),
                            Text(campaign.endDate!,
                                style: AppTypography.labelS.copyWith(
                                    color: AppColors.textDisabled,
                                    fontSize: 10)),
                          ]),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Başlık
                    Text(campaign.title,
                        style: AppTypography.bodyM.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),

                    // Açıklama
                    if (campaign.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(campaign.description,
                          style: AppTypography.labelS.copyWith(
                              color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],

                    const SizedBox(height: 10),

                    // Detaya git butonu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Detayları Gör',
                            style: AppTypography.labelS.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios,
                            size: 10, color: color),
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
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}
