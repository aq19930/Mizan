import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'daily_financial_summary.dart';

class NotificationService {
  static NotificationService? _instance;
  factory NotificationService() => _instance ??= NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const int kDailySummaryNotificationId = 1001;
  static const String kDailyChannelId = 'mizan_daily_financial_summary';
  static const String kDailyChannelName = 'الملخص المالي اليومي (Mizan Daily)';
  static const String kDailyChannelDescription = 'تنبيه مسائي يوضح كم صرفت اليوم والمتبقي والحد الموصى به للغد';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize timezone database
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
      } catch (_) {
        try {
          tz.setLocalLocation(tz.getLocation('UTC'));
        } catch (_) {}
      }

      // 2. Platform initialization settings
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped: ${response.payload}');
        },
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService initialize warning: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      if (kIsWeb) return false;

      if (Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidImplementation?.requestNotificationsPermission();
        return granted ?? true;
      } else if (Platform.isIOS) {
        final iosImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosImplementation?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? true;
      }
    } catch (e) {
      debugPrint('Permission request error: $e');
    }
    return true;
  }

  NotificationDetails _createNotificationDetails(DailyFinancialSummary summary, bool isArabic) {
    final title = summary.getNotificationTitle(isArabic);

    final bigTextStyleInformation = BigTextStyleInformation(
      '• ${isArabic ? "صرفت اليوم" : "Spent today"}: ${summary.spentToday.toStringAsFixed(2)} ${isArabic ? "ر.س" : "SAR"}\n'
      '• ${isArabic ? "المتبقي من الميزانية" : "Remaining budget"}: ${summary.remainingBudget.toStringAsFixed(0)} ${isArabic ? "ر.س" : "SAR"}\n'
      '• ${isArabic ? "الموصى به لغداً" : "Recommended for tomorrow"}: ${summary.recommendedTomorrow.toStringAsFixed(0)} ${isArabic ? "ر.س" : "SAR"}',
      contentTitle: title,
      summaryText: isArabic ? 'ميزان — ملخص اليوم' : 'Mizan — Today\'s Summary',
    );

    final androidDetails = AndroidNotificationDetails(
      kDailyChannelId,
      kDailyChannelName,
      channelDescription: kDailyChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: bigTextStyleInformation,
      color: const Color(0xFF0F4D3A),
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Send immediate summary notification (e.g. Test / On-demand)
  Future<void> showDailySummaryNotification(
    DailyFinancialSummary summary, {
    bool isArabic = true,
  }) async {
    await initialize();

    try {
      final details = _createNotificationDetails(summary, isArabic);
      await _notificationsPlugin.show(
        id: kDailySummaryNotificationId,
        title: summary.getNotificationTitle(isArabic),
        body: summary.getNotificationBody(isArabic),
        notificationDetails: details,
        payload: 'daily_summary',
      );
    } catch (e) {
      debugPrint('Error showing daily summary notification: $e');
    }
  }

  /// Schedule recurring daily summary notification at specific hour & minute
  Future<void> scheduleDailySummaryNotification({
    required TimeOfDay time,
    required DailyFinancialSummary summary,
    bool isArabic = true,
  }) async {
    await initialize();

    try {
      final details = _createNotificationDetails(summary, isArabic);

      // Cancel any existing scheduled reminder first
      await cancelDailySummaryNotification();

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // If scheduled time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notificationsPlugin.zonedSchedule(
        id: kDailySummaryNotificationId,
        title: summary.getNotificationTitle(isArabic),
        body: summary.getNotificationBody(isArabic),
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily_summary_scheduled',
      );
      debugPrint('Daily notification successfully scheduled for ${time.hour}:${time.minute}');
    } catch (e) {
      debugPrint('Error scheduling daily summary notification: $e');
    }
  }

  Future<void> cancelDailySummaryNotification() async {
    try {
      await _notificationsPlugin.cancel(id: kDailySummaryNotificationId);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }
}
