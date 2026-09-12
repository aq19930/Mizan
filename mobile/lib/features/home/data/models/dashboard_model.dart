import 'package:mobile/features/transactions/data/models/transaction_model.dart';

class CategorySpendingModel {
  final String? categoryId;
  final String categoryNameAr;
  final String categoryNameEn;
  final String icon;
  final String colorHex;
  final double spentAmount;
  final double percentage;

  CategorySpendingModel({
    this.categoryId,
    required this.categoryNameAr,
    required this.categoryNameEn,
    required this.icon,
    required this.colorHex,
    required this.spentAmount,
    required this.percentage,
  });

  factory CategorySpendingModel.fromJson(Map<String, dynamic> json) {
    return CategorySpendingModel(
      categoryId: json['categoryId'],
      categoryNameAr: json['categoryNameAr'] ?? 'أخرى',
      categoryNameEn: json['categoryNameEn'] ?? 'Other',
      icon: json['icon'] ?? 'more_horiz',
      colorHex: json['colorHex'] ?? '#6B7280',
      spentAmount: (json['spentAmount'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class UpcomingCommitmentSummary {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime dueDate;
  final int daysUntilDue;
  final bool isPaid;

  UpcomingCommitmentSummary({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.dueDate,
    required this.daysUntilDue,
    this.isPaid = false,
  });

  factory UpcomingCommitmentSummary.fromJson(Map<String, dynamic> json) {
    return UpcomingCommitmentSummary(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? 'Other',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: DateTime.tryParse(json['dueDate']?.toString() ?? '') ?? DateTime.now(),
      daysUntilDue: (json['daysUntilDue'] as num?)?.toInt() ?? 0,
      isPaid: json['isPaid'] as bool? ?? false,
    );
  }
}

class DashboardModel {
  final double currentBalance;
  final double committedAmount;
  final double availableToSpend;
  final double spentToday;
  final double dailyLimit;
  final double expectedTomorrow;
  final String budgetHealth;
  final List<TransactionModel> recentTransactions;
  final List<CategorySpendingModel> spendingByCategory;
  final List<UpcomingCommitmentSummary> upcomingCommitments;
  final String aiInsightAr;
  final String aiInsightEn;

  DashboardModel({
    required this.currentBalance,
    this.committedAmount = 1592.0,
    double? availableToSpend,
    required this.spentToday,
    required this.dailyLimit,
    required this.expectedTomorrow,
    required this.budgetHealth,
    required this.recentTransactions,
    required this.spendingByCategory,
    this.upcomingCommitments = const [],
    required this.aiInsightAr,
    required this.aiInsightEn,
  }) : availableToSpend = availableToSpend ?? (currentBalance - 1592.0 > 0 ? currentBalance - 1592.0 : 0.0);

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final rawRecent = json['recentTransactions'] as List? ?? [];
    final rawCategories = json['spendingByCategory'] as List? ?? [];
    final rawUpcoming = json['upcomingCommitments'] as List? ?? [];

    final balance = (json['currentBalance'] as num?)?.toDouble() ?? 0.0;
    final committed = (json['committedAmount'] as num?)?.toDouble() ?? 1592.0;
    final available = (json['availableToSpend'] as num?)?.toDouble() ?? (balance - committed > 0 ? balance - committed : 0.0);

    return DashboardModel(
      currentBalance: balance,
      committedAmount: committed,
      availableToSpend: available,
      spentToday: (json['spentToday'] as num?)?.toDouble() ?? 0.0,
      dailyLimit: (json['dailyLimit'] as num?)?.toDouble() ?? 0.0,
      expectedTomorrow: (json['expectedTomorrow'] as num?)?.toDouble() ?? 0.0,
      budgetHealth: json['budgetHealth'] ?? 'Safe',
      recentTransactions: rawRecent.map((e) => TransactionModel.fromJson(e)).toList(),
      spendingByCategory: rawCategories.map((e) => CategorySpendingModel.fromJson(e)).toList(),
      upcomingCommitments: rawUpcoming.map((e) => UpcomingCommitmentSummary.fromJson(e)).toList(),
      aiInsightAr: json['aiInsightAr'] ?? 'كل شيء تحت السيطرة!',
      aiInsightEn: json['aiInsightEn'] ?? 'Everything is on track!',
    );
  }
}
