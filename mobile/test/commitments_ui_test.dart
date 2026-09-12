import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/commitments/presentation/commitments_screen.dart';
import 'package:mobile/features/commitments/presentation/add_commitment_screen.dart';
import 'package:mobile/features/setup/presentation/commitments_setup_screen.dart';
import 'package:mobile/features/bank_parser/presentation/review_detected_transaction_screen.dart';
import 'package:mobile/features/bank_parser/presentation/parser_debug_screen.dart';
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

  group('Commitments & Bank Parser Screens Widget Tests', () {
    testWidgets('CommitmentsScreen renders summary and tabs', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const CommitmentsScreen()));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(CommitmentsScreen), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('AddCommitmentScreen renders all form fields', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const AddCommitmentScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(AddCommitmentScreen), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(4)); // title, amount, merchant, notes
    });

    testWidgets('CommitmentsSetupScreen renders onboarding step 3/7', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const CommitmentsSetupScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(CommitmentsSetupScreen), findsOneWidget);
      expect(find.byType(Checkbox), findsWidgets);
    });

    testWidgets('ReviewDetectedTransactionScreen renders detected transaction info', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const ReviewDetectedTransactionScreen()));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(ReviewDetectedTransactionScreen), findsOneWidget);
      expect(find.text('AL RAJHI BANK LEASING'), findsOneWidget);
    });

    testWidgets('ParserDebugScreen renders presets and analyzer', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const ParserDebugScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ParserDebugScreen), findsOneWidget);
      expect(find.byType(FilterChip), findsWidgets);
    });
  });
}
