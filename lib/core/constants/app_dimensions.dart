/// Liqra — Ölçü Sistemi
///
/// ── Neden gerekli ───────────────────────────────────────────────────────────
/// Uygulamada **18 farklı köşe yarıçapı** (2'den 22'ye) ve düzensiz boşluklar
/// kullanılıyordu. Ekranlar tek tek fena değildi ama birbirini tutmuyordu:
/// yan yana duran iki kartın köşesi farklı, aralarındaki boşluk farklıydı.
/// Göz bunu "bozuk" diye okur ama nedenini söyleyemez.
///
/// Yeni kod bu ölçekten seçer. Ara değer gerekiyorsa önce ölçeğin yanlış olup
/// olmadığı sorulmalı — ölçeğe yeni kademe eklemek, tek seferlik ara değer
/// yazmaktan iyidir.
library;

/// Köşe yarıçapı ölçeği — dört kademe yeter.
class AppRadius {
  const AppRadius._();

  /// Rozet, küçük etiket, ilerleme çubuğu
  static const double xs = 8;

  /// Chip, input, küçük düğme
  static const double sm = 12;

  /// Kart, liste öğesi — en yaygın kullanım
  static const double md = 16;

  /// Bottom sheet, büyük panel, öne çıkan kart
  static const double lg = 24;

  /// Tam yuvarlak (avatar, pill düğme)
  static const double pill = 999;
}

/// Boşluk ölçeği — 4'ün katları.
///
/// Dikey ritim bu değerlerden kurulur; 7, 9, 11 gibi ara değerler ekranlar
/// arası hizayı bozar.
class AppSpacing {
  const AppSpacing._();

  /// İkon ile metin arası gibi çok dar aralık
  static const double xxs = 4;

  /// Satır içi öğeler arası
  static const double xs = 8;

  /// Kart içi dikey aralık
  static const double sm = 12;

  /// Kartlar arası, bölüm içi
  static const double md = 16;

  /// Ekran kenar boşluğu — yatay padding'in standardı
  static const double lg = 20;

  /// Bölümler arası
  static const double xl = 24;

  /// Büyük ayrım
  static const double xxl = 32;
}

/// Kenarlık kalınlıkları.
class AppBorder {
  const AppBorder._();

  /// Kart ve yüzey kenarlığı
  static const double thin = 1;

  /// Seçili / aktif durum
  static const double thick = 1.5;
}
