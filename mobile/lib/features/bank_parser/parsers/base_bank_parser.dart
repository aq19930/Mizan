import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../data/models/field_confidence.dart';
import '../data/models/parsed_bank_transaction.dart';
import '../utils/arabic_number_normalizer.dart';
import 'bank_parser_interface.dart';

abstract class BaseBankParser implements IBankMessageParser {
  @override
  String extractCurrency(String message) => 'SAR';

  @override
  String? extractCardSuffix(String message) {
    return ArabicNumberNormalizer.extractCardSuffix(message);
  }

  @override
  DateTime? extractDate(String message) {
    return ArabicNumberNormalizer.parseDate(message);
  }

  @override
  String? extractReference(String message) {
    final normalized = ArabicNumberNormalizer.normalizeDigits(message);
    final match = RegExp(
      r'(?:الرقم\s*المرجعي|رقم\s*المرجع|مرجع|المرجع|ref|reference)[\s:]*([a-zA-Z0-9_-]{4,})',
      caseSensitive: false,
    ).firstMatch(normalized);
    return match?.group(1);
  }

  @override
  double? extractReportedBalance(String message) {
    final normalized = ArabicNumberNormalizer.normalizeDigits(message);
    final match = RegExp(
      r'(?:الرصيد\s*(?:المتبقي|المتاح|الحالي|بعد\s*العملية)?|رصيد(?:ك)?\s*(?:المتبقي|المتاح|الحالي)?|avail(?:able)?\s*balance|balance)[\s:]*([0-9,.]+)',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (match != null) {
      return ArabicNumberNormalizer.parseAmount(match.group(1)!);
    }
    return null;
  }

  @override
  String inferCategory(String merchant, String transactionType) {
    final m = merchant.toLowerCase();

    // Food & Dining
    if (m.contains('hungerstation') ||
        m.contains('jahez') ||
        m.contains('albaik') ||
        m.contains('al baik') ||
        m.contains('mcdonald') ||
        m.contains('starbucks') ||
        m.contains('kfc') ||
        m.contains('مطعم') ||
        m.contains('مقهى') ||
        m.contains('كافيه')) {
      return 'Food & Dining';
    }

    // Groceries
    if (m.contains('panda') ||
        m.contains('danube') ||
        m.contains('tamimi') ||
        m.contains('lulu') ||
        m.contains('othaim') ||
        m.contains('بندة') ||
        m.contains('العثيم') ||
        m.contains('التميمي') ||
        m.contains('الدانو')) {
      return 'Groceries';
    }

    // Transportation
    if (m.contains('uber') ||
        m.contains('careem') ||
        m.contains('bolt') ||
        m.contains('petrol') ||
        m.contains('station') ||
        m.contains('محطة') ||
        m.contains('دريس') ||
        m.contains('أوبر')) {
      return 'Transportation';
    }

    // Telecommunications & Bills
    if (m.contains('stc') ||
        m.contains('mobily') ||
        m.contains('zain') ||
        m.contains('salam') ||
        m.contains('كهرباء') ||
        m.contains('مياه') ||
        m.contains('فاتورة') ||
        m.contains('sec')) {
      return 'Bills & Utilities';
    }

    // Shopping
    if (m.contains('amazon') ||
        m.contains('noon') ||
        m.contains('jarir') ||
        m.contains('extra') ||
        m.contains('جرير') ||
        m.contains('نون') ||
        m.contains('أمازون')) {
      return 'Shopping';
    }

    // Subscriptions
    if (m.contains('netflix') ||
        m.contains('spotify') ||
        m.contains('apple') ||
        m.contains('google') ||
        m.contains('shahid')) {
      return 'Subscriptions';
    }

    // Transfer / Income
    if (transactionType == 'SALARY') {
      return 'Salary';
    }
    if (transactionType == 'TRANSFER_IN' || transactionType == 'DEPOSIT' || transactionType == 'REFUND') {
      return 'Income';
    }

    return 'Other';
  }

  @override
  ParsedBankTransactionDto? parse(String message, {String? sender}) {
    if (!canParse(message, sender: sender)) return null;

    final amount = extractAmount(message);
    if (amount == null || amount <= 0) return null;

    final type = extractTransactionType(message);
    final merchant = extractMerchant(message);
    final date = extractDate(message) ?? DateTime.now();
    final card = extractCardSuffix(message);
    final balance = extractReportedBalance(message);
    final ref = extractReference(message);
    final category = inferCategory(merchant, type);

    // Calculate field confidence
    final amountConf = amount > 0 ? 0.99 : 0.0;
    final merchantConf = merchant.isNotEmpty && merchant != 'UNKNOWN_MERCHANT' ? 0.95 : 0.70;
    final dateConf = extractDate(message) != null ? 0.95 : 0.80;
    final typeConf = type != 'UNKNOWN' ? 0.98 : 0.75;
    final overall = (amountConf * 0.4) + (merchantConf * 0.3) + (typeConf * 0.2) + (dateConf * 0.1);

    final confidence = FieldConfidence(
      overall: double.parse(overall.toStringAsFixed(2)),
      amount: amountConf,
      merchant: merchantConf,
      date: dateConf,
      transactionType: typeConf,
    );

    final hash = sha256.convert(utf8.encode(message.trim())).toString();

    return ParsedBankTransactionDto(
      schemaVersion: '1.0',
      source: 'SMS',
      bank: bankIdentifier,
      transactionType: type,
      amount: amount,
      currency: extractCurrency(message),
      merchant: merchant,
      cardLast4: card,
      transactionDate: date,
      reportedBalance: balance,
      referenceNumber: ref,
      category: category,
      confidence: confidence,
      messageHash: hash,
      rawMessagePreserved: message,
    );
  }
}
