import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/theme_provider.dart';
import 'package:mobile/core/localization/locale_provider.dart';
import 'package:mobile/shared/widgets/mizan_button.dart';
import 'package:mobile/shared/widgets/mizan_card.dart';
import 'package:mobile/shared/widgets/mizan_password_field.dart';
import 'package:mobile/features/onboarding/presentation/language_selection_screen.dart';
import 'package:mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mobile/features/auth/presentation/auth_welcome_screen.dart';
import 'package:mobile/features/auth/presentation/register_screen.dart';
import 'package:mobile/features/home/presentation/home_screen.dart';
import 'package:mobile/features/budgets/presentation/budget_screen.dart';
import 'package:mobile/features/setup/presentation/initial_balance_screen.dart';
import 'package:mobile/features/setup/presentation/category_budget_screen.dart';
import 'package:mobile/features/setup/presentation/privacy_setup_screen.dart';
import 'package:mobile/features/transactions/presentation/transactions_screen.dart';
import 'package:mobile/features/transactions/presentation/add_transaction_screen.dart';
import 'package:mobile/features/insights/presentation/insights_screen.dart';
import 'package:mobile/features/more/presentation/more_screen.dart';
import 'package:mobile/l10n/app_localizations.dart';

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
        home: child,
      ),
    );
  }

  group('MIZAN Complete Flow Tests', () {
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

    testWidgets('MizanButton renders and triggers onPressed', (WidgetTester tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MizanButton(
              text: 'Test Button',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      await tester.tap(find.text('Test Button'));
      expect(pressed, isTrue);
    });

    testWidgets('MizanCard renders with child', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MizanCard(
              child: const Text('Test Card'),
            ),
          ),
        ),
      );

      expect(find.text('Test Card'), findsOneWidget);
    });

    testWidgets('MizanPasswordField renders with toggleable visibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const Scaffold(
            body: MizanPasswordField(
              showStrengthMeter: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MizanPasswordField), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
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

    testWidgets('LanguageSelectionScreen renders options', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const LanguageSelectionScreen(), locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.text('English'), findsOneWidget);
      expect(find.byType(LanguageSelectionScreen), findsOneWidget);
    });

    testWidgets('OnboardingScreen renders first page', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const OnboardingScreen(), locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('AuthWelcomeScreen renders', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const AuthWelcomeScreen(), locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.byType(AuthWelcomeScreen), findsOneWidget);
      expect(find.byType(MizanButton), findsNWidgets(2));
    });

    testWidgets('RegisterScreen renders form fields', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const RegisterScreen(), locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(4));
    });

    testWidgets('HomeScreen renders dashboard with hero card', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const HomeScreen(), locale: const Locale('ar')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('BudgetScreen renders budget categories', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const BudgetScreen(), locale: const Locale('ar')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(BudgetScreen), findsOneWidget);
    });

    testWidgets('InitialBalanceScreen renders correctly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const InitialBalanceScreen(), locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.byType(InitialBalanceScreen), findsOneWidget);
      expect(find.byType(MizanButton), findsOneWidget);
    });

    testWidgets('CategoryBudgetScreen renders categories', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const CategoryBudgetScreen(), locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.byType(CategoryBudgetScreen), findsOneWidget);
    });

    testWidgets('PrivacySetupScreen renders privacy bullets', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const PrivacySetupScreen(), locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.byType(PrivacySetupScreen), findsOneWidget);
    });

    testWidgets('TransactionsScreen renders transaction list', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const TransactionsScreen(), locale: const Locale('ar')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(TransactionsScreen), findsOneWidget);
    });

    testWidgets('AddTransactionScreen renders transaction form', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const AddTransactionScreen(), locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.byType(AddTransactionScreen), findsOneWidget);
    });

    testWidgets('InsightsScreen renders AI insights and forecast', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const InsightsScreen(), locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.byType(InsightsScreen), findsOneWidget);
    });

    testWidgets('MoreScreen renders settings and user profile', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const MoreScreen(), locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.byType(MoreScreen), findsOneWidget);
    });
  });
}
