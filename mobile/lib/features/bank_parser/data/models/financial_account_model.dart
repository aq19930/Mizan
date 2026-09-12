class FinancialAccountModel {
  final String id;
  final String userId;
  final String bankName;
  final String displayName;
  final String maskedAccountNumber;
  final String accountSuffix;
  final String currency;
  final bool isPrimary;
  final DateTime createdAt;

  FinancialAccountModel({
    required this.id,
    required this.userId,
    required this.bankName,
    required this.displayName,
    required this.maskedAccountNumber,
    required this.accountSuffix,
    this.currency = 'SAR',
    this.isPrimary = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'bankName': bankName,
        'displayName': displayName,
        'maskedAccountNumber': maskedAccountNumber,
        'accountSuffix': accountSuffix,
        'currency': currency,
        'isPrimary': isPrimary,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FinancialAccountModel.fromJson(Map<String, dynamic> json) => FinancialAccountModel(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        bankName: json['bankName'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        maskedAccountNumber: json['maskedAccountNumber'] as String? ?? '',
        accountSuffix: json['accountSuffix'] as String? ?? '',
        currency: json['currency'] as String? ?? 'SAR',
        isPrimary: json['isPrimary'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}