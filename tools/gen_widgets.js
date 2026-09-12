const fs = require('fs');
const path = require('path');

function write(relPath, content) {
  const fullPath = path.join(__dirname, '..', 'mobile', relPath);
  const dir = path.dirname(fullPath);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(fullPath, content.trim() + '\n', 'utf8');
  console.log('Generated: ' + relPath);
}

write('lib/shared/widgets/mizan_button.dart', `
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class MizanButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isLoading;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? textColor;

  const MizanButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? Theme.of(context).colorScheme.primary,
          side: BorderSide(
            color: backgroundColor ?? Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        child: _buildChild(context),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.primaryDeepGreen,
        foregroundColor: textColor ?? AppColors.white,
      ),
      child: _buildChild(context),
    );
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
}
`);

write('lib/shared/widgets/mizan_card.dart', `
import 'package:flutter/material.dart';

class MizanCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const MizanCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final cardBorderRadius = borderRadius ?? BorderRadius.circular(16);

    return Material(
      color: color ?? Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: cardBorderRadius,
        side: Theme.of(context).cardTheme.shape is RoundedRectangleBorder
            ? (Theme.of(context).cardTheme.shape as RoundedRectangleBorder).side
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: cardBorderRadius,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }
}
`);

write('lib/shared/widgets/mizan_logo.dart', `
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class MizanLogo extends StatelessWidget {
  final double width;
  final double? height;
  final bool useDarkVariant;

  const MizanLogo({
    super.key,
    this.width = 200,
    this.height,
    this.useDarkVariant = true,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = useDarkVariant ? AppConstants.logoDark : AppConstants.logoLight;

    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
`);

write('lib/shared/widgets/language_switcher.dart', `
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_colors.dart';

class LanguageSwitcher extends ConsumerWidget {
  final Color? color;

  const LanguageSwitcher({super.key, this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isArabic = currentLocale.languageCode == 'ar';

    return TextButton.icon(
      onPressed: () => ref.read(localeProvider.notifier).toggleLocale(),
      icon: Icon(Icons.language, size: 18, color: color ?? Theme.of(context).colorScheme.primary),
      label: Text(
        isArabic ? 'English' : 'العربية',
        style: TextStyle(
          color: color ?? Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        backgroundColor: (color != null ? Colors.white.withValues(alpha: 0.15) : AppColors.secondarySage.withValues(alpha: 0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
`);

write('lib/shared/widgets/theme_toggle.dart', `
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';

class ThemeToggle extends ConsumerWidget {
  final Color? iconColor;

  const ThemeToggle({super.key, this.iconColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return IconButton(
      tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      icon: Icon(
        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        color: iconColor ?? Theme.of(context).iconTheme.color,
      ),
      onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
    );
  }
}
`);
