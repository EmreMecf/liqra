import 'package:flutter/material.dart';

/// Liqra — Marka Renk Sistemi
/// "Likit paranın zekası" — Dark-first, Teal-primary
class AppColors {
  // ── Zemin Katmanları (ink → lift) ──────────────────────────────────────────
  /// En derin arka plan — sayfa zemini
  static const Color bgPrimary   = Color(0xFF05080F); // ink
  /// Kart zemini
  static const Color bgSecondary = Color(0xFF161D2E); // card
  /// Input, chip, yükseltilmiş yüzey
  static const Color bgTertiary  = Color(0xFF1F2A40); // lift

  // Ek zemin tonları
  static const Color bgVoid    = Color(0xFF0C1120); // en koyu
  static const Color bgSurface = Color(0xFF111827); // yüzey
  static const Color bgCard    = Color(0xFF161D2E); // kart
  static const Color bgCard2   = Color(0xFF1A2235); // kart hover
  static const Color bgLift    = Color(0xFF1F2A40); // yükseltilmiş

  // ── Ana Vurgu — Liqra Teal ─────────────────────────────────────────────────
  /// Birincil aksent — tüm CTA, kâr, onay, aktif durum
  static const Color accentGreen = Color(0xFF0AFFE0); // Liqra Teal
  static const Color accentTeal  = Color(0xFF00C9B1); // Teal ikincil
  static const Color accentTealD = Color(0xFF007A6D); // Teal koyu

  /// Liqra teal için bg ve border opacity'si
  static const Color liqraBg  = Color(0x120AFFE0); // %7 alpha
  static const Color liqraBdr = Color(0x380AFFE0); // %22 alpha

  // ── İkincil Vurgu — Gold ──────────────────────────────────────────────────
  /// Altın / yüksek risk / premium özellikler
  static const Color accentAmber = Color(0xFFE4B84A); // Brand Gold
  static const Color accentGold  = Color(0xFFE4B84A); // alias
  static const Color goldBright  = Color(0xFFF7D470); // parlak altın

  static const Color goldBg  = Color(0x17E4B84A); // %9 alpha
  static const Color goldBdr = Color(0x47E4B84A); // %28 alpha

  // ── Tehlike / Negatif ─────────────────────────────────────────────────────
  static const Color accentRed  = Color(0xFFFF4757);
  static const Color redBg      = Color(0x1AFF4757); // %10 alpha

  // ── Bilgi / Link ─────────────────────────────────────────────────────────
  static const Color accentBlue = Color(0xFF3B82F6);

  // ── Metin ────────────────────────────────────────────────────────────────
  /// Birincil metin
  static const Color textPrimary   = Color(0xFFD6DCF0); // text
  /// İkincil metin / açıklama
  static const Color textSecondary = Color(0xFF8B96B0); // silver
  /// Devre dışı / pasif
  static const Color textDisabled  = Color(0xFF4A5570); // dim

  // ── Kenarlıklar ──────────────────────────────────────────────────────────
  static const Color borderSubtle = Color(0x12FFFFFF); // rgba(255,255,255, 0.07)
  static const Color borderMedium = Color(0x21FFFFFF); // rgba(255,255,255, 0.13)
  static const Color borderActive = Color(0x380AFFE0); // Liqra teal border

  // ── Grafik Renkleri ───────────────────────────────────────────────────────
  static const List<Color> chartColors = [
    Color(0xFF0AFFE0), // liqra teal
    Color(0xFFE4B84A), // gold
    Color(0xFFFF4757), // red
    Color(0xFF3B82F6), // blue
    Color(0xFFF7D470), // gold bright
    Color(0xFF8B5CF6), // purple
    Color(0xFF00C9B1), // teal 2
    Color(0xFFFF6B7A), // red light
  ];
}
