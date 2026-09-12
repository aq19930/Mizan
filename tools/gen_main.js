const fs = require('fs');
const path = require('path');

function write(relPath, content) {
  const fullPath = path.join(__dirname, '..', 'mobile', relPath);
  const dir = path.dirname(fullPath);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(fullPath, content.trim() + '\n', 'utf8');
  console.log('Generated: ' + relPath);
}

write('lib/main.dart', `
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

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
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme(isArabic: isArabic),
      darkTheme: AppTheme.darkTheme(isArabic: isArabic),
      themeMode: themeMode,
    );
  }
}
`);

write('test/widget_test.dart', `
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/theme_provider.dart';
import 'package:mobile/core/localization/locale_provider.dart';
import 'package:mobile/shared/widgets/mizan_button.dart';

void main() {
  group('MIZAN Phase 1 & 2 Tests', () {
    test('Verify Brand Colors Palette', () {
      expect(AppColors.primaryDeepGreen, const Color(0xFF0F4D3A));
      expect(AppColors.accentGreen, const Color(0xFF22C55E));
      expect(AppColors.secondarySage, const Color(0xFFA7C957));
      expect(AppColors.backgroundCream, const Color(0xFFF5F1E8));
    });

    test('Verify Light and Dark Themes', () {
      final light = AppTheme.lightTheme(isArabic: true);
      final dark = AppTheme.darkTheme(isArabic: true);

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.scaffoldBackgroundColor, AppColors.backgroundCream);
      expect(dark.scaffoldBackgroundColor, AppColors.backgroundDark);
    });

    testWidgets('MizanButton renders correctly', (WidgetTester tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MizanButton(
              text: 'ابدأ الآن',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('ابدأ الآن'), findsOneWidget);
      await tester.tap(find.text('ابدأ الآن'));
      expect(pressed, isTrue);
    });

    test('LocaleNotifier toggles between Arabic and English', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(localeProvider.notifier);
      expect(container.read(localeProvider).languageCode, 'ar');

      notifier.toggleLocale();
      expect(container.read(localeProvider).languageCode, 'en');

      notifier.toggleLocale();
      expect(container.read(localeProvider).languageCode, 'ar');
    });

    test('ThemeNotifier toggles between Light and Dark', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);
      expect(container.read(themeModeProvider), ThemeMode.light);

      notifier.toggleTheme();
      expect(container.read(themeModeProvider), ThemeMode.dark);

      notifier.toggleTheme();
      expect(container.read(themeModeProvider), ThemeMode.light);
    });
  });
}
`);
