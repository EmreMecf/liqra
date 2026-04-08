import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Liqra Tipografi Sistemi
///
/// Başlıklar / Display : Fraunces  (serif, w700–w900) — güçlü, özgün
/// UI / Gövde          : Outfit    (sans-serif, w300–w700) — temiz, modern
/// Fiyat / Mono        : DM Mono   (monospace, w400–w500) — hassas, teknik
class AppTypography {
  // ── Display — Fraunces (Hero sayılar, ana başlıklar) ──────────────────────

  /// 52px — Splash, ana ekran hero
  static TextStyle get display => GoogleFonts.fraunces(
        fontSize: 52,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
        letterSpacing: -1.5,
        height: 1.0,
      );

  // ── Başlıklar — Fraunces ──────────────────────────────────────────────────

  static TextStyle get headlineL => GoogleFonts.fraunces(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.15,
      );

  static TextStyle get headlineM => GoogleFonts.fraunces(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
        height: 1.2,
      );

  static TextStyle get headlineS => GoogleFonts.fraunces(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
        height: 1.25,
      );

  // ── Sayısal Değerler — DM Mono ────────────────────────────────────────────

  static TextStyle get numberXL => GoogleFonts.dmMono(
        fontSize: 32,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get numberL => GoogleFonts.dmMono(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get numberM => GoogleFonts.dmMono(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get numberS => GoogleFonts.dmMono(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  /// Teal renkte vurgulu mono — fiyat, kod, sembol
  static TextStyle get monoHighlight => GoogleFonts.dmMono(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.accentGreen,
      );

  // ── Gövde Metni — Outfit ──────────────────────────────────────────────────

  static TextStyle get bodyL => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w300,
        color: AppColors.textSecondary,
        height: 1.7,
      );

  static TextStyle get bodyM => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w300,
        color: AppColors.textSecondary,
        height: 1.65,
      );

  static TextStyle get bodyS => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w300,
        color: AppColors.textSecondary,
        height: 1.55,
      );

  // ── Etiketler — Outfit ────────────────────────────────────────────────────

  static TextStyle get labelM => GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      );

  static TextStyle get labelS => GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      );

  /// Üst büyük harf etiket — DM Mono ile (bölüm başlıkları)
  static TextStyle get capsLabel => GoogleFonts.dmMono(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: AppColors.textDisabled,
        letterSpacing: 1.6,
      );

  // ── Buton ─────────────────────────────────────────────────────────────────

  static TextStyle get button => GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.bgPrimary,
        letterSpacing: 0.2,
      );
}
