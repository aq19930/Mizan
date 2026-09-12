class TrafficFineResult {
  final bool isTrafficFine;
  final String? violationReference;
  final String? lawReference;

  TrafficFineResult({
    required this.isTrafficFine,
    this.violationReference,
    this.lawReference,
  });
}

class TrafficFineDetector {
  static TrafficFineResult detect(String message) {
    final lower = message.toLowerCase();

    final hasTrafficKeywords = lower.contains('نظام المرور') ||
        lower.contains('مخالفة') ||
        lower.contains('مرور') ||
        lower.contains('trf') ||
        lower.contains('traffic');

    if (!hasTrafficKeywords) {
      return TrafficFineResult(isTrafficFine: false);
    }

    // Extract TRF violation code: "TRF 48100009799845" or "مخالفة TRF 4810..."
    String? ref;
    final trfMatch = RegExp(r'(TRF\s*[0-9]{8,20})', caseSensitive: false).firstMatch(message);
    if (trfMatch != null) {
      ref = trfMatch.group(1)!.trim();
    } else {
      final numMatch = RegExp(r'(?:مخالفة|رقم)[\s:]*([0-9]{8,20})', caseSensitive: false).firstMatch(message);
      if (numMatch != null) ref = numMatch.group(1)!.trim();
    }

    // Extract law reference: "المادة رقم (75) من نظام المرور"
    String? law;
    final lawMatch = RegExp(r'(المادة\s*(?:رقم)?\s*\(?[0-9]+\)?\s*من\s*نظام\s*المرور)', caseSensitive: false)
        .firstMatch(message);
    if (lawMatch != null) {
      law = lawMatch.group(1)!.trim();
    }

    return TrafficFineResult(
      isTrafficFine: true,
      violationReference: ref,
      lawReference: law,
    );
  }
}