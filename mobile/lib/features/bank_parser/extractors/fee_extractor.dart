import '../utils/arabic_number_normalizer.dart';

class FeeExtractor {
  static double extract(String message) {
    final normalized = ArabicNumberNormalizer.normalizeDigits(message);

    // Matches: "رسوم: SAR 0", "الرسوم SAR 0.58", "رسوم: 1.50", "الرسوم: SAR 0.58", "fee: SAR 0.58"
    final match = RegExp(
      r'(?:الرسوم|رسوم|fees|fee)[\s:]*(?:SAR|ر\.س|ريال)?[\s:]*([0-9,.]+)',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (match != null) {
      final feeVal = ArabicNumberNormalizer.parseAmount(match.group(1)!);
      if (feeVal != null && feeVal >= 0) return feeVal;
    }

    return 0.0;
  }
}