import '../utils/arabic_number_normalizer.dart';
import 'base_bank_parser.dart';

class SabParser extends BaseBankParser {
  @override
  String get bankIdentifier => 'SAB';

  @override
  String get bankDisplayNameAr => 'البنك السعودي الأول';

  @override
  String get bankDisplayNameEn => 'Saudi Awwal Bank (SAB)';

  @override
  bool canParse(String message, {String? sender}) {
    final s = (sender ?? '').toLowerCase();
    final m = message.toLowerCase();
    return s.contains('sab') ||
        s.contains('sabb') ||
        m.contains('الأول') ||
        m.contains('الاول') ||
        m.contains('sab');
  }

  @override
  String detectBank(String message, {String? sender}) => bankIdentifier;

  @override
  String extractTransactionType(String message) {
    final m = message.toLowerCase();
    if (m.contains('pos purchase') || m.contains('نقاط بيع')) return 'POS_PURCHASE';
    if (m.contains('online') || m.contains('إنترنت')) return 'ONLINE_PURCHASE';
    if (m.contains('atm') || m.contains('سحب نقدي')) return 'ATM_WITHDRAWAL';
    if (m.contains('transfer to') || m.contains('حوالة صادرة')) return 'TRANSFER_OUT';
    if (m.contains('transfer from') || m.contains('حوالة واردة')) return 'TRANSFER_IN';
    if (m.contains('bill') || m.contains('سداد')) return 'BILL_PAYMENT';
    return 'PURCHASE';
  }

  @override
  double? extractAmount(String message) {
    final normalized = ArabicNumberNormalizer.normalizeDigits(message);
    final match = RegExp(
      r'(?:of|amount|مبلغ|بمبلغ|SAR)[\s:]*([0-9,.]+)',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (match != null) {
      return ArabicNumberNormalizer.parseAmount(match.group(1)!);
    }
    return ArabicNumberNormalizer.parseAmount(message);
  }

  @override
  String extractMerchant(String message) {
    final matchEn = RegExp(r'at\s+([a-zA-Z0-9\s&_-]+?)(?:\s+(?:on|via)|\.|$)', caseSensitive: false)
        .firstMatch(message);
    if (matchEn != null) return matchEn.group(1)!.trim();

    final matchAr = RegExp(r'لدى\s+([^في\n\r,.]+)', caseSensitive: false).firstMatch(message);
    if (matchAr != null) return matchAr.group(1)!.trim();

    return 'UNKNOWN_MERCHANT';
  }
}
