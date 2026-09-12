class BudgetModel {
  final String id;
  final String? categoryId;
  final String categoryNameAr;
  final String categoryNameEn;
  final String categoryIcon;
  final double amount;
  final double spent;
  final double remaining;
  final double percentage;
  final String status;

  BudgetModel({
    required this.id,
    this.categoryId,
    required this.categoryNameAr,
    required this.categoryNameEn,
    required this.categoryIcon,
    required this.amount,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.status,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] ?? '',
      categoryId: json['categoryId'],
      categoryNameAr: json['categoryNameAr'] ?? '???',
      categoryNameEn: json['categoryNameEn'] ?? 'General',
      categoryIcon: json['categoryIcon'] ?? 'restaurant',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      spent: (json['spent'] as num?)?.toDouble() ?? 0.0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Safe',
    );
  }
}
