import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/di/injection.dart';
import '../features/subscriptions/presentation/viewmodel/subscription_viewmodel.dart';

import 'dashboard/dashboard_screen.dart';
import 'spending/spending_screen.dart';
import '../features/accounts/presentation/screens/accounts_screen.dart';
import 'portfolio/portfolio_screen.dart';
import 'ai_assistant/ai_assistant_screen.dart';
import 'subscriptions/subscriptions_screen.dart';
import 'profile/profile_screen.dart';

/// Ana scaffold — Alt navigasyon çubuğu ile 5 ekran
class MainScaffold extends StatefulWidget {
  /// Global key — diğer ekranlardan sekme değiştirmek için
  static final globalKey = GlobalKey<_MainScaffoldState>();

  /// Herhangi bir yerden tab değiştir (örn. dashboard uyarı kartından AI'a geç)
  static void switchTab(int index) =>
      globalKey.currentState?.switchTo(index);

  MainScaffold({Key? key}) : super(key: key ?? globalKey);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  void switchTo(int index) => setState(() => _selectedIndex = index);

  static const List<Widget> _screens = [
    DashboardScreen(),
    SpendingScreen(),
    AccountsScreen(),
    PortfolioScreen(),
    AiAssistantScreen(),
    SubscriptionsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SubscriptionViewModel>(
          create: (_) => getIt<SubscriptionViewModel>(),
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: _buildNavBar(),
      ),
    );
  }

  Widget _buildNavBar() {
    return Container(
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          border: const Border(
            top: BorderSide(color: AppColors.borderSubtle, width: 0.5),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_outlined,            activeIcon: Icons.home,                label: 'Ana Sayfa',  index: 0, current: _selectedIndex, onTap: _onTap),
                _NavItem(icon: Icons.receipt_long_outlined,    activeIcon: Icons.receipt_long,        label: 'Harcamalar', index: 1, current: _selectedIndex, onTap: _onTap),
                _NavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Cüzdan', index: 2, current: _selectedIndex, onTap: _onTap),
                _NavItem(icon: Icons.show_chart_outlined,      activeIcon: Icons.show_chart,          label: 'Yatırımlar', index: 3, current: _selectedIndex, onTap: _onTap),
                _NavItem(icon: Icons.smart_toy_outlined,       activeIcon: Icons.smart_toy,           label: 'AI',         index: 4, current: _selectedIndex, onTap: _onTap, badge: true),
                _NavItem(icon: Icons.subscriptions_outlined,   activeIcon: Icons.subscriptions,       label: 'Abonelik',   index: 5, current: _selectedIndex, onTap: _onTap),
                _NavItem(icon: Icons.person_outline,           activeIcon: Icons.person,              label: 'Profil',     index: 6, current: _selectedIndex, onTap: _onTap),
              ],
            ),
          ),
        ),
      );
  }

  void _onTap(int index) => setState(() => _selectedIndex = index);
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;
  final bool badge;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = index == current;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: SizedBox(
        width: 48,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44, height: 32,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.accentGreen.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    color: isActive ? AppColors.accentGreen : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                if (badge && !isActive)
                  Positioned(
                    right: 6,
                    top: 4,
                    child: Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.accentGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.accentGreen : AppColors.textSecondary,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
