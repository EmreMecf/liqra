import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/di/injection.dart';
import '../../features/campaigns/presentation/viewmodel/campaign_viewmodel.dart';
import '../../features/news/presentation/viewmodel/news_viewmodel.dart';
import '../campaigns/campaigns_screen.dart';
import '../news/news_screen.dart';

/// Keşfet ekranı — Haberler + Kampanyalar tab'ları
class KesfetScreen extends StatefulWidget {
  const KesfetScreen({super.key});

  @override
  State<KesfetScreen> createState() => _KesfetScreenState();
}

class _KesfetScreenState extends State<KesfetScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NewsViewModel>(
          create: (_) => getIt<NewsViewModel>(),
        ),
        ChangeNotifierProvider<CampaignViewModel>(
          create: (_) => getIt<CampaignViewModel>(),
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Column(
          children: [
            // ── Tab Bar ──────────────────────────────────────────────────
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Keşfet', style: AppTypography.headlineL),
                    const SizedBox(height: 14),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderSubtle, width: 0.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(30),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TabBar(
                        controller: _tabCtrl,
                        indicator: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accentGreen.withAlpha(35),
                              AppColors.accentGreen.withAlpha(18),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                              color: AppColors.accentGreen.withAlpha(120)),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelPadding: EdgeInsets.zero,
                        labelColor: AppColors.accentGreen,
                        unselectedLabelColor: AppColors.textSecondary,
                        tabs: const [
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.newspaper_rounded, size: 14),
                                SizedBox(width: 5),
                                Text('Haberler',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.local_offer_rounded, size: 14),
                                SizedBox(width: 5),
                                Text('Kampanyalar',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Tab İçerikleri ───────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: const [
                  _NewsTab(),
                  _CampaignsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Haberler tab içeriği (NewsScreen'in body kısmı) ──────────────────────────

class _NewsTab extends StatelessWidget {
  const _NewsTab();

  @override
  Widget build(BuildContext context) {
    // NewsScreen zaten SafeArea + Scaffold içeriyor ama biz sadece body kısmını kullanmak istiyoruz
    // Aynı widget'ları doğrudan kullanmak yerine NewsScreen'i sıfırdan sarıyoruz
    return const NewsScreen();
  }
}

// ── Kampanyalar tab içeriği ───────────────────────────────────────────────────

class _CampaignsTab extends StatelessWidget {
  const _CampaignsTab();

  @override
  Widget build(BuildContext context) {
    return const CampaignsScreen();
  }
}
