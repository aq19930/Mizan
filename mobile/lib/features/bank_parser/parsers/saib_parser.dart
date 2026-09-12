import '../utils/arabic_number_normalizer.dart';
import 'base_bank_parser.dart';

class SaibParser extends BaseBankParser {
  @override
  String get bankIdentifier => 'SAIB';

  @override
  String get bankDisplayNameAr => 'البنك السعودي للاستثمار';

  @override
  String get bankDisplayNameEn => 'Saudi Investment Bank (SAIB)';

  @override
  bool canParse(String message, {String? sender}) {
    final s = (sender ?? '').toLowerCase();
    final m = message.toLowerCase();
    return s.contains('saib') ||
        s.contains('saibank') ||
        m.contains('الاستثمار') ||
        m.contains('السعودي للاستثمار') ||
        m.contains('saib') ||
        (m.contains('حوالة واردة: راتب')) ||
        (m.contains('مبلغ:') && (m.contains('xxx') || m.contains('الى: xxx') || m.contains('من: xxx')));
  }

  @override
  String detectBank(String message, {String? sender}) => bankIdentifier;

  @override
  String extractTransactionType(String message) {
    final m = message.toLowerCase();
    if (m.contains('راتب') || m.contains('salary')) return 'SALARY';
    if (m.contains('نقاط بيع') || m.contains('pos')) return 'POS_PURCHASE';
    if (m.contains('إنترنت') || m.contains('online') || m.contains('إلكتروني')) return 'ONLINE_PURCHASE';
    if (m.contains('سحب نقدي') || m.contains('atm')) return 'ATM_WITHDRAWAL';
    if (m.contains('حوالة واردة') || m.contains('إيداع') || m.contains('deposit')) return 'TRANSFER_IN';
    if (m.contains('حوالة صادرة') || m.contains('تحويل')) return 'TRANSFER_OUT';
    if (m.contains('سداد') || m.contains('فاتورة')) return 'BILL_PAYMENT';
    if (m.contains('استرجاع') || m.contains('استرداد') || m.contains('refund')) return 'REFUND';
    if (m.contains('شراء') || m.contains('purchase')) return 'PURCHASE';
    return 'PURCHASE';
  }

  @override
  double? extractAmount(String message) {
    final normalized = ArabicNumberNormalizer.normalizeDigits(message);
    final match = RegExp(
      r'(?:بمبلغ|مبلغ|بقيمة|amount|SAR)[\s:]*(?:SAR|ر\.س|ريال)?[\s:]*([0-9,.]+)',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (match != null) {
      return ArabicNumberNormalizer.parseAmount(match.group(1)!);
    }
    return ArabicNumberNormalizer.parseAmount(message);
  }

  @override
  String extractMerchant(String message) {
    final m = message.toLowerCase();

    // 1. Salary
    if (m.contains('راتب') || m.contains('salary')) {
      final senderMatch = RegExp(r'(?:من|جهة|صاحب العمل)[\s:]+([^\n\r,.]+)', caseSensitive: false).firstMatch(message);
      if (senderMatch != null && senderMatch.group(1)!.trim().isNotEmpty) {
        return 'راتب - ${senderMatch.group(1)!.trim()}';
      }
      return 'راتب شهري';
    }

    // 2. Incoming transfer
    if (m.contains('حوالة واردة')) {
      final senderMatch = RegExp(r'(?:من)[\s:]+([^\n\r,.]+)', caseSensitive: false).firstMatch(message);
      if (senderMatch != null && senderMatch.group(1)!.trim().isNotEmpty) {
        return 'حوالة واردة من ${senderMatch.group(1)!.trim()}';
      }
      return 'حوالة واردة';
    }

    // 3. Bill payment
    if (m.contains('سداد فاتورة') || m.contains('سداد')) {
      final billMatch = RegExp(r'(?:سداد\s*(?:فاتورة)?|فاتورة)[\s:]+([^\n\r,.]+)', caseSensitive: false).firstMatch(message);
      if (billMatch != null && billMatch.group(1)!.trim().isNotEmpty) {
        return billMatch.group(1)!.trim();
      }
    }

    // 4. POS / Online purchase
    final matchAr = RegExp(r'لدى\s+([^في\n\r,.]+)', caseSensitive: false).firstMatch(message);
    if (matchAr != null) return matchAr.group(1)!.trim();

    final matchEn = RegExp(r'at\s+([a-zA-Z0-9\s&_-]+?)(?:\s+(?:on|via)|\.|$)', caseSensitive: false)
        .firstMatch(message);
    if (matchEn != null) return matchEn.group(1)!.trim();

    return 'البنك السعودي للاستثمار';
  }
}
