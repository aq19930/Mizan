class SalaryCandidateResult {
  final bool isExplicitSalary;
  final bool isCandidate;
  final String promptAr;
  final String promptEn;

  SalaryCandidateResult({
    required this.isExplicitSalary,
    required this.isCandidate,
    this.promptAr = 'يبدو أن هذا المبلغ راتبك الشهري. هل تريد اعتباره راتبًا؟',
    this.promptEn = 'This transaction looks like your monthly salary. Would you like to categorize it as Salary?',
  });
}

class SalaryCandidateDetector {
  static SalaryCandidateResult detect(String message, double amount, bool isIncoming) {
    final lower = message.toLowerCase();

    // 1. Explicit salary keywords
    final hasExplicit = lower.contains('راتب') ||
        lower.contains('salary') ||
        lower.contains('payroll') ||
        lower.contains('مسير رواتب');

    if (hasExplicit) {
      return SalaryCandidateResult(isExplicitSalary: true, isCandidate: true);
    }

    // 2. Candidate heuristic: Incoming money between 2,500 SAR and 80,000 SAR
    if (isIncoming && amount >= 2500.0 && amount <= 80000.0) {
      return SalaryCandidateResult(isExplicitSalary: false, isCandidate: true);
    }

    return SalaryCandidateResult(isExplicitSalary: false, isCandidate: false);
  }
}