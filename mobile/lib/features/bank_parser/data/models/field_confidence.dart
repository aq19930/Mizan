class FieldConfidence {
  final double overall;
  final double amount;
  final double merchant;
  final double date;
  final double transactionType;

  const FieldConfidence({
    required this.overall,
    required this.amount,
    required this.merchant,
    required this.date,
    required this.transactionType,
  });

  bool get isHigh => overall >= 0.90;
  bool get isMedium => overall >= 0.70 && overall < 0.90;
  bool get isLow => overall < 0.70;

  Map<String, dynamic> toJson() => {
        'overall': double.parse(overall.toStringAsFixed(2)),
        'amount': double.parse(amount.toStringAsFixed(2)),
        'merchant': double.parse(merchant.toStringAsFixed(2)),
        'date': double.parse(date.toStringAsFixed(2)),
        'transactionType': double.parse(transactionType.toStringAsFixed(2)),
      };

  factory FieldConfidence.fromJson(Map<String, dynamic> json) => FieldConfidence(
        overall: (json['overall'] as num?)?.toDouble() ?? 0.0,
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        merchant: (json['merchant'] as num?)?.toDouble() ?? 0.0,
        date: (json['date'] as num?)?.toDouble() ?? 0.0,
        transactionType: (json['transactionType'] as num?)?.toDouble() ?? 0.0,
      );
}
