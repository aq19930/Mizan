import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';

class ThemeToggle extends ConsumerWidget {
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;

  const ThemeToggle({
    super.key,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final defaultColor = isDark ? Colors.white : const Color(0xFF1F2937);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark
                ? Colors.white.withValues(alpha: 0.14)
                : const Color(0x150F4D3A)),
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ??
              (iconColor != null
                  ? iconColor!.withValues(alpha: 0.35)
                  : (isDark ? Colors.white24 : const Color(0x330F4D3A))),
          width: 1.3,
        ),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
        icon: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          color: iconColor ?? defaultColor,
          size: 20,
        ),
        onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
      ),
    );
  }
}
