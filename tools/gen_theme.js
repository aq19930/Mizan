const fs = require('fs');
const path = require('path');

function write(relPath, content) {
  const fullPath = path.join(__dirname, '..', 'mobile', relPath);
  const dir = path.dirname(fullPath);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(fullPath, content.trim() + '\n', 'utf8');
  console.log('Generated: ' + relPath);
}

write('lib/core/theme/app_colors.dart', `
import 'package:flutter/material.dart';

class AppColors {
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
  static const Color textMutedDark = Color(0xFF9CA3AF);

  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE5DECE);
  static const Color textMutedLight = Color(0xFF6B7280);

  static const Color income = Color(0xFF22C55E);
  static const Color expense = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  static const Color catFood = Color(0xFFF59E0B);
  static const Color catTransport = Color(0xFF3B82F6);
  static const Color catShopping = Color(0xFFEC4899);
  static const Color catBills = Color(0xFF8B5CF6);
  static const Color catEntertainment = Color(0xFF10B981);
}
`);

write('lib/core/theme/app_typography.dart', `
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
  }) {
    if (isArabic) {
      return GoogleFonts.ibmPlexSansArabic(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height ?? 1.4,
      );
    }
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height ?? 1.3,
    );
  }

  static TextTheme createTextTheme({required bool isDark, required bool isArabic}) {
    final textColor = isDark ? AppColors.textLight : AppColors.darkText;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return TextTheme(
      displayLarge: _font(isArabic: isArabic, fontSize: 32, fontWeight: FontWeight.w700, color: textColor),
      displayMedium: _font(isArabic: isArabic, fontSize: 28, fontWeight: FontWeight.w700, color: textColor),
      headlineLarge: _font(isArabic: isArabic, fontSize: 24, fontWeight: FontWeight.w600, color: textColor),
      headlineMedium: _font(isArabic: isArabic, fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
      titleLarge: _font(isArabic: isArabic, fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
      titleMedium: _font(isArabic: isArabic, fontSize: 16, fontWeight: FontWeight.w500, color: textColor),
      bodyLarge: _font(isArabic: isArabic, fontSize: 16, fontWeight: FontWeight.w400, color: textColor),
      bodyMedium: _font(isArabic: isArabic, fontSize: 14, fontWeight: FontWeight.w400, color: textColor),
      bodySmall: _font(isArabic: isArabic, fontSize: 12, fontWeight: FontWeight.w400, color: textMuted),
      labelLarge: _font(isArabic: isArabic, fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
    );
  }
}
`);
