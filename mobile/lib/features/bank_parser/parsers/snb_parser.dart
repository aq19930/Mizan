import '../utils/arabic_number_normalizer.dart';
import 'base_bank_parser.dart';

class SnbParser extends BaseBankParser {
  @override
  String get bankIdentifier => 'SNB';

  @override
  String get bankDisplayNameAr => 'البنك الأهلي السعودي';

  @override
  String get bankDisplayNameEn => 'Saudi National Bank (SNB)';

  @override
  bool canParse(String message, {String? sender}) {
    final s = (sender ?? '').toLowerCase();
    final m = message.toLowerCase();
    return s.contains('snb') ||
        s.contains('alahli') ||
        m.contains('الأهلي') ||
        m.contains('الاهلي') ||
        m.contains('snb');
  }

  @override
  String detectBank(String message, {String? sender}) => bankIdentifier;

  @override
  String extractTransactionType(String message) {
    final m = message.toLowerCase();
    if (m.contains('نقاط بيع') || m.contains('pos')) return 'POS_PURCHASE';
    if (m.contains('إنترنت') || m.contains('online') || m.contains('إلكتروني')) return 'ONLINE_PURCHASE';
    if (m.contains('سحب نقدي') || m.contains('atm')) return 'ATM_WITHDRAWAL';
    if (m.contains('حوالة صادرة') || m.contains('تحويل')) return 'TRANSFER_OUT';
    if (m.contains('حوالة واردة') || m.contains('إيداع')) return 'TRANSFER_IN';
    if (m.contains('سداد')) return 'BILL_PAYMENT';
    if (m.contains('شراء') || m.contains('purchase')) return 'PURCHASE';
    return 'PURCHASE';
  }

  @override
  double? extractAmount(String message) {
    final normalized = ArabicNumberNormalizer.normalizeDigits(message);
    final match = RegExp(
      r'(?:بمبلغ|مبلغ|بقيمة|amount|SAR)[\s:]*([0-9,.]+)',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (match != null) {
      return ArabicNumberNormalizer.parseAmount(match.group(1)!);
    }
    return ArabicNumberNormalizer.parseAmount(message);
  }

  @override
  String extractMerchant(String message) {
    final matchAr = RegExp(r'لدى\s+([^في\n\r,.]+)', caseSensitive: false).firstMatch(message);
    if (matchAr != null) return matchAr.group(1)!.trim();

    final matchEn = RegExp(r'at\s+([a-zA-Z0-9\s&_-]+?)(?:\s+(?:on|via)|\.|$)', caseSensitive: false)
        .firstMatch(message);
    if (matchEn != null) return matchEn.group(1)!.trim();

    return 'UNKNOWN_MERCHANT';
  }
}
