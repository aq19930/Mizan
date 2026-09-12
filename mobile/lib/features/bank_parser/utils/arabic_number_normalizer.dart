class ArabicNumberNormalizer {
  static const Map<String, String> _arabicToEnglishDigits = {
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
  };

  /// Converts all Arabic-Indic numerals in a string to standard Western digits.
  static String normalizeDigits(String input) {
    var result = input;
    _arabicToEnglishDigits.forEach((ar, en) {
      result = result.replaceAll(ar, en);
    });
    return result;
  }

  /// Normalizes amounts, e.g. "١٥٠٫٥٠ ر.س" or "1,250.00 SAR" -> double 150.50 or 1250.00
  static double? parseAmount(String input) {
    if (input.trim().isEmpty) return null;

    var cleaned = normalizeDigits(input);
    // Replace Arabic decimal separator (٫) with dot (.)
    cleaned = cleaned.replaceAll('٫', '.');
    // Remove currency words and symbols
    cleaned = cleaned
        .replaceAll(RegExp(r'(SAR|ر\.س|ريال|رس)', caseSensitive: false), '')
        .trim();

    // If there is comma as thousands separator (e.g. 1,250.50), remove it
    // If comma is used as decimal separator (e.g. 1250,50), handle accordingly
    if (cleaned.contains(',') && cleaned.contains('.')) {
      cleaned = cleaned.replaceAll(',', '');
    } else if (cleaned.contains(',')) {
      // Check if it's thousands separator or decimal
      final parts = cleaned.split(',');
      if (parts.length == 2 && parts[1].length == 2) {
        cleaned = '${parts[0]}.${parts[1]}';
      } else {
        cleaned = cleaned.replaceAll(',', '');
      }
    }

    // Extract first valid numeric floating point sequence
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(cleaned);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  /// Extracts card suffix from phrases like "بطاقة: *1234", "المنتهية بـ 8831", or "card ending 5678"
  static String? extractCardSuffix(String text) {
    final normalized = normalizeDigits(text);

    // Pattern 1: Explicit ending keywords: المنتهية بـ 1234 or ending (in) 1234
    final endingMatch = RegExp(r'(?:المنتهية?\s+بـ?|ending\s+(?:in\s+)?)[*xX\s]*(\d{4})', caseSensitive: false)
        .firstMatch(normalized);
    if (endingMatch != null) return endingMatch.group(1);

    // Pattern 2: Card / Account / To / From mention: حساب, بطاقة, الى, من, card, account, to, from
    final cardMatch = RegExp(r'(?:بطاقة|بطاقتك|حساب|إلى|الى|من|card|account|to|from)[^0-9\n]{0,35}[*xX#]*\s*(\d{4})', caseSensitive: false)
        .firstMatch(normalized);
    if (cardMatch != null) return cardMatch.group(1);

    // Pattern 3: Standalone *1234 or XXX1234 or **1234
    final starMatch = RegExp(r'[*xX]{1,4}\s*(\d{4})').firstMatch(normalized);
    if (starMatch != null) return starMatch.group(1);

    return null;
  }

  /// Normalizes date strings commonly found in Saudi bank messages
  static DateTime? parseDate(String text) {
    final normalized = normalizeDigits(text);

    // Pattern 1: YYYY-MM-DD or YYYY/MM/DD with optional time HH:mm
    final isoMatch = RegExp(r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})(?:[\sT]+(\d{1,2}):(\d{2}))?')
        .firstMatch(normalized);
    if (isoMatch != null) {
      final y = int.parse(isoMatch.group(1)!);
      final m = int.parse(isoMatch.group(2)!);
      final d = int.parse(isoMatch.group(3)!);
      final h = isoMatch.group(4) != null ? int.parse(isoMatch.group(4)!) : 12;
      final min = isoMatch.group(5) != null ? int.parse(isoMatch.group(5)!) : 0;
      return DateTime(y, m, d, h, min);
    }

    // Pattern 2: DD/MM/YYYY or DD-MM-YYYY with optional time
    final dmyMatch = RegExp(r'(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})(?:[\sT]+(\d{1,2}):(\d{2}))?')
        .firstMatch(normalized);
    if (dmyMatch != null) {
      final d = int.parse(dmyMatch.group(1)!);
      final m = int.parse(dmyMatch.group(2)!);
      var y = int.parse(dmyMatch.group(3)!);
      if (y < 100) y += 2000;
      final h = dmyMatch.group(4) != null ? int.parse(dmyMatch.group(4)!) : 12;
      final min = dmyMatch.group(5) != null ? int.parse(dmyMatch.group(5)!) : 0;
      return DateTime(y, m, d, h, min);
    }

    return null;
  }
}
