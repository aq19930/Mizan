import 'package:flutter/material.dart';

class AppColors {
  // Compatibility Aliases
  static const Color accentBrightGreen = accentGreen;
  static const Color secondarySageGreen = secondarySage;
  static const Color creamBackground = backgroundCream;
  static const Color darkBackground = backgroundDark;
  static const Color darkSurface = surfaceDark;
  static const Color lightSurface = surfaceLight;
  static const Color darkBorder = borderDark;
  static const Color lightBorder = borderLight;
  static const Color darkTextPrimary = textLight;
  static const Color darkTextSecondary = textMutedDark;
  static const Color lightTextPrimary = darkText;
  static const Color lightTextSecondary = textMutedLight;
  static const Color dangerRed = expense;
  static const Color warningAmber = warning;

  AppColors._();

  static const Color primaryDeepGreen = Color(0xFF0F4D3A);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color secondarySage = Color(0xFFA7C957);
  static const Color backgroundCream = Color(0xFFF5F1E8);
  static const Color darkText = Color(0xFF1F2937);
  static const Color neutralBeige = Color(0xFFD4C9B6);
  static const Color white = Color(0xFFFFFFFF);

  static const Color backgroundDark = Color(0xFF091410);
  static const Color surfaceDark = Color(0xFF0F261E);
  static const Color cardDark = Color(0xFF153328);
  static const Color borderDark = Color(0xFF234B3D);
  static const Color textLight = Color(0xFFF9FAFB);
  static const Color textMutedDark = Color(0xFFD1D5DB);

  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE5DECE);
  static const Color textMutedLight = Color(0xFF374151);

  static const Color income = Color(0xFF22C55E);
  static const Color expense = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  static const Color catFood = Color(0xFFF59E0B);
  static const Color catTransport = Color(0xFF3B82F6);
  static const Color catShopping = Color(0xFFEC4899);
  static const Color catBills = Color(0xFF8B5CF6);
  static const Color catEntertainment = Color(0xFF10B981);

  static const Map<AppThemePalette, PaletteColors> palettes = {
    AppThemePalette.emerald: PaletteColors(
      primary: Color(0xFF0F4D3A),
      accent: Color(0xFF22C55E),
      secondary: Color(0xFFA7C957),
      background: Color(0xFFF5F1E8),
      cardBackground: Color(0xFFFFFFFF),
      nameAr: 'الزمردي الملكي',
      nameEn: 'Royal Emerald',
    ),
    AppThemePalette.vibrantGreen: PaletteColors(
      primary: Color(0xFF16A34A),
      accent: Color(0xFF22C55E),
      secondary: Color(0xFFA7C957),
      background: Color(0xFFF6FAF6),
      cardBackground: Color(0xFFFFFFFF),
      nameAr: 'الأخضر الحيوي',
      nameEn: 'Vibrant Green',
    ),
    AppThemePalette.sage: PaletteColors(
      primary: Color(0xFF557A46),
      accent: Color(0xFFA7C957),
      secondary: Color(0xFFD4C9B6),
      background: Color(0xFFF7F5EE),
      cardBackground: Color(0xFFFFFFFF),
      nameAr: 'الميرمية الهادئ',
      nameEn: 'Calm Sage',
    ),
  };

  static PaletteColors getPalette(AppThemePalette palette) => palettes[palette] ?? palettes[AppThemePalette.emerald]!;
}

enum AppThemePalette {
  emerald,
  vibrantGreen,
  sage,
}

class PaletteColors {
  final Color primary;
  final Color accent;
  final Color secondary;
  final Color background;
  final Color cardBackground;
  final String nameAr;
  final String nameEn;

  const PaletteColors({
    required this.primary,
    required this.accent,
    required this.secondary,
    required this.background,
    required this.cardBackground,
    required this.nameAr,
    required this.nameEn,
  });
}
