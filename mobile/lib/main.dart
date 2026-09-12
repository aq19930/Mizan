import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/localization/locale_provider.dart';
import 'core/notifications/notification_service.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_palette_provider.dart';
import 'core/theme/theme_provider.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService().initialize();
  } catch (_) {}
  runApp(const ProviderScope(child: MizanApp()));
}

class MizanApp extends ConsumerWidget {
  const MizanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final currentPalette = ref.watch(themePaletteProvider);
    final isArabic = currentLocale.languageCode == 'ar';

    return MaterialApp.router(
      title: 'MIZAN — ميزان',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      locale: currentLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.lightTheme(isArabic: isArabic, palette: currentPalette),
      darkTheme: AppTheme.darkTheme(isArabic: isArabic, palette: currentPalette),
      themeMode: themeMode,
    );
  }
}
