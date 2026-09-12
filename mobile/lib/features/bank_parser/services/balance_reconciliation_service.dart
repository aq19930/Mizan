class ReconciliationResult {
  final bool hasDiscrepancy;
  final double mizanBalance;
  final double reportedBankBalance;
  final double difference;
  final String explanationAr;
  final String explanationEn;
  final String recommendedActionAr;
  final String recommendedActionEn;

  const ReconciliationResult({
    required this.hasDiscrepancy,
    required this.mizanBalance,
    required this.reportedBankBalance,
    required this.difference,
    required this.explanationAr,
    required this.explanationEn,
    required this.recommendedActionAr,
    required this.recommendedActionEn,
  });
}

class BalanceReconciliationService {
  /// Compares calculated Mizan wallet balance against reported bank SMS balance.
  /// Never modifies balance silently.
  static ReconciliationResult reconcile({
    required double mizanCurrentBalance,
    required double? reportedBankBalance,
  }) {
    if (reportedBankBalance == null) {
      return ReconciliationResult(
        hasDiscrepancy: false,
        mizanBalance: mizanCurrentBalance,
        reportedBankBalance: mizanCurrentBalance,
        difference: 0.0,
        explanationAr: 'لا يتضمن نص الرسالة رصيداً بنكياً معلناً.',
        explanationEn: 'No reported balance found in the message.',
        recommendedActionAr: 'لا يتطلب أي إجراء.',
        recommendedActionEn: 'No action required.',
      );
    }

    final diff = reportedBankBalance - mizanCurrentBalance;
    final hasDiscrepancy = diff.abs() > 0.50; // Threshold of 0.50 SAR

    if (!hasDiscrepancy) {
      return ReconciliationResult(
        hasDiscrepancy: false,
        mizanBalance: mizanCurrentBalance,
        reportedBankBalance: reportedBankBalance,
        difference: 0.0,
        explanationAr: 'رصيد ميزان متطابق تماماً مع رصيد البنك المعلن.',
        explanationEn: 'Mizan balance is fully reconciled with reported bank balance.',
        recommendedActionAr: 'الأمور تسير بسلاسة ودقة.',
        recommendedActionEn: 'Everything is on track.',
      );
    }

    final isReportedHigher = diff > 0;
    final diffFormatted = diff.abs().toStringAsFixed(2);

    final explanationAr = isReportedHigher
        ? 'رصيد البنك أعلى من رصيد ميزان بفارق $diffFormatted ر.س. قد توجد عملية إيداع أو دخل لم يتم رصدها بعد.'
        : 'رصيد ميزان أعلى من رصيد البنك بفارق $diffFormatted ر.س. قد توجد عملية صرف أو رسوم لم تسجل في التطبيق.';

    final explanationEn = isReportedHigher
        ? 'Reported bank balance is higher by $diffFormatted SAR. You may have an unrecorded deposit.'
        : 'Mizan balance is higher by $diffFormatted SAR. You may have an unrecorded expense or bank fee.';

    return ReconciliationResult(
      hasDiscrepancy: true,
      mizanBalance: mizanCurrentBalance,
      reportedBankBalance: reportedBankBalance,
      difference: diff,
      explanationAr: explanationAr,
      explanationEn: explanationEn,
      recommendedActionAr: 'يمكنك مراجعة العمليات الأخيرة أو تحديث رصيد البداية ليتطابق مع كشف حسابك.',
      recommendedActionEn: 'Review recent transactions or adjust your wallet starting balance.',
    );
  }
}
