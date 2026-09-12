import '../utils/arabic_number_normalizer.dart';
import 'base_bank_parser.dart';

class AlRajhiParser extends BaseBankParser {
  @override
  String get bankIdentifier => 'ALRAJHI';

  @override
  String get bankDisplayNameAr => 'مصرف الراجحي';

  @override
  String get bankDisplayNameEn => 'Al Rajhi Bank';

  @override
  bool canParse(String message, {String? sender}) {
    final s = (sender ?? '').toLowerCase();
    final m = message.toLowerCase();
    return s.contains('rajhi') ||
        m.contains('الراجحي') ||
        m.contains('al rajhi') ||
        m.contains('alrajhibank');
  }

  @override
  String detectBank(String message, {String? sender}) => bankIdentifier;

  @override
  String extractTransactionType(String message) {
    final m = message.toLowerCase();
    if (m.contains('نقاط بيع') || m.contains('pos')) return 'POS_PURCHASE';
    if (m.contains('إنترنت') || m.contains('شراء عبر') || m.contains('online')) return 'ONLINE_PURCHASE';
    if (m.contains('سحب نقدي') || m.contains('صراف') || m.contains('atm')) return 'ATM_WITHDRAWAL';
    if (m.contains('حوالة صادرة') || m.contains('تحويل إلى')) return 'TRANSFER_OUT';
    if (m.contains('حوالة واردة') || m.contains('إيداع') || m.contains('راتب')) return 'TRANSFER_IN';
    if (m.contains('سداد فاتورة') || m.contains('سداد')) return 'BILL_PAYMENT';
    if (m.contains('استرجاع') || m.contains('refund')) return 'REFUND';
    if (m.contains('شراء') || m.contains('purchase')) return 'PURCHASE';
    return 'PURCHASE';
  }

  @override
  double? extractAmount(String message) {
    final normalized = ArabicNumberNormalizer.normalizeDigits(message);
    // Matches: "بقيمة 120.50 رس" or "مبلغ 120.50" or "SAR 120.50"
    final match = RegExp(
      r'(?:بقيمة|مبلغ|amount|of|SAR)[\s:]*([0-9,.]+)',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (match != null) {
      return ArabicNumberNormalizer.parseAmount(match.group(1)!);
    }
    return ArabicNumberNormalizer.parseAmount(message);
  }

  @override
  String extractMerchant(String message) {
    // Al Rajhi pattern: "لدى HUNGERSTATION في" or "at MERCHANT on"
    final matchAr = RegExp(r'لدى\s+([^في\n\r,.]+)', caseSensitive: false).firstMatch(message);
    if (matchAr != null) return matchAr.group(1)!.trim();

    final matchEn = RegExp(r'(?:at|to)\s+([a-zA-Z0-9\s&_-]+?)(?:\s+(?:on|date|via)|\.|$)', caseSensitive: false)
        .firstMatch(message);
    if (matchEn != null) return matchEn.group(1)!.trim();

    return 'UNKNOWN_MERCHANT';
  }
}
