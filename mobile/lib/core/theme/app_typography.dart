import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle _font({
    required bool isArabic,
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) {
    if (!GoogleFonts.config.allowRuntimeFetching) {
      return TextStyle(
        fontFamily: isArabic ? 'Cairo' : 'Inter',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height ?? (isArabic ? 1.35 : 1.3),
        letterSpacing: letterSpacing,
      );
    }

    if (isArabic) {
      return GoogleFonts.cairo(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height ?? 1.35,
        letterSpacing: letterSpacing,
      );
    }
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height ?? 1.3,
      letterSpacing: letterSpacing,
    );
  }

  static TextTheme createTextTheme({required bool isDark, required bool isArabic}) {
    final textColor = isDark ? AppColors.textLight : AppColors.darkText;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return TextTheme(
      displayLarge: _font(isArabic: isArabic, fontSize: 32, fontWeight: FontWeight.w800, color: textColor),
      displayMedium: _font(isArabic: isArabic, fontSize: 28, fontWeight: FontWeight.w800, color: textColor),
      displaySmall: _font(isArabic: isArabic, fontSize: 24, fontWeight: FontWeight.w700, color: textColor),
      headlineLarge: _font(isArabic: isArabic, fontSize: 24, fontWeight: FontWeight.w700, color: textColor),
      headlineMedium: _font(isArabic: isArabic, fontSize: 20, fontWeight: FontWeight.w700, color: textColor),
      headlineSmall: _font(isArabic: isArabic, fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
      titleLarge: _font(isArabic: isArabic, fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
      titleMedium: _font(isArabic: isArabic, fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      titleSmall: _font(isArabic: isArabic, fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: _font(isArabic: isArabic, fontSize: 16, fontWeight: FontWeight.w500, color: textColor),
      bodyMedium: _font(isArabic: isArabic, fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
      bodySmall: _font(isArabic: isArabic, fontSize: 12.5, fontWeight: FontWeight.w500, color: textMuted),
      labelLarge: _font(isArabic: isArabic, fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
      labelMedium: _font(isArabic: isArabic, fontSize: 12, fontWeight: FontWeight.w600, color: textMuted),
      labelSmall: _font(isArabic: isArabic, fontSize: 11, fontWeight: FontWeight.w600, color: textMuted),
    );
  }
}
