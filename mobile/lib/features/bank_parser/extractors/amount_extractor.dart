import '../utils/arabic_number_normalizer.dart';

class AmountExtractor {
  static double? extract(String message) {
    final normalized = ArabicNumberNormalizer.normalizeDigits(message);

    // Pattern 1: Explicit labels: بمبلغ, المبلغ, مبلغ, بقيمة, بSAR, amount
    // Matches: "مبلغ: SAR 6,960.45", "المبلغ: SAR 171.35", "المبلغ SAR 15", "بSAR 11.05", "بمبلغ 100 ر.س"
    final match = RegExp(
      r'(?:المبلغ|بمبلغ|مبلغ|بقيمة|amount|بSAR|SAR)[\s:]*(?:SAR|ر\.س|ريال)?[\s:]*([0-9,.]+)',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (match != null) {
      final val = ArabicNumberNormalizer.parseAmount(match.group(1)!);
      if (val != null && val > 0) return val;
    }

    // Pattern 2: "بSAR 11.05" or "SAR 11.05" without prefix
    final sarMatch = RegExp(r'(?:ب)?SAR[\s:]*([0-9,.]+)', caseSensitive: false).firstMatch(normalized);
    if (sarMatch != null) {
      final val = ArabicNumberNormalizer.parseAmount(sarMatch.group(1)!);
      if (val != null && val > 0) return val;
    }

    return ArabicNumberNormalizer.parseAmount(message);
  }
}