class CommitmentOccurrenceModel {
  final String id;
  final String commitmentId;
  final DateTime expectedDate;
  final double expectedAmount;
  final String? actualTransactionId;
  final String status;
  final DateTime? paidAt;
  final double? actualAmount;

  CommitmentOccurrenceModel({
    required this.id,
    required this.commitmentId,
    required this.expectedDate,
    required this.expectedAmount,
    this.actualTransactionId,
    required this.status,
    this.paidAt,
    this.actualAmount,
  });

  factory CommitmentOccurrenceModel.fromJson(Map<String, dynamic> json) => CommitmentOccurrenceModel(
        id: json['id'] as String? ?? '',
        commitmentId: json['commitmentId'] as String? ?? '',
        expectedDate: DateTime.parse(json['expectedDate'] as String),
        expectedAmount: (json['expectedAmount'] as num?)?.toDouble() ?? 0.0,
        actualTransactionId: json['actualTransactionId'] as String?,
        status: json['status'] as String? ?? 'Pending',
        paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt'] as String) : null,
        actualAmount: (json['actualAmount'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'commitmentId': commitmentId,
        'expectedDate': expectedDate.toIso8601String(),
        'expectedAmount': expectedAmount,
        'actualTransactionId': actualTransactionId,
        'status': status,
        'paidAt': paidAt?.toIso8601String(),
        'actualAmount': actualAmount,
      };
}

class CommitmentModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String category;
  final String categoryNameAr;
  final String categoryNameEn;
  final double amount;
  final String currency;
  final String frequency;
  final DateTime startDate;
  final DateTime dueDate;
  final DateTime nextDueDate;
  final DateTime? endDate;
  final bool isRecurring;
  final bool autoRenew;
  final String priority;
  final String? paymentMethod;
  final String? merchant;
  final String? reference;
  final String status;
  final int reminderDaysBefore;
  final bool isPaid;
  final DateTime createdAt;
  final List<CommitmentOccurrenceModel> occurrences;

  CommitmentModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    required this.categoryNameAr,
    required this.categoryNameEn,
    required this.amount,
    this.currency = 'SAR',
    required this.frequency,
    required this.startDate,
    required this.dueDate,
    required this.nextDueDate,
    this.endDate,
    this.isRecurring = true,
    this.autoRenew = true,
    this.priority = 'Medium',
    this.paymentMethod,
    this.merchant,
    this.reference,
    this.status = 'Active',
    this.reminderDaysBefore = 3,
    this.isPaid = false,
    required this.createdAt,
    this.occurrences = const [],
  });

  int get daysUntilDue => nextDueDate.difference(DateTime.now()).inDays;
  bool get isOverdue => !isPaid && nextDueDate.isBefore(DateTime.now());
  bool get isDueSoon => !isPaid && daysUntilDue >= 0 && daysUntilDue <= 7;

  factory CommitmentModel.fromJson(Map<String, dynamic> json) {
    var rawOccurrences = json['occurrences'] as List? ?? [];
    return CommitmentModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'Other',
      categoryNameAr: json['categoryNameAr'] as String? ?? 'أخرى',
      categoryNameEn: json['categoryNameEn'] as String? ?? 'Other',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'SAR',
      frequency: json['frequency'] as String? ?? 'Monthly',
      startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ?? DateTime.now(),
      dueDate: DateTime.tryParse(json['dueDate'] as String? ?? '') ?? DateTime.now(),
      nextDueDate: DateTime.tryParse(json['nextDueDate'] as String? ?? '') ?? DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'] as String) : null,
      isRecurring: json['isRecurring'] as bool? ?? true,
      autoRenew: json['autoRenew'] as bool? ?? true,
      priority: json['priority'] as String? ?? 'Medium',
      paymentMethod: json['paymentMethod'] as String?,
      merchant: json['merchant'] as String?,
      reference: json['reference'] as String?,
      status: json['status'] as String? ?? 'Active',
      reminderDaysBefore: json['reminderDaysBefore'] as int? ?? 3,
      isPaid: json['isPaid'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      occurrences: rawOccurrences.map((e) => CommitmentOccurrenceModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'description': description,
        'category': category,
        'categoryNameAr': categoryNameAr,
        'categoryNameEn': categoryNameEn,
        'amount': amount,
        'currency': currency,
        'frequency': frequency,
        'startDate': startDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'nextDueDate': nextDueDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'isRecurring': isRecurring,
        'autoRenew': autoRenew,
        'priority': priority,
        'paymentMethod': paymentMethod,
        'merchant': merchant,
        'reference': reference,
        'status': status,
        'reminderDaysBefore': reminderDaysBefore,
        'isPaid': isPaid,
        'createdAt': createdAt.toIso8601String(),
        'occurrences': occurrences.map((e) => e.toJson()).toList(),
      };
}
