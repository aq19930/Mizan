import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../data/models/field_confidence.dart';
import '../data/models/parsed_bank_transaction.dart';
import '../data/models/transaction_direction.dart';
import '../extractors/account_extractor.dart';
import '../extractors/amount_extractor.dart';
import '../extractors/biller_extractor.dart';
import '../extractors/fee_extractor.dart';
import '../extractors/merchant_extractor.dart';
import '../extractors/recipient_extractor.dart';
import '../extractors/salary_candidate_detector.dart';
import '../extractors/traffic_fine_detector.dart';
import '../extractors/transaction_type_detector.dart';
import '../utils/arabic_number_normalizer.dart';
import 'bank_parser_interface.dart';

class SaudiBankMessageParser implements IBankMessageParser {
  @override
  String get bankIdentifier => 'SAUDI_MODULAR';

  @override
  String get bankDisplayNameAr => 'محرك الرسائل البنكية السعودية المتقدم';

  @override
  String get bankDisplayNameEn => 'Advanced Saudi Bank Engine';

  @override
  bool canParse(String message, {String? sender}) => true; // Modular fallback handles all

  @override
  String detectBank(String message, {String? sender}) {
    final s = (sender ?? '').toLowerCase();
    final m = message.toLowerCase();

    if (s.contains('rajhi') || m.contains('الراجحي') || m.contains('rjhi')) return 'Al Rajhi Bank';
    if (s.contains('snb') || s.contains('alahli') || m.contains('الأهلي')) return 'SNB';
    if (s.contains('riyad') || m.contains('الرياض')) return 'Riyad Bank';
    if (s.contains('inma') || m.contains('الإنماء')) return 'Alinma Bank';
    if (s.contains('sab') || m.contains('الأول')) return 'SAB';
    if (s.contains('saib') || m.contains('الاستثمار')) return 'SAIB';
    if (s.contains('stc') || m.contains('stc bank') || m.contains('stcpay')) return 'STC Bank';
    return 'Saudi Bank';
  }

  @override
  String extractCurrency(String message) => 'SAR';

  @override
  String? extractCardSuffix(String message) {
    final acc = AccountExtractor.extract(message);
    return acc.cardLast4 ?? AccountExtractor.normalizeSuffix(acc.sourceAccount);
  }

  @override
  double? extractAmount(String message) => AmountExtractor.extract(message);

  @override
  String extractMerchant(String message) => MerchantExtractor.extract(message).rawMerchant;

  @override
  String extractTransactionType(String message) => TransactionTypeDetector.detect(message);

  @override
  DateTime? extractDate(String message) {
    final parsed = ArabicNumberNormalizer.parseDate(message);
    if (parsed != null) return parsed;

    // Pattern: "في: 08-25 09:22" or "في 09-08 21:20"
    final match = RegExp(r'(?:في|بتاريخ|on)[\s:]*(\d{1,2})[-/](\d{1,2})(?:[\s]+(\d{1,2}):(\d{2}))?')
        .firstMatch(ArabicNumberNormalizer.normalizeDigits(message));
    if (match != null) {
      final now = DateTime.now();
      final m = int.parse(match.group(1)!);
      final d = int.parse(match.group(2)!);
      final h = match.group(3) != null ? int.parse(match.group(3)!) : 12;
      final min = match.group(4) != null ? int.parse(match.group(4)!) : 0;
      return DateTime(now.year, m, d, h, min);
    }
    return DateTime.now();
  }

  @override
  double? extractReportedBalance(String message) {
    final match = RegExp(
      r'(?:الرصيد|رصيدك|balance)[\s:]*(?:SAR|ر\.س)?[\s:]*([0-9,.]+)',
      caseSensitive: false,
    ).firstMatch(ArabicNumberNormalizer.normalizeDigits(message));
    if (match != null) {
      return ArabicNumberNormalizer.parseAmount(match.group(1)!);
    }
    return null;
  }

  @override
  String? extractReference(String message) {
    // 1. Check traffic fine reference
    final traffic = TrafficFineDetector.detect(message);
    if (traffic.violationReference != null) return traffic.violationReference;

    // 2. Check general reference number
    final match = RegExp(
      r'(?:الرقم\s*المرجعي|رقم\s*المرجع|مرجع|المرجع|ref|reference)[\s:]*([a-zA-Z0-9_-]{4,})',
      caseSensitive: false,
    ).firstMatch(ArabicNumberNormalizer.normalizeDigits(message));
    return match?.group(1);
  }

  @override
  String inferCategory(String merchant, String transactionType) {
    if (transactionType == 'TRAFFIC_FINE' || transactionType == 'GOVERNMENT_PAYMENT') {
      return 'Government';
    }
    if (transactionType == 'BILL_PAYMENT') {
      return 'Bills';
    }
    if (transactionType == 'LOCAL_TRANSFER' || transactionType == 'TRANSFER_OUT') {
      return 'Transfers';
    }
    if (transactionType == 'SALARY') {
      return 'Salary';
    }
    if (transactionType == 'TRANSFER_IN' || transactionType == 'DEPOSIT' || transactionType == 'REFUND') {
      return 'Income';
    }
    if (transactionType == 'ATM_WITHDRAWAL') {
      return 'Cash & ATM';
    }
    return 'Shopping';
  }

  @override
  ParsedBankTransactionDto? parse(String message, {String? sender}) {
    final amount = extractAmount(message);
    if (amount == null || amount <= 0) return null;

    final fee = FeeExtractor.extract(message);
    final bank = detectBank(message, sender: sender);
    final txType = extractTransactionType(message);
    final accounts = AccountExtractor.extract(message);
    final merchantRes = MerchantExtractor.extract(message);
    final recipientRes = RecipientExtractor.extract(message);
    final billerRes = BillerExtractor.extract(message);
    final date = extractDate(message) ?? DateTime.now();
    final balance = extractReportedBalance(message);
    final ref = extractReference(message);

    final isIncoming = txType == 'SALARY' || txType == 'TRANSFER_IN' || txType == 'DEPOSIT' || txType == 'REFUND';
    final direction = isIncoming ? TransactionDirection.inDir : TransactionDirection.outDir;

    // Evaluate salary candidate
    final salaryRes = SalaryCandidateDetector.detect(message, amount, isIncoming);

    // Categories & subcategories
    String category = inferCategory(merchantRes.rawMerchant, txType);
    String? subcategory;

    if (txType == 'BILL_PAYMENT') {
      category = 'Bills';
      subcategory = billerRes.service ?? 'Telecommunications';
    } else if (txType == 'TRAFFIC_FINE') {
      category = 'Government';
      subcategory = 'Traffic Fine';
    } else if (txType == 'LOCAL_TRANSFER') {
      category = 'Transfers';
      subcategory = 'Local Transfer';
    }

    // Determine final merchant display
    String displayMerchant = merchantRes.rawMerchant;
    if (txType == 'BILL_PAYMENT') {
      displayMerchant = billerRes.biller ?? 'فاتورة سداد';
    } else if (txType == 'LOCAL_TRANSFER') {
      displayMerchant = recipientRes.recipientName != null ? 'تحويل إلى ${recipientRes.recipientName}' : 'تحويل محلي';
    } else if (txType == 'TRAFFIC_FINE') {
      displayMerchant = 'مخالفة مرورية';
    } else if (txType == 'SALARY') {
      displayMerchant = 'راتب شهري';
    } else if (txType == 'TRANSFER_IN') {
      displayMerchant = 'حوالة واردة';
    }

    // Confidence
    final confidence = FieldConfidence(
      overall: 0.98,
      amount: 0.99,
      merchant: 0.98,
      date: 0.95,
      transactionType: 0.99,
    );

    // Idempotency message hash (deterministic across calls for identical SMS)
    final hashSource = '${accounts.sourceAccount}_${txType}_${amount}_${fee}_${displayMerchant}_${ref}_${ArabicNumberNormalizer.normalizeDigits(message).trim()}';
    final hash = sha256.convert(utf8.encode(hashSource)).toString();

    return ParsedBankTransactionDto(
      schemaVersion: '1.0',
      source: 'SMS',
      bank: bank,
      transactionType: txType,
      direction: direction,
      amount: amount,
      fee: fee,
      totalDebit: isIncoming ? 0.0 : (amount + fee),
      totalCredit: isIncoming ? amount : 0.0,
      currency: 'SAR',
      merchant: displayMerchant,
      normalizedMerchant: merchantRes.normalizedMerchant,
      cardLast4: accounts.cardLast4,
      sourceAccount: accounts.sourceAccount,
      destinationAccount: accounts.destinationAccount,
      destinationBank: recipientRes.destinationBank,
      recipientName: recipientRes.recipientName,
      billerCode: billerRes.billerCode,
      biller: billerRes.biller,
      service: billerRes.service,
      billNumber: billerRes.billNumber,
      paymentMethod: merchantRes.paymentMethod,
      salaryCandidate: salaryRes.isCandidate,
      transactionDate: date,
      reportedBalance: balance,
      referenceNumber: ref,
      category: category,
      subcategory: subcategory,
      confidence: confidence,
      messageHash: hash,
      rawMessagePreserved: message,
    );
  }
}