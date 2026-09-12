class MerchantExtractorResult {
  final String rawMerchant;
  final String normalizedMerchant;
  final String? paymentMethod;

  MerchantExtractorResult({
    required this.rawMerchant,
    required this.normalizedMerchant,
    this.paymentMethod,
  });
}

class MerchantExtractor {
  static MerchantExtractorResult extract(String message) {
    String? raw;
    String? paymentMethod;

    // Detect payment method (e.g. مدى سامسونج, Apple Pay, Mada)
    if (message.contains('مدى سامسونج') || message.toLowerCase().contains('samsung pay')) {
      paymentMethod = 'MADA_SAMSUNG_PAY';
    } else if (message.toLowerCase().contains('apple pay') || message.contains('أبل باي')) {
      paymentMethod = 'MADA_APPLE_PAY';
    } else if (message.contains('مدى') || message.toLowerCase().contains('mada')) {
      paymentMethod = 'MADA';
    }

    // Pattern 1: "من MATHAQ A", "لدى جرير", "لدى AL BAIK"
    final atMatch = RegExp(r'(?:لدى|at)[\s:]+([^\n\r,.]+)', caseSensitive: false).firstMatch(message);
    if (atMatch != null) {
      raw = atMatch.group(1)!.trim();
    }

    // Pattern 2: "من STORE" (avoiding "من: XXX2001" which is account)
    if (raw == null) {
      final fromMatch = RegExp(r'من\s+([A-Za-z0-9 \t&_\u0621-\u064A]{2,30})', caseSensitive: false).firstMatch(message);
      if (fromMatch != null) {
        final candidate = fromMatch.group(1)!.trim();
        // Ensure candidate is not an account marker like "X2001" or "XXX2001"
        if (!RegExp(r'^[*xX#\d\s:]{4,15}$').hasMatch(candidate) && !candidate.startsWith(':')) {
          raw = candidate;
        }
      }
    }

    raw = raw ?? 'UNKNOWN_MERCHANT';

    // Normalize merchant: "MATHAQ A" -> "MATHAQ", trim punctuation
    var norm = raw.replaceAll(RegExp(r'\s+[A-Z0-9]$'), '').trim().toUpperCase();
    if (norm.isEmpty) norm = raw.toUpperCase();

    return MerchantExtractorResult(
      rawMerchant: raw,
      normalizedMerchant: norm,
      paymentMethod: paymentMethod,
    );
  }
}