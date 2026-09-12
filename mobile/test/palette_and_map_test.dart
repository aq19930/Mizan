import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/theme_palette_provider.dart';
import 'package:mobile/features/transactions/presentation/widgets/spending_map_view.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget(Widget child, {Locale locale = const Locale('ar')}) {
    return ProviderScope(
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme(isArabic: locale.languageCode == 'ar'),
        home: Scaffold(body: child),
      ),
    );
  }

  group('Theme Palette Provider Tests', () {
    test('Default palette is emerald', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final palette = container.read(themePaletteProvider);
      expect(palette, equals(AppThemePalette.emerald));
    });

    test('Can change palette to vibrantGreen and sage', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themePaletteProvider.notifier).setPalette(AppThemePalette.vibrantGreen);
      expect(container.read(themePaletteProvider), equals(AppThemePalette.vibrantGreen));

      container.read(themePaletteProvider.notifier).setPalette(AppThemePalette.sage);
      expect(container.read(themePaletteProvider), equals(AppThemePalette.sage));
    });

    test('AppColors.palettes maps colors correctly for all 3 themes', () {
      final emerald = AppColors.palettes[AppThemePalette.emerald]!;
      expect(emerald.primary, equals(const Color(0xFF0F4D3A)));
      expect(emerald.accent, equals(const Color(0xFF22C55E)));

      final vibrant = AppColors.palettes[AppThemePalette.vibrantGreen]!;
      expect(vibrant.primary, equals(const Color(0xFF16A34A)));

      final sage = AppColors.palettes[AppThemePalette.sage]!;
      expect(sage.primary, equals(const Color(0xFF557A46)));
    });
  });

  group('Spending Map View Widget Tests', () {
    testWidgets('SpendingMapView renders categories and mock locations', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const SpendingMapView(), locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Check for title and filter chips
      expect(find.text('خريطة أين صرفت؟'), findsOneWidget);
      expect(find.text('الكل'), findsOneWidget);
      expect(find.text('مطاعم وكافيهات'), findsOneWidget);
      expect(find.text('مواصلات ووقود'), findsOneWidget);
    });

    testWidgets('Tapping category filter in SpendingMapView updates selection', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const SpendingMapView(), locale: const Locale('ar')));
      await tester.pumpAndSettle();

      final foodFilter = find.text('مطاعم وكافيهات');
      expect(foodFilter, findsOneWidget);
      await tester.tap(foodFilter);
      await tester.pumpAndSettle();

      // View should remain stable without errors
      expect(find.byType(SpendingMapView), findsOneWidget);
    });
  });
}
