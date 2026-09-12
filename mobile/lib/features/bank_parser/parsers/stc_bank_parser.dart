import '../utils/arabic_number_normalizer.dart';
import 'base_bank_parser.dart';

class StcBankParser extends BaseBankParser {
  @override
  String get bankIdentifier => 'STC_BANK';

  @override
  String get bankDisplayNameAr => 'بنك إس تي سي';

  @override
  String get bankDisplayNameEn => 'STC Bank';

  @override
  bool canParse(String message, {String? sender}) {
    final s = (sender ?? '').toLowerCase();
    final m = message.toLowerCase();
    return s.contains('stc') ||
        s.contains('stcpay') ||
        s.contains('stc bank') ||
        m.contains('stc pay') ||
        m.contains('stc bank') ||
        m.contains('إس تي سي');
  }

  @override
  String detectBank(String message, {String? sender}) => bankIdentifier;

  @override
  String extractTransactionType(String message) {
    final m = message.toLowerCase();
    if (m.contains('تحويل إلى') || m.contains('تم تحويل') && m.contains('إلى')) return 'TRANSFER_OUT';
    if (m.contains('استلام تحويل') || m.contains('حوالة واردة') || m.contains('تم إيداع')) return 'TRANSFER_IN';
    if (m.contains('سداد') || m.contains('فاتورة')) return 'BILL_PAYMENT';
    if (m.contains('سحب نقدي') || m.contains('atm')) return 'ATM_WITHDRAWAL';
    if (m.contains('إنترنت') || m.contains('online')) return 'ONLINE_PURCHASE';
    if (m.contains('شراء') || m.contains('خصم') || m.contains('purchase')) return 'PURCHASE';
    return 'PURCHASE';
  }

  @override
  double? extractAmount(String message) {
    final normalized = ArabicNumberNormalizer.normalizeDigits(message);
    // Patterns: "تم خصم 35.00 ر.س" or "تم تحويل 250.00" or "مبلغ 35.00"
    final match = RegExp(
      r'(?:تم خصم|تم تحويل|مبلغ|بقيمة|amount|SAR)[\s:]*([0-9,.]+)',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (match != null) {
      return ArabicNumberNormalizer.parseAmount(match.group(1)!);
    }
    return ArabicNumberNormalizer.parseAmount(message);
  }

  @override
  String extractMerchant(String message) {
    final matchAr = RegExp(r'لدى\s+([^عبر\n\r,.]+)', caseSensitive: false).firstMatch(message);
    if (matchAr != null) return matchAr.group(1)!.trim();

    final matchTransfer = RegExp(r'إلى\s+([^\n\r,.]+)', caseSensitive: false).firstMatch(message);
    if (matchTransfer != null) return matchTransfer.group(1)!.trim();

    final matchEn = RegExp(r'at\s+([a-zA-Z0-9\s&_-]+?)(?:\s+(?:on|via)|\.|$)', caseSensitive: false)
        .firstMatch(message);
    if (matchEn != null) return matchEn.group(1)!.trim();

    return 'UNKNOWN_MERCHANT';
  }
}
