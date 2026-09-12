import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/notifications/daily_financial_summary.dart';
import 'package:mobile/core/notifications/notification_provider.dart';
import 'package:mobile/core/notifications/notification_service.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/home/presentation/home_screen.dart';
import 'package:mobile/features/more/presentation/more_screen.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockNotificationService implements NotificationService {
  bool permissionsRequested = false;
  bool dailyScheduled = false;
  bool dailyCancelled = false;
  DailyFinancialSummary? lastSummary;
  TimeOfDay? lastScheduledTime;
  int showCallCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermissions() async {
    permissionsRequested = true;
    return true;
  }

  @override
  Future<void> scheduleDailySummaryNotification({
    required TimeOfDay time,
    required DailyFinancialSummary summary,
    bool isArabic = true,
  }) async {
    dailyScheduled = true;
    lastScheduledTime = time;
    lastSummary = summary;
  }

  @override
  Future<void> cancelDailySummaryNotification() async {
    dailyCancelled = true;
    dailyScheduled = false;
  }

  @override
  Future<void> showDailySummaryNotification(
    DailyFinancialSummary summary, {
    bool isArabic = true,
  }) async {
    showCallCount++;
    lastSummary = summary;
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  group('DailyFinancialSummary Model Tests', () {
    test('Correctly formats Arabic notification title and body with all 3 metrics', () {
      final summary = DailyFinancialSummary(
        spentToday: 137.50,
        remainingBudget: 3750.0,
        recommendedTomorrow: 140.0,
        timestamp: DateTime(2026, 9, 12),
      );

      final title = summary.getNotificationTitle(true);
      final body = summary.getNotificationBody(true);

      expect(title, contains('ملخص ميزان المالي اليومي'));
      // Check for 1: كم صرفت اليوم
      expect(body, contains('صرفت اليوم: 137.50 ر.س'));
      // Check for 2: كم المتبقي
      expect(body, contains('المتبقي: 3750 ر.س'));
      // Check for 3: كم المفروض تصرف بكره
      expect(body, contains('الموصى به لغداً: 140 ر.س'));
    });

    test('Correctly formats English notification title and body with all 3 metrics', () {
      final summary = DailyFinancialSummary(
        spentToday: 215.20,
        remainingBudget: 2800.0,
        recommendedTomorrow: 110.0,
        timestamp: DateTime(2026, 9, 12),
      );

      final title = summary.getNotificationTitle(false);
      final body = summary.getNotificationBody(false);

      expect(title, contains('Mizan Daily Financial Summary'));
      expect(body, contains('Spent today: 215.20 SAR'));
      expect(body, contains('Left: 2800 SAR'));
      expect(body, contains('Tomorrow limit: 110 SAR'));
    });
  });

  group('NotificationSettingsProvider Tests', () {
    test('Initializes with default values and scheduled evening alert', () {
      final mock = MockNotificationService();
      final container = ProviderContainer(
        overrides: [
          notificationServiceProvider.overrideWithValue(mock),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(notificationSettingsProvider);
      expect(state.isDailyEnabled, isTrue);
      expect(state.summaryTime.hour, equals(21));
      expect(state.summaryTime.minute, equals(0));
      expect(state.currentSummary.spentToday, equals(137.50));
      expect(state.currentSummary.remainingBudget, equals(3750.0));
      expect(state.currentSummary.recommendedTomorrow, equals(140.0));
    });

    test('Updates financial numbers dynamically', () {
      final mock = MockNotificationService();
      final container = ProviderContainer(
        overrides: [
          notificationServiceProvider.overrideWithValue(mock),
        ],
      );
      addTearDown(container.dispose);

      container.read(notificationSettingsProvider.notifier).updateFinancials(
            spentToday: 320.0,
            remainingBudget: 1500.0,
            recommendedTomorrow: 95.0,
          );

      final state = container.read(notificationSettingsProvider);
      expect(state.currentSummary.spentToday, equals(320.0));
      expect(state.currentSummary.remainingBudget, equals(1500.0));
      expect(state.currentSummary.recommendedTomorrow, equals(95.0));
    });

    test('Toggles notification enabled state and calls mock service', () async {
      final mock = MockNotificationService();
      final container = ProviderContainer(
        overrides: [
          notificationServiceProvider.overrideWithValue(mock),
        ],
      );
      addTearDown(container.dispose);

      await container.read(notificationSettingsProvider.notifier).toggleDailyEnabled(false);
      expect(container.read(notificationSettingsProvider).isDailyEnabled, isFalse);
      expect(mock.dailyCancelled, isTrue);

      await container.read(notificationSettingsProvider.notifier).toggleDailyEnabled(true);
      expect(container.read(notificationSettingsProvider).isDailyEnabled, isTrue);
      expect(mock.dailyScheduled, isTrue);
    });

    test('Sends test notification successfully with all 3 metrics', () async {
      final mock = MockNotificationService();
      final container = ProviderContainer(
        overrides: [
          notificationServiceProvider.overrideWithValue(mock),
        ],
      );
      addTearDown(container.dispose);

      final success = await container
          .read(notificationSettingsProvider.notifier)
          .sendTestNotification(isArabic: true);

      expect(success, isTrue);
      expect(mock.showCallCount, equals(1));
      expect(mock.lastSummary?.spentToday, equals(137.50));
      expect(mock.lastSummary?.remainingBudget, equals(3750.0));
      expect(mock.lastSummary?.recommendedTomorrow, equals(140.0));
      expect(container.read(notificationSettingsProvider).lastSentMessage, contains('137.50'));
    });
  });

  group('UI Widgets Tests for Daily Financial Notifications', () {
    testWidgets('MoreScreen displays Daily Financial Summary notification card & preview',
        (tester) async {
      final mock = MockNotificationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWithValue(mock),
          ],
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.lightTheme(isArabic: true),
            home: const MoreScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the notification section header and preview exist
      expect(find.text('إشعارات وملخص المصاريف اليومي'), findsOneWidget);
      expect(find.text('تنبيه الملخص اليومي للمصاريف'), findsOneWidget);
      expect(find.text('صرفت اليوم'), findsOneWidget);
      expect(find.text('كم المتبقي'), findsOneWidget);
      expect(find.text('كم المفروض بكره'), findsOneWidget);

      // Verify test button exists
      final testBtn = find.text('تجربة إرسال الإشعار الآن للجوال');
      expect(testBtn, findsOneWidget);

      // Scroll until visible and tap test button
      await tester.ensureVisible(testBtn);
      await tester.pumpAndSettle();
      await tester.tap(testBtn);
      await tester.pumpAndSettle();

      expect(mock.showCallCount, equals(1));
    });

    testWidgets('HomeScreen notification bell opens Daily Financial Summary bottom sheet',
        (tester) async {
      final mock = MockNotificationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWithValue(mock),
          ],
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.lightTheme(isArabic: true),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the notification bell icon
      final bellIcon = find.byIcon(Icons.notifications_none_rounded);
      expect(bellIcon, findsOneWidget);

      // Tap the bell icon
      await tester.tap(bellIcon);
      await tester.pumpAndSettle();

      // Verify the bottom sheet opened with title and 3 metrics
      expect(find.text('تنبيه ملخصك المالي اليومي'), findsOneWidget);
      expect(find.text('كم صرفت اليوم:'), findsOneWidget);
      expect(find.text('كم المتبقي من الميزانية:'), findsOneWidget);
      expect(find.text('كم المفروض تصرف بكره:'), findsOneWidget);

      // Verify test button in bottom sheet
      final testModalBtn = find.text('تجربة إرسال الإشعار الآن للجوال');
      expect(testModalBtn, findsOneWidget);

      // Tap test button in bottom sheet
      await tester.tap(testModalBtn);
      await tester.pumpAndSettle();

      expect(mock.showCallCount, equals(1));
    });
  });
}
