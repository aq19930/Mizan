import '../utils/arabic_number_normalizer.dart';
import 'base_bank_parser.dart';

class RiyadBankParser extends BaseBankParser {
  @override
  String get bankIdentifier => 'RIYAD_BANK';

  @override
  String get bankDisplayNameAr => 'بنك الرياض';

  @override
  String get bankDisplayNameEn => 'Riyad Bank';

  @override
  bool canParse(String message, {String? sender}) {
    final s = (sender ?? '').toLowerCase();
    final m = message.toLowerCase();
    return s.contains('riyad') || m.contains('الرياض') || m.contains('riyad bank');
  }

  @override
  String detectBank(String message, {String? sender}) => bankIdentifier;

  @override
  String extractTransactionType(String message) {
    final m = message.toLowerCase();
    if (m.contains('سحب نقدي') || m.contains('atm')) return 'ATM_WITHDRAWAL';
    if (m.contains('حوالة') || m.contains('تحويل')) return 'TRANSFER_OUT';
    if (m.contains('إيداع') || m.contains('راتب')) return 'TRANSFER_IN';
    if (m.contains('سداد')) return 'BILL_PAYMENT';
    if (m.contains('إنترنت') || m.contains('online')) return 'ONLINE_PURCHASE';
    if (m.contains('شراء') || m.contains('خصم عملية')) return 'PURCHASE';
    return 'PURCHASE';
  }

  @override
  double? extractAmount(String message) {
    final normalized = ArabicNumberNormalizer.normalizeDigits(message);
    final match = RegExp(
      r'(?:مبلغ|بقيمة|بمبلغ|amount|SAR)[\s:]*([0-9,.]+)',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (match != null) {
      return ArabicNumberNormalizer.parseAmount(match.group(1)!);
    }
    return ArabicNumberNormalizer.parseAmount(message);
  }

  @override
  String extractMerchant(String message) {
    final matchAr = RegExp(r'لدى\s+([^بتاريخ\n\r,.]+)', caseSensitive: false).firstMatch(message);
    if (matchAr != null) return matchAr.group(1)!.trim();

    final matchEn = RegExp(r'at\s+([a-zA-Z0-9\s&_-]+?)(?:\s+(?:on|date)|\.|$)', caseSensitive: false)
        .firstMatch(message);
    if (matchEn != null) return matchEn.group(1)!.trim();

    return 'UNKNOWN_MERCHANT';
  }
}
