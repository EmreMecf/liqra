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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabCtrl,
                    indicator: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.accentGreen.withValues(alpha: 0.4)),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: AppTypography.labelS.copyWith(
                        fontWeight: FontWeight.w700, fontSize: 12),
                    unselectedLabelStyle: AppTypography.labelS.copyWith(
                        fontWeight: FontWeight.w500, fontSize: 12),
                    labelColor: AppColors.accentGreen,
                    unselectedLabelColor: AppColors.textSecondary,
                    tabs: const [
                      Tab(text: '📰  Haberler'),
                      Tab(text: '🎯  Kampanyalar'),
                    ],
                  ),
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
