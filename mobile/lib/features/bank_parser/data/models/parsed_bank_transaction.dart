import 'field_confidence.dart';
import 'location_metadata.dart';
import 'transaction_direction.dart';

class ParsedBankTransactionDto {
  final String schemaVersion;
  final String source;
  final String bank;
  final String transactionType;
  final TransactionDirection direction;
  final double amount;
  final double fee;
  final double tax;
  final double cashback;
  final double totalDebit;
  final double totalCredit;
  final String currency;
  final String merchant;
  final String normalizedMerchant;
  final String? cardLast4;
  final String? sourceAccount;
  final String? destinationAccount;
  final String? destinationBank;
  final String? recipientName;
  final String? billerCode;
  final String? biller;
  final String? service;
  final String? billNumber;
  final String? paymentMethod;
  final bool salaryCandidate;
  final LocationMetadata? location;
  final DateTime transactionDate;
  final double? reportedBalance;
  final String? referenceNumber;
  final String category;
  final String? subcategory;
  final FieldConfidence confidence;
  final String messageHash;
  final String? rawMessagePreserved; // in-memory only for local UI review

  ParsedBankTransactionDto({
    this.schemaVersion = '1.0',
    this.source = 'SMS',
    required this.bank,
    required this.transactionType,
    TransactionDirection? direction,
    required this.amount,
    this.fee = 0.0,
    this.tax = 0.0,
    this.cashback = 0.0,
    double? totalDebit,
    double? totalCredit,
    this.currency = 'SAR',
    required this.merchant,
    String? normalizedMerchant,
    this.cardLast4,
    this.sourceAccount,
    this.destinationAccount,
    this.destinationBank,
    this.recipientName,
    this.billerCode,
    this.biller,
    this.service,
    this.billNumber,
    this.paymentMethod,
    this.salaryCandidate = false,
    this.location,
    required this.transactionDate,
    this.reportedBalance,
    this.referenceNumber,
    required this.category,
    this.subcategory,
    required this.confidence,
    required this.messageHash,
    this.rawMessagePreserved,
  })  : direction = direction ??
            (transactionType == 'SALARY' ||
                    transactionType == 'TRANSFER_IN' ||
                    transactionType == 'DEPOSIT' ||
                    transactionType == 'REFUND'
                ? TransactionDirection.inDir
                : TransactionDirection.outDir),
        totalDebit = totalDebit ??
            (direction == TransactionDirection.inDir
                ? 0.0
                : (transactionType == 'SALARY' ||
                        transactionType == 'TRANSFER_IN' ||
                        transactionType == 'DEPOSIT' ||
                        transactionType == 'REFUND'
                    ? 0.0
                    : amount + fee)),
        totalCredit = totalCredit ??
            (direction == TransactionDirection.outDir
                ? 0.0
                : (transactionType == 'SALARY' ||
                        transactionType == 'TRANSFER_IN' ||
                        transactionType == 'DEPOSIT' ||
                        transactionType == 'REFUND'
                    ? amount
                    : 0.0)),
        normalizedMerchant = normalizedMerchant ?? merchant.trim().toUpperCase();

  bool get isValid => amount > 0 && currency == 'SAR' && confidence.overall > 0;
  bool get isIncome => direction == TransactionDirection.inDir;
  bool get isExpense => direction == TransactionDirection.outDir;

  String? get accountSuffix {
    if (cardLast4 != null && cardLast4!.isNotEmpty) return cardLast4;
    if (sourceAccount != null && sourceAccount!.isNotEmpty) {
      final match = RegExp(r'\d{4}$').firstMatch(sourceAccount!);
      if (match != null) return match.group(0);
    }
    return null;
  }

  Map<String, dynamic> toJson({bool includeLocalRaw = false}) => {
        'schemaVersion': schemaVersion,
        'source': source,
        'bank': bank,
        'type': transactionType,
        'transactionType': transactionType,
        'direction': direction.code,
        'amount': amount,
        'fee': fee,
        'tax': tax,
        'cashback': cashback,
        'totalDebit': totalDebit,
        'totalCredit': totalCredit,
        'currency': currency,
        'merchant': merchant,
        'normalizedMerchant': normalizedMerchant,
        'cardLast4': cardLast4,
        'sourceAccount': sourceAccount,
        'destinationAccount': destinationAccount,
        'destinationBank': destinationBank,
        'recipientName': recipientName,
        'billerCode': billerCode,
        'billerName': biller,
        'serviceType': service,
        'billNumber': billNumber,
        'paymentMethod': paymentMethod,
        'salaryCandidate': salaryCandidate,
        'location': location?.toJson(),
        'transactionDate': transactionDate.toIso8601String(),
        'reportedBalance': reportedBalance,
        'referenceNumber': referenceNumber,
        'category': category,
        'subcategory': subcategory,
        'confidence': confidence.overall,
        'confidenceDetails': confidence.toJson(),
        'messageHash': messageHash,
        if (includeLocalRaw && rawMessagePreserved != null)
          'rawMessage': rawMessagePreserved,
      };

  Map<String, dynamic> toStructuredJson() => {
        'schemaVersion': schemaVersion,
        'messageType': 'FINANCIAL_TRANSACTION',
        'transaction': {
          'type': transactionType,
          'direction': direction.code,
          'amount': amount,
          'fee': fee,
          'totalDebit': totalDebit,
          'totalCredit': totalCredit,
          'currency': currency,
          'merchant': merchant,
          'category': category,
          if (subcategory != null) 'subcategory': subcategory,
        },
        'accounts': {
          'source': sourceAccount ?? (cardLast4 != null ? '****$cardLast4' : null),
          'destination': destinationAccount,
        },
        'bankMetadata': {
          if (billerCode != null) 'billerCode': billerCode,
          if (biller != null) 'biller': biller,
          if (service != null) 'service': service,
          if (billNumber != null) 'billNumber': billNumber,
          if (recipientName != null) 'recipientName': recipientName,
          if (destinationBank != null) 'destinationBank': destinationBank,
          if (paymentMethod != null) 'paymentMethod': paymentMethod,
          'referenceNumber': referenceNumber,
        },
        'location': location?.toJson(),
        'confidence': confidence.toJson(),
        'salaryCandidate': salaryCandidate,
      };

  factory ParsedBankTransactionDto.fromJson(Map<String, dynamic> json) => ParsedBankTransactionDto(
        schemaVersion: json['schemaVersion'] as String? ?? '1.0',
        source: json['source'] as String? ?? 'SMS',
        bank: json['bank'] as String? ?? 'UNKNOWN',
        transactionType: json['transactionType'] as String? ?? json['type'] as String? ?? 'PURCHASE',
        direction: TransactionDirection.fromCode(json['direction'] as String?),
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        fee: (json['fee'] as num?)?.toDouble() ?? 0.0,
        tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
        cashback: (json['cashback'] as num?)?.toDouble() ?? 0.0,
        totalDebit: (json['totalDebit'] as num?)?.toDouble(),
        totalCredit: (json['totalCredit'] as num?)?.toDouble(),
        currency: json['currency'] as String? ?? 'SAR',
        merchant: json['merchant'] as String? ?? '',
        normalizedMerchant: json['normalizedMerchant'] as String?,
        cardLast4: json['cardLast4'] as String?,
        sourceAccount: json['sourceAccount'] as String?,
        destinationAccount: json['destinationAccount'] as String?,
        destinationBank: json['destinationBank'] as String?,
        recipientName: json['recipientName'] as String?,
        billerCode: json['billerCode'] as String?,
        biller: json['biller'] as String? ?? json['billerName'] as String?,
        service: json['service'] as String? ?? json['serviceType'] as String?,
        billNumber: json['billNumber'] as String?,
        paymentMethod: json['paymentMethod'] as String?,
        salaryCandidate: json['salaryCandidate'] as bool? ?? false,
        location: json['location'] != null ? LocationMetadata.fromJson(json['location'] as Map<String, dynamic>) : null,
        transactionDate: DateTime.tryParse(json['transactionDate'] as String? ?? '') ?? DateTime.now(),
        reportedBalance: (json['reportedBalance'] as num?)?.toDouble(),
        referenceNumber: json['referenceNumber'] as String?,
        category: json['category'] as String? ?? 'Other',
        subcategory: json['subcategory'] as String?,
        confidence: FieldConfidence.fromJson(json['confidenceDetails'] as Map<String, dynamic>? ?? json['confidence'] as Map<String, dynamic>? ?? {}),
        messageHash: json['messageHash'] as String? ?? '',
        rawMessagePreserved: json['rawMessage'] as String?,
      );
}