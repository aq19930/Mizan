import '../utils/arabic_number_normalizer.dart';
import 'base_bank_parser.dart';

class GenericBankParser extends BaseBankParser {
  @override
  String get bankIdentifier => 'GENERIC_BANK';

  @override
  String get bankDisplayNameAr => 'مصرف عام';

  @override
  String get bankDisplayNameEn => 'Generic Bank';

  @override
  bool canParse(String message, {String? sender}) => true;

  @override
  String detectBank(String message, {String? sender}) => sender ?? bankIdentifier;

  @override
  String extractTransactionType(String message) {
    final m = message.toLowerCase();
    if (m.contains('سحب نقدي') || m.contains('atm')) return 'ATM_WITHDRAWAL';
    if (m.contains('حوالة صادرة') || m.contains('تحويل إلى')) return 'TRANSFER_OUT';
    if (m.contains('حوالة واردة') || m.contains('إيداع') || m.contains('راتب')) return 'TRANSFER_IN';
    if (m.contains('سداد') || m.contains('فاتورة') || m.contains('bill')) return 'BILL_PAYMENT';
    if (m.contains('نقاط بيع') || m.contains('pos')) return 'POS_PURCHASE';
    if (m.contains('إنترنت') || m.contains('online')) return 'ONLINE_PURCHASE';
    if (m.contains('شراء') || m.contains('purchase') || m.contains('خصم')) return 'PURCHASE';
    return 'PURCHASE';
  }

  @override
  double? extractAmount(String message) {
    return ArabicNumberNormalizer.parseAmount(message);
  }

  @override
  String extractMerchant(String message) {
    final matchAr = RegExp(r'لدى\s+([^\s,.\n\r]+(?:\s+[^\s,.\n\r]+){0,3})', caseSensitive: false)
        .firstMatch(message);
    if (matchAr != null) return matchAr.group(1)!.trim();

    final matchEn = RegExp(r'(?:at|to)\s+([a-zA-Z0-9\s&_-]+?)(?:\s+(?:on|via|date)|\.|$)', caseSensitive: false)
        .firstMatch(message);
    if (matchEn != null) return matchEn.group(1)!.trim();

    return 'UNKNOWN_MERCHANT';
  }
}
