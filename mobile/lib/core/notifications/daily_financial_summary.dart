import 'package:flutter/material.dart';

class DailyFinancialSummary {
  final double spentToday;
  final double remainingBudget;
  final double recommendedTomorrow;
  final double totalMonthlyBudget;
  final int daysRemainingInMonth;
  final DateTime timestamp;

  const DailyFinancialSummary({
    required this.spentToday,
    required this.remainingBudget,
    required this.recommendedTomorrow,
    this.totalMonthlyBudget = 5000.0,
    this.daysRemainingInMonth = 19,
    required this.timestamp,
  });

  String getNotificationTitle(bool isArabic) {
    return isArabic ? '🌙 ملخص ميزان المالي اليومي' : '🌙 Mizan Daily Financial Summary';
  }

  String getNotificationBody(bool isArabic) {
    if (isArabic) {
      return 'صرفت اليوم: ${spentToday.toStringAsFixed(2)} ر.س | المتبقي: ${remainingBudget.toStringAsFixed(0)} ر.س | الموصى به لغداً: ${recommendedTomorrow.toStringAsFixed(0)} ر.س';
    } else {
      return 'Spent today: ${spentToday.toStringAsFixed(2)} SAR | Left: ${remainingBudget.toStringAsFixed(0)} SAR | Tomorrow limit: ${recommendedTomorrow.toStringAsFixed(0)} SAR';
    }
  }

  String getFormattedLine(String label, double amount, String currency, {Color? color}) {
    return '$label: ${amount.toStringAsFixed(2)} $currency';
  }
}
