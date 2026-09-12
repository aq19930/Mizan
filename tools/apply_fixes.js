const fs = require('fs');
const path = require('path');

function updateFile(relPath, replacer) {
  const fullPath = path.join('mobile', relPath);
  let content = fs.readFileSync(fullPath, 'utf8');
  content = replacer(content);
  fs.writeFileSync(fullPath, content, 'utf8');
  console.log('Updated: ' + relPath);
}

// 1. Fix CardTheme -> CardThemeData in app_theme.dart
updateFile('lib/core/theme/app_theme.dart', c => c.replaceAll('CardTheme(', 'CardThemeData('));

// 2. Fix import in login_screen.dart
updateFile('lib/features/auth/presentation/login_screen.dart', c => 
  c.replace("import 'package:flutter_gen/gen_l10n/app_localizations.dart';", "import '../../../l10n/app_localizations.dart';")
);

// 3. Fix import in home_screen.dart
updateFile('lib/features/home/presentation/home_screen.dart', c => 
  c.replace("import 'package:flutter_gen/gen_l10n/app_localizations.dart';", "import '../../../l10n/app_localizations.dart';")
);

// 4. Fix import in onboarding_screen.dart
updateFile('lib/features/onboarding/presentation/onboarding_screen.dart', c => 
  c.replace("import 'package:flutter_gen/gen_l10n/app_localizations.dart';", "import '../../../l10n/app_localizations.dart';")
);

// 5. Fix splash_screen async gap
updateFile('lib/features/splash/presentation/splash_screen.dart', c => {
  return c.replace(
    `    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool(AppConstants.prefKeyOnboardingComplete) ?? false;

    if (onboardingDone) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.onboarding);
    }`,
    `    await Future.delayed(const Duration(milliseconds: 2200));
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool(AppConstants.prefKeyOnboardingComplete) ?? false;

    if (!mounted) return;

    if (onboardingDone) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.onboarding);
    }`
  );
});

// 6. Fix main.dart localizations
updateFile('lib/main.dart', c => {
  return `import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/localization/locale_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MizanApp()));
}

class MizanApp extends ConsumerWidget {
  const MizanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isArabic = currentLocale.languageCode == 'ar';

    return MaterialApp.router(
      title: 'MIZAN — ميزان',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      locale: currentLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.lightTheme(isArabic: isArabic),
      darkTheme: AppTheme.darkTheme(isArabic: isArabic),
      themeMode: themeMode,
    );
  }
}
`;
});

console.log('All fixes applied!');
