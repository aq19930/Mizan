class BillerExtractorResult {
  final String? billerCode;
  final String? biller;
  final String? service;
  final String? billNumber;

  BillerExtractorResult({
    this.billerCode,
    this.biller,
    this.service,
    this.billNumber,
  });
}

class BillerExtractor {
  static BillerExtractorResult extract(String message) {
    String? code;
    String? billerName;
    String? service;
    String? billNum;

    // Matches: "مفوتر: 044 زين" or "مفوتر: 044"
    final billerMatch = RegExp(
      r'مفوتر[\s:]*(\d{3,4})?[\s:]*([^\n\r,.]+)?',
      caseSensitive: false,
    ).firstMatch(message);

    if (billerMatch != null) {
      code = billerMatch.group(1)?.trim();
      billerName = billerMatch.group(2)?.trim();
    }

    // Matches: "خدمة:الاتصالات والانترنت" or "خدمة: كهرباء"
    final serviceMatch = RegExp(
      r'خدمة[\s:]*([^\n\r,.]+)',
      caseSensitive: false,
    ).firstMatch(message);

    if (serviceMatch != null) {
      service = serviceMatch.group(1)!.trim();
    }

    // Matches: "رقم الفاتورة: 831032470841" or "فاتورة: 123456"
    final billNumMatch = RegExp(
      r'(?:رقم\s*الفاتورة|فاتورة)[\s:]*([0-9]{5,20})',
      caseSensitive: false,
    ).firstMatch(message);

    if (billNumMatch != null) {
      billNum = billNumMatch.group(1)!.trim();
    }

    return BillerExtractorResult(
      billerCode: code,
      biller: billerName,
      service: service,
      billNumber: billNum,
    );
  }
}