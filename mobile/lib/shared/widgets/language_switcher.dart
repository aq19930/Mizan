import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_colors.dart';

class LanguageSwitcher extends ConsumerWidget {
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;

  const LanguageSwitcher({
    super.key,
    this.color,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isArabic = currentLocale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // High-contrast, crystal-clear color resolution
    final effectiveColor = color ?? (isDark ? Colors.white : AppColors.darkText);
    final effectiveBackground = backgroundColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.14)
            : AppColors.primaryDeepGreen.withValues(alpha: 0.08));
    final effectiveBorder = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.30)
            : AppColors.primaryDeepGreen.withValues(alpha: 0.25));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => ref.read(localeProvider.notifier).toggleLocale(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: effectiveBackground,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: effectiveBorder, width: 1.4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language_rounded,
                size: 19,
                color: effectiveColor,
              ),
              const SizedBox(width: 7),
              Text(
                isArabic ? 'English' : 'العربية',
                style: TextStyle(
                  color: effectiveColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
