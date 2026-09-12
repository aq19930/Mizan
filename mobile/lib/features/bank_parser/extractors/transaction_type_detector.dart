import 'traffic_fine_detector.dart';

class TransactionTypeDetector {
  static String detect(String message) {
    final lower = message.toLowerCase();

    // 1. Semantic Override: Traffic violations MUST override generic "حوالة صادرة"
    final traffic = TrafficFineDetector.detect(message);
    if (traffic.isTrafficFine) {
      return 'TRAFFIC_FINE';
    }

    // 2. Explicit Salary
    if (lower.contains('راتب') || lower.contains('salary') || lower.contains('payroll')) {
      return 'SALARY';
    }

    // 3. Bill Payment
    if (lower.contains('سداد فاتورة') ||
        lower.contains('مفوتر') ||
        lower.contains('فاتورة') ||
        lower.contains('سداد') ||
        lower.contains('bill payment')) {
      return 'BILL_PAYMENT';
    }

    // 4. Local Transfer
    if (lower.contains('حوالة محلية') ||
        lower.contains('حوالة صادرة: محلية') ||
        lower.contains('local transfer')) {
      return 'LOCAL_TRANSFER';
    }

    // 5. Transfer In / Incoming
    if (lower.contains('حوالة واردة') ||
        lower.contains('transfer in') ||
        lower.contains('تم إيداع') ||
        lower.contains('تم ايداع') ||
        (lower.contains('إيداع') && !lower.contains('سحب')) ||
        (RegExp(r'(?:إلى|الى|to)[\s:]*(?:حساب|account)?[*xX#]*\s*\d{3,4}', caseSensitive: false).hasMatch(message) &&
            !lower.contains('من') &&
            !lower.contains('from') &&
            !lower.contains('شراء') &&
            !lower.contains('سداد') &&
            !lower.contains('سحب') &&
            !lower.contains('صادرة'))) {
      return 'TRANSFER_IN';
    }

    // 6. Transfer Out / Outgoing Transfer
    if (lower.contains('حوالة صادرة') ||
        lower.contains('تحويل') ||
        lower.contains('transfer out')) {
      return 'TRANSFER_OUT';
    }

    // 7. POS Purchase
    if (lower.contains('شراء pos') ||
        lower.contains('نقاط بيع') ||
        lower.contains('pos') ||
        lower.contains('مدى سامسونج') ||
        lower.contains('apple pay')) {
      return 'POS_PURCHASE';
    }

    // 8. Online / E-commerce Purchase
    if (lower.contains('إنترنت') ||
        lower.contains('online') ||
        lower.contains('إلكتروني') ||
        lower.contains('ecommerce')) {
      return 'ONLINE_PURCHASE';
    }

    // 9. ATM Withdrawal
    if (lower.contains('سحب نقدي') ||
        lower.contains('صراف') ||
        lower.contains('atm')) {
      return 'ATM_WITHDRAWAL';
    }

    // 10. Government Payment
    if (lower.contains('حكومي') ||
        lower.contains('أبشر') ||
        lower.contains('government')) {
      return 'GOVERNMENT_PAYMENT';
    }

    // 11. Refund
    if (lower.contains('استرداد') ||
        lower.contains('استرجاع') ||
        lower.contains('refund')) {
      return 'REFUND';
    }

    // 12. Generic Purchase
    if (lower.contains('شراء') || lower.contains('purchase')) {
      return 'POS_PURCHASE';
    }

    // 13. Fee
    if (lower.contains('رسوم') || lower.contains('fee')) {
      return 'FEE';
    }

    return 'UNKNOWN';
  }
}