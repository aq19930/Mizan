class TransactionModel {
  final String id;
  final String walletId;
  final int transactionType; // 0 = Expense, 1 = Income, 2 = Transfer
  final double amount;
  final String currency;
  final String merchant;
  final String? categoryId;
  final String? categoryNameAr;
  final String? categoryNameEn;
  final String? categoryIcon;
  final String? categoryColorHex;
  final DateTime transactionDate;
  final int source; // 0 = Manual, 1 = SMS Auto
  final double confidence;
  final bool isVerified;
  final String? notes;
  final String? referenceNumber;

  TransactionModel({
    required this.id,
    required this.walletId,
    required this.transactionType,
    required this.amount,
    this.currency = 'SAR',
    required this.merchant,
    this.categoryId,
    this.categoryNameAr,
    this.categoryNameEn,
    this.categoryIcon,
    this.categoryColorHex,
    required this.transactionDate,
    this.source = 0,
    this.confidence = 1.0,
    this.isVerified = true,
    this.notes,
    this.referenceNumber,
  });

  bool get isIncome =>
      transactionType == 1 ||
      transactionType == 4 ||
      transactionType == 6 ||
      transactionType == 8;

  bool get isExpense => !isIncome;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      walletId: json['walletId'] ?? '',
      transactionType: json['transactionType'] ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'SAR',
      merchant: json['merchant'] ?? '',
      categoryId: json['categoryId'],
      categoryNameAr: json['categoryNameAr'],
      categoryNameEn: json['categoryNameEn'],
      categoryIcon: json['categoryIcon'],
      categoryColorHex: json['categoryColorHex'],
      transactionDate: json['transactionDate'] != null
          ? DateTime.parse(json['transactionDate'])
          : DateTime.now(),
      source: json['source'] ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      isVerified: json['isVerified'] ?? true,
      notes: json['notes'],
      referenceNumber: json['referenceNumber'],
    );
  }
}
