import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../core/di/injection.dart';
import '../features/subscriptions/presentation/viewmodel/subscription_viewmodel.dart';

import 'dashboard/dashboard_screen.dart';
import 'spending/spending_screen.dart';
import '../features/accounts/presentation/screens/accounts_screen.dart';
import 'portfolio/portfolio_screen.dart';
import 'ai_assistant/ai_assistant_screen.dart';
import 'subscriptions/subscriptions_screen.dart';
import 'kesfet/kesfet_screen.dart';
import 'profile/profile_screen.dart';
import 'widgets/liqra_logo.dart';

/// Ana scaffold — mobil: bottom nav + FAB  |  web (≥900px): sol sidebar
class MainScaffold extends StatefulWidget {
  static final globalKey = GlobalKey<_MainScaffoldState>();
  static void switchTab(int index) =>
      globalKey.currentState?.switchTo(index);

  MainScaffold({Key? key}) : super(key: key ?? globalKey);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _fabOpen = false;

  late final AnimationController _fabCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  // ── 8 ekran lazy cache ────────────────────────────────────────────────────
  static final List<Widget?> _cache = List.filled(8, null);
  static const List<Widget Function()> _builders = [
    DashboardScreen.new,    // 0
    SpendingScreen.new,     // 1
    AccountsScreen.new,     // 2
    PortfolioScreen.new,    // 3
    AiAssistantScreen.new,  // 4
    SubscriptionsScreen.new,// 5
    KesfetScreen.new,       // 6
    ProfileScreen.new,      // 7
  ];

  // ── Mobil bottom nav (4 item) ────────────────────────────────────────────
  static const _navItems = [
    _NavDef(Icons.home_outlined,           Icons.home_rounded,        'Ana Sayfa',  0),
    _NavDef(Icons.receipt_long_outlined,   Icons.receipt_long_rounded,'Harcamalar', 1),
    _NavDef(Icons.candlestick_chart_outlined, Icons.candlestick_chart, 'Yatırımlar', 3),
    _NavDef(Icons.auto_awesome_outlined,   Icons.auto_awesome,        'AI',         4),
  ];

  // ── FAB speed-dial ───────────────────────────────────────────────────────
  static const _fabItems = [
    _FabDef(Icons.account_balance_wallet_rounded, 'Cüzdan',      2, AppColors.accentGreen),
    _FabDef(Icons.autorenew_rounded,              'Abonelikler', 5, Color(0xFF9B59B6)),
    _FabDef(Icons.explore_rounded,                'Keşfet',      6, Color(0xFF3498DB)),
    _FabDef(Icons.manage_accounts_rounded,        'Profil',      7, Color(0xFFE67E22)),
  ];

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnim = CurvedAnimation(parent: _fabCtrl, curve: Curves.easeOutBack);
    _fadeAnim  = CurvedAnimation(parent: _fabCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
  }

  void switchTo(int index) {
    _closeFab();
    if (_selectedIndex != index) setState(() => _selectedIndex = index);
  }

  void _onNavTap(int index) {
    _closeFab();
    setState(() => _selectedIndex = index);
  }

  void _toggleFab() {
    setState(() => _fabOpen = !_fabOpen);
    if (_fabOpen) _fabCtrl.forward();
    else _fabCtrl.reverse();
  }

  void _closeFab() {
    if (!_fabOpen) return;
    setState(() => _fabOpen = false);
    _fabCtrl.reverse();
  }

  void _onFabItemTap(int index) {
    _closeFab();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _selectedIndex = index);
    });
  }

  // ── İçerik yığını (paylaşımlı) ───────────────────────────────────────────
  Widget _contentStack() => _LazyIndexedStack(
        index: _selectedIndex,
        builders: _builders,
        cache: _cache,
      );

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SubscriptionViewModel>(
          create: (_) => getIt<SubscriptionViewModel>(),
        ),
      ],
      child: isWide ? _buildWebLayout() : _buildMobileLayout(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WEB LAYOUT — sabit sol sidebar
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildWebLayout() {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Row(
        children: [
          // ── Sol sidebar ─────────────────────────────────────────────────
          _WebSidebar(
            selectedIndex: _selectedIndex,
            onItemTap: (i) => setState(() => _selectedIndex = i),
          ),
          // ── Dikey ayraç ─────────────────────────────────────────────────
          Container(
            width: 1,
            color: AppColors.borderSubtle.withValues(alpha: 0.6),
          ),
          // ── Ana içerik ──────────────────────────────────────────────────
          Expanded(child: _contentStack()),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MOBİL LAYOUT — bottom nav + FAB speed-dial
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          _contentStack(),
          // FAB karartması
          if (_fabOpen)
            GestureDetector(
              onTap: _closeFab,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Container(color: Colors.black.withAlpha(140)),
              ),
            ),
          // FAB speed-dial item'ları
          Positioned(
            bottom: _bottomNavHeight(context) + 16,
            right: 0,
            left: 0,
            child: _buildFabMenu(),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  double _bottomNavHeight(BuildContext context) =>
      64 + MediaQuery.of(context).padding.bottom;

  // ── FAB ana butonu ─────────────────────────────────────────────────────────
  Widget _buildFab() {
    return AnimatedBuilder(
      animation: _fabCtrl,
      builder: (_, __) => GestureDetector(
        onTap: _toggleFab,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _fabOpen
                  ? [AppColors.accentRed, const Color(0xFFFF6B6B)]
                  : [AppColors.accentGreen, const Color(0xFF00B896)],
            ),
            boxShadow: [
              BoxShadow(
                color: (_fabOpen ? AppColors.accentRed : AppColors.accentGreen)
                    .withAlpha(100),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: (_fabOpen ? AppColors.accentRed : AppColors.accentGreen)
                    .withAlpha(40),
                blurRadius: 32,
                spreadRadius: 4,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: AnimatedRotation(
            turns: _fabOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 220),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }

  // ── FAB speed-dial menüsü ─────────────────────────────────────────────────
  Widget _buildFabMenu() {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (_, __) {
        if (!_fabOpen && _fabCtrl.value == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_fabItems.length, (i) {
              final item = _fabItems[i];
              final delay = i * 0.15;
              final t =
                  (_scaleAnim.value - delay).clamp(0.0, 1.0) /
                  (1.0 - delay.clamp(0.0, 0.6));
              return Transform.scale(
                scale: t,
                child: Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: _FabMenuItem(
                    item: item,
                    isSelected: _selectedIndex == item.index,
                    onTap: () => _onFabItemTap(item.index),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  // ── Alt navigasyon çubuğu ─────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return BottomAppBar(
      color: AppColors.bgSecondary,
      elevation: 0,
      notchMargin: 10,
      shape: const CircularNotchedRectangle(),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.borderSubtle.withAlpha(100),
              width: 0.5,
            ),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.bgSecondary,
              AppColors.bgSecondary.withAlpha(245),
            ],
          ),
        ),
        height: 62,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(def: _navItems[0], current: _selectedIndex, onTap: _onNavTap),
            _NavItem(def: _navItems[1], current: _selectedIndex, onTap: _onNavTap),
            const SizedBox(width: 68), // FAB boşluğu
            _NavItem(def: _navItems[2], current: _selectedIndex, onTap: _onNavTap),
            _NavItem(def: _navItems[3], current: _selectedIndex, onTap: _onNavTap, badge: true),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WEB SIDEBAR
// ══════════════════════════════════════════════════════════════════════════════

class _WebSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTap;

  const _WebSidebar({
    required this.selectedIndex,
    required this.onItemTap,
  });

  static const _sections = [
    _SideSection('ANA', [
      _SideItem(Icons.home_outlined,              Icons.home_rounded,               'Ana Sayfa',   0),
      _SideItem(Icons.receipt_long_outlined,      Icons.receipt_long_rounded,       'Harcamalar',  1),
      _SideItem(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'Cüzdan', 2),
    ]),
    _SideSection('YATIRIM', [
      _SideItem(Icons.candlestick_chart_outlined, Icons.candlestick_chart,          'Yatırımlar',  3),
      _SideItem(Icons.autorenew_rounded,          Icons.autorenew_rounded,          'Abonelikler', 5),
    ]),
    _SideSection('KEŞİF', [
      _SideItem(Icons.auto_awesome_outlined,      Icons.auto_awesome,               'AI Asistan',  4),
      _SideItem(Icons.explore_outlined,           Icons.explore_rounded,            'Keşfet',      6),
    ]),
    _SideSection('HESAP', [
      _SideItem(Icons.manage_accounts_outlined,   Icons.manage_accounts_rounded,    'Profil',      7),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.bgSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: const LiqraLogo(fontSize: 22, showTagline: false, centered: false),
          ),
          Container(height: 1, color: AppColors.borderSubtle.withValues(alpha: 0.6)),
          const SizedBox(height: 8),

          // ── Navigasyon ───────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _sections.map((section) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
                        child: Text(
                          section.label,
                          style: AppTypography.labelS.copyWith(
                            color: AppColors.textDisabled,
                            fontSize: 9,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                      ...section.items.map((item) => _SidebarItemTile(
                            item: item,
                            isActive: selectedIndex == item.index,
                            onTap: () => onItemTap(item.index),
                          )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Alt bilgi ────────────────────────────────────────────────────
          Container(height: 1, color: AppColors.borderSubtle.withValues(alpha: 0.6)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const LiqraLogoMark(size: 22),
                const SizedBox(width: 8),
                Text(
                  'Liqra v1.0',
                  style: AppTypography.labelS
                      .copyWith(color: AppColors.textDisabled, fontSize: 10),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accentGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItemTile extends StatelessWidget {
  final _SideItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItemTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accentGreen.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? Border.all(color: AppColors.accentGreen.withValues(alpha: 0.2))
              : null,
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                key: ValueKey(isActive),
                color: isActive ? AppColors.accentGreen : AppColors.textSecondary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: GoogleFonts.outfit(
                  color: isActive ? AppColors.accentGreen : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isActive)
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.accentGreen,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// VERİ SINIFLARI
// ══════════════════════════════════════════════════════════════════════════════

class _NavDef {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  const _NavDef(this.icon, this.activeIcon, this.label, this.index);
}

class _FabDef {
  final IconData icon;
  final String label;
  final int index;
  final Color color;
  const _FabDef(this.icon, this.label, this.index, this.color);
}

class _SideItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  const _SideItem(this.icon, this.activeIcon, this.label, this.index);
}

class _SideSection {
  final String label;
  final List<_SideItem> items;
  const _SideSection(this.label, this.items);
}

// ══════════════════════════════════════════════════════════════════════════════
// MOBİL NAV ITEM
// ══════════════════════════════════════════════════════════════════════════════

class _NavItem extends StatelessWidget {
  final _NavDef def;
  final int current;
  final ValueChanged<int> onTap;
  final bool badge;

  const _NavItem({
    required this.def,
    required this.current,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = def.index == current;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(def.index),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Pill indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: isActive ? 46 : 36,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.accentGreen.withAlpha(28)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.accentGreen.withAlpha(20),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: Icon(
                    isActive ? def.activeIcon : def.icon,
                    color: isActive
                        ? AppColors.accentGreen
                        : AppColors.textSecondary,
                    size: 21,
                  ),
                ),
                if (badge && !isActive)
                  Positioned(
                    right: 8,
                    top: 4,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentGreen.withAlpha(80),
                            blurRadius: 4,
                          )
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 1),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.accentGreen : AppColors.textSecondary,
                letterSpacing: isActive ? 0.2 : 0,
              ),
              child: Text(def.label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FAB MENÜ ITEM
// ══════════════════════════════════════════════════════════════════════════════

class _FabMenuItem extends StatelessWidget {
  final _FabDef item;
  final bool isSelected;
  final VoidCallback onTap;

  const _FabMenuItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? item.color : item.color.withAlpha(30),
              border: isSelected
                  ? null
                  : Border.all(color: item.color.withAlpha(80), width: 1.5),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: item.color.withAlpha(80),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Icon(
              item.icon,
              color: isSelected ? Colors.white : item.color,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              item.label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected ? item.color : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// LAZY INDEXED STACK
// ══════════════════════════════════════════════════════════════════════════════

class _LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget Function()> builders;
  final List<Widget?> cache;

  const _LazyIndexedStack({
    required this.index,
    required this.builders,
    required this.cache,
  });

  @override
  State<_LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<_LazyIndexedStack> {
  late final List<bool> _activated;

  @override
  void initState() {
    super.initState();
    _activated = List.generate(
        widget.builders.length, (i) => i == widget.index);
    widget.cache[widget.index] ??= widget.builders[widget.index]();
  }

  @override
  void didUpdateWidget(_LazyIndexedStack old) {
    super.didUpdateWidget(old);
    if (widget.index != old.index) {
      _activated[widget.index] = true;
      widget.cache[widget.index] ??= widget.builders[widget.index]();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: List.generate(widget.builders.length, (i) {
        if (!_activated[i]) return const SizedBox.shrink();
        return Offstage(
          offstage: widget.index != i,
          child: TickerMode(
            enabled: widget.index == i,
            child: widget.cache[i]!,
          ),
        );
      }),
    );
  }
}
