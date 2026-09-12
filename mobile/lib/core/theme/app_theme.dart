import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme({bool isArabic = true, AppThemePalette palette = AppThemePalette.emerald}) {
    final colors = AppColors.getPalette(palette);
    final fontFamily = isArabic
        ? (GoogleFonts.config.allowRuntimeFetching ? GoogleFonts.cairo().fontFamily : 'Cairo')
        : (GoogleFonts.config.allowRuntimeFetching ? GoogleFonts.inter().fontFamily : 'Inter');

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.light,
      primaryColor: colors.primary,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.light(
        primary: colors.primary,
        secondary: colors.secondary,
        tertiary: colors.accent,
        surface: colors.cardBackground,
        error: AppColors.expense,
        onPrimary: AppColors.white,
        onSecondary: AppColors.darkText,
        onSurface: AppColors.darkText,
      ),
      cardTheme: CardThemeData(
        color: colors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkText),
        titleTextStyle: const TextStyle(color: AppColors.darkText, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      textTheme: AppTypography.createTextTheme(isDark: false, isArabic: isArabic),
    );
  }

  static ThemeData darkTheme({bool isArabic = true, AppThemePalette palette = AppThemePalette.emerald}) {
    final colors = AppColors.getPalette(palette);
    final fontFamily = isArabic
        ? (GoogleFonts.config.allowRuntimeFetching ? GoogleFonts.cairo().fontFamily : 'Cairo')
        : (GoogleFonts.config.allowRuntimeFetching ? GoogleFonts.inter().fontFamily : 'Inter');

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.dark,
      primaryColor: colors.accent,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: ColorScheme.dark(
        primary: colors.accent,
        secondary: colors.secondary,
        surface: AppColors.surfaceDark,
        error: AppColors.expense,
        onPrimary: AppColors.darkText,
        onSecondary: AppColors.white,
        onSurface: AppColors.textLight,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.textLight),
        titleTextStyle: TextStyle(color: AppColors.textLight, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGreen,
          foregroundColor: AppColors.primaryDeepGreen,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      textTheme: AppTypography.createTextTheme(isDark: true, isArabic: isArabic),
    );
  }
}
