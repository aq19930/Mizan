class RecipientExtractorResult {
  final String? recipientName;
  final String? destinationBank;

  RecipientExtractorResult({this.recipientName, this.destinationBank});
}

class RecipientExtractor {
  static RecipientExtractorResult extract(String message) {
    String? recipient;
    String? bank;

    // Matches: "المصرف RJHI", "بنك الراجحي", "مصرف الإنماء", "بنك الرياض", "SNB"
    final bankMatch = RegExp(
      r'(?:المصرف|مصرف|بنك|bank)[\s:]*([A-Za-z\u0621-\u064A]{2,20})',
      caseSensitive: false,
    ).firstMatch(message);

    if (bankMatch != null) {
      bank = bankMatch.group(1)!.trim();
    }

    // Matches: "الى: عبدالعزيز محمد القحط" (non-digit name after الى:)
    final recipientMatch = RegExp(
      r'(?:إلى|الى|to)[\s:]+([\u0621-\u064A\s]{4,40})(?:\n|\r|$)',
      caseSensitive: false,
    ).firstMatch(message);

    if (recipientMatch != null) {
      recipient = recipientMatch.group(1)!.trim();
    }

    return RecipientExtractorResult(
      recipientName: recipient,
      destinationBank: bank,
    );
  }
}