import '../utils/arabic_number_normalizer.dart';

class AccountExtractorResult {
  final String? sourceAccount;
  final String? destinationAccount;
  final String? cardLast4;

  AccountExtractorResult({this.sourceAccount, this.destinationAccount, this.cardLast4});
}

class AccountExtractor {
  static AccountExtractorResult extract(String message) {
    final normalized = ArabicNumberNormalizer.normalizeDigits(message);

    String? source;
    String? destination;
    String? card;

    // Source account: "من: XXX2001", "من X2001", "من حساب XXX2001"
    final sourceMatch = RegExp(
      r'(?:من\s*(?:حساب)?|source\s*account)[\s:]*([*xX#\d]{4,16})',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (sourceMatch != null) {
      source = sourceMatch.group(1)!.trim();
    }

    // Destination account: "الى: XXX2001", "الى X6980", "إلى حساب *6980", "to: XXX2001"
    final destMatches = RegExp(
      r'(?:إلى|الى|to)[\s:]*([*xX#\d]{4,16})',
      caseSensitive: false,
    ).allMatches(normalized);

    if (destMatches.isNotEmpty) {
      // Pick the last destination account match if multiple
      destination = destMatches.last.group(1)!.trim();
    }

    // Card extraction: "بطاقة: *4019", "مدى سامسونج X3232", "ending 1234"
    card = ArabicNumberNormalizer.extractCardSuffix(normalized);

    return AccountExtractorResult(
      sourceAccount: source,
      destinationAccount: destination,
      cardLast4: card,
    );
  }

  static String? normalizeSuffix(String? accountOrCard) {
    if (accountOrCard == null) return null;
    final match = RegExp(r'\d{4}$').firstMatch(accountOrCard.trim());
    return match?.group(0);
  }
}