import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'daily_financial_summary.dart';
import 'notification_service.dart';

class NotificationSettingsState {
  final bool isDailyEnabled;
  final TimeOfDay summaryTime;
  final DailyFinancialSummary currentSummary;
  final bool isSendingTest;
  final String? lastSentMessage;

  const NotificationSettingsState({
    required this.isDailyEnabled,
    required this.summaryTime,
    required this.currentSummary,
    this.isSendingTest = false,
    this.lastSentMessage,
  });

  NotificationSettingsState copyWith({
    bool? isDailyEnabled,
    TimeOfDay? summaryTime,
    DailyFinancialSummary? currentSummary,
    bool? isSendingTest,
    String? lastSentMessage,
  }) {
    return NotificationSettingsState(
      isDailyEnabled: isDailyEnabled ?? this.isDailyEnabled,
      summaryTime: summaryTime ?? this.summaryTime,
      currentSummary: currentSummary ?? this.currentSummary,
      isSendingTest: isSendingTest ?? this.isSendingTest,
      lastSentMessage: lastSentMessage ?? this.lastSentMessage,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationSettingsState> {
  final NotificationService _service;

  NotificationNotifier(this._service)
      : super(
          NotificationSettingsState(
            isDailyEnabled: true,
            summaryTime: const TimeOfDay(hour: 21, minute: 0),
            currentSummary: DailyFinancialSummary(
              spentToday: 137.50,
              remainingBudget: 3750.0,
              recommendedTomorrow: 140.0,
              totalMonthlyBudget: 5000.0,
              daysRemainingInMonth: 19,
              timestamp: DateTime.now(),
            ),
          ),
        ) {
    _loadSettings();
  }

  static const String _kEnabledKey = 'mizan_pref_daily_notif_enabled';
  static const String _kHourKey = 'mizan_pref_daily_notif_hour';
  static const String _kMinuteKey = 'mizan_pref_daily_notif_minute';

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_kEnabledKey) ?? true;
      final hour = prefs.getInt(_kHourKey) ?? 21;
      final minute = prefs.getInt(_kMinuteKey) ?? 0;

      final time = TimeOfDay(hour: hour, minute: minute);
      state = state.copyWith(
        isDailyEnabled: enabled,
        summaryTime: time,
      );

      if (enabled) {
        await _service.scheduleDailySummaryNotification(
          time: time,
          summary: state.currentSummary,
        );
      }
    } catch (_) {}
  }

  void updateFinancials({
    required double spentToday,
    required double remainingBudget,
    required double recommendedTomorrow,
    double totalMonthlyBudget = 5000.0,
    int daysRemainingInMonth = 19,
  }) {
    final updatedSummary = DailyFinancialSummary(
      spentToday: spentToday,
      remainingBudget: remainingBudget,
      recommendedTomorrow: recommendedTomorrow,
      totalMonthlyBudget: totalMonthlyBudget,
      daysRemainingInMonth: daysRemainingInMonth,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(currentSummary: updatedSummary);

    if (state.isDailyEnabled) {
      _service.scheduleDailySummaryNotification(
        time: state.summaryTime,
        summary: updatedSummary,
      );
    }
  }

  Future<void> toggleDailyEnabled(bool enabled) async {
    state = state.copyWith(isDailyEnabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kEnabledKey, enabled);

      if (enabled) {
        await _service.requestPermissions();
        await _service.scheduleDailySummaryNotification(
          time: state.summaryTime,
          summary: state.currentSummary,
        );
      } else {
        await _service.cancelDailySummaryNotification();
      }
    } catch (_) {}
  }

  Future<void> setSummaryTime(TimeOfDay time) async {
    state = state.copyWith(summaryTime: time);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kHourKey, time.hour);
      await prefs.setInt(_kMinuteKey, time.minute);

      if (state.isDailyEnabled) {
        await _service.scheduleDailySummaryNotification(
          time: time,
          summary: state.currentSummary,
        );
      }
    } catch (_) {}
  }

  Future<bool> sendTestNotification({bool isArabic = true}) async {
    state = state.copyWith(isSendingTest: true);

    try {
      await _service.requestPermissions();
      await _service.showDailySummaryNotification(
        state.currentSummary,
        isArabic: isArabic,
      );

      final message = state.currentSummary.getNotificationBody(isArabic);
      state = state.copyWith(
        isSendingTest: false,
        lastSentMessage: message,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSendingTest: false);
      return false;
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationSettingsProvider =
    StateNotifierProvider<NotificationNotifier, NotificationSettingsState>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return NotificationNotifier(service);
});
