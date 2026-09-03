import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// Alt navigasyon sekmesi tanımı.
class NavDef {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;

  const NavDef(this.icon, this.activeIcon, this.label, this.index);
}

/// Liqra alt navigasyon çubuğu.
///
/// ── Neden ayrı dosya ────────────────────────────────────────────────────────
/// `MainScaffold` içinde özel metottu; bu yüzden tasarım önizlemesinde
/// gösterilemiyor, ancak cihaza kurunca görülebiliyordu.
///
/// ── Düzeltilen iki ölçü hatası ──────────────────────────────────────────────
///
/// 1. **Çentik ile FAB boşluğu uyuşmuyordu.** `CircularNotchedRectangle`,
///    58 piksellik FAB için `notchMargin: 10` ile **78 piksellik** bir oyuk
///    keser. Sekmeler arasına bırakılan boşluk ise 68 pikseldi: çentik, iki
///    yanındaki sekmelerin 5'er pikselini kesiyordu. Kenardaki simgeler
///    kırpılmış görünüyordu.
///
/// 2. **Sekmeler sabit 72 piksel genişlikteydi.** Dört sekme + boşluk =
///    356 piksel; 360 piksellik yaygın Android ekranlarda geriye 4 piksel
///    kalıyor, 320 piksellik ekranlarda taşıyordu. Artık [Expanded] ile
///    kalan alanı eşit paylaşıyorlar — her ekranda aynı ritim.
class LiqraBottomNav extends StatelessWidget {
  final List<NavDef> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  /// Rozet gösterilecek sekmenin indeksi (yoksa null).
  final int? badgeIndex;

  const LiqraBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    this.badgeIndex,
  });

  /// FAB çapı — çentik genişliği buradan türetilir.
  static const fabSize = 58.0;

  /// `BottomAppBar.notchMargin` ile aynı olmalı.
  static const notchMargin = 10.0;

  /// Çentiğin gerçek genişliği. Sekme boşluğu bundan küçük olursa çentik
  /// komşu sekmeleri keser.
  static const notchWidth = fabSize + notchMargin * 2;

  /// Çubuğun içerik yüksekliği (güvenli alan hariç).
  static const barHeight = 62.0;

  @override
  Widget build(BuildContext context) {
    // Sekmeler ortadaki çentiğin iki yanına eşit bölünür.
    final half = items.length ~/ 2;

    return BottomAppBar(
      color: AppColors.bgSecondary,
      // Yükseklik + gölge, üst kenarlık yerine. Kenarlık `Border(top:)` ile
      // çizilemez: çentiğin etrafını dolanamaz, düz bir çizgi olarak geçer.
      elevation: 12,
      shadowColor: Colors.black,
      notchMargin: notchMargin,
      shape: const CircularNotchedRectangle(),
      padding: EdgeInsets.zero,
      // Çocuk ARKA PLAN BOYAMAMALI. Eskiden buraya `color`/`gradient` taşıyan
      // bir Container konuyordu; BottomAppBar'ın çizdiği çentikli şeklin
      // üzerine düz dikdörtgen boyadığı için **çentik hiç görünmüyordu** ve
      // FAB çubuğun üstüne yapıştırılmış gibi duruyordu.
      child: SizedBox(
        height: barHeight,
        child: Row(
          children: [
            for (var i = 0; i < half; i++)
              Expanded(child: _tab(items[i])),
            // Çentik boşluğu — genişliği çentiğin kendisiyle aynı
            const SizedBox(width: notchWidth),
            for (var i = half; i < items.length; i++)
              Expanded(child: _tab(items[i])),
          ],
        ),
      ),
    );
  }

  Widget _tab(NavDef def) => _NavItem(
        def: def,
        isActive: def.index == selectedIndex,
        showBadge: badgeIndex == def.index,
        onTap: onTap,
      );
}

class _NavItem extends StatelessWidget {
  final NavDef def;
  final bool isActive;
  final bool showBadge;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.def,
    required this.isActive,
    required this.showBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(def.index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: isActive ? 46 : 36,
                height: 30,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.accentGreen.withAlpha(28)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  isActive ? def.activeIcon : def.icon,
                  color: isActive
                      ? AppColors.accentGreen
                      : AppColors.textSecondary,
                  size: 21,
                ),
              ),
              if (showBadge && !isActive)
                Positioned(
                  right: 4,
                  top: 2,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.accentGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              color:
                  isActive ? AppColors.accentGreen : AppColors.textSecondary,
            ),
            // Dar ekranlarda etiket kırpılsın, taşma çizgisi çıkmasın.
            child: Text(
              def.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
