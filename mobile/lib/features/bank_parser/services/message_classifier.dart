enum MessageClassification {
  financialTransaction,
  otp,
  securityAlert,
  marketing,
  balanceInformation,
  failedTransaction,
  other,
}

class MessageClassifier {
  static const List<String> _otpKeywords = [
    'رمز التحقق',
    'كلمة المرور لمرة واحدة',
    'رمز التفعيل',
    'كلمة السر المؤقتة',
    'otp',
    'verification code',
    'one time password',
    'passcode',
    'لا تشارك هذا الرمز',
    'do not share this code',
  ];

  static const List<String> _securityKeywords = [
    'تسجيل دخول جديد',
    'تغيير كلمة المرور',
    'تم قفل الحساب',
    'محاولة تسجيل الدخول',
    'new login',
    'password changed',
    'account locked',
    'security alert',
  ];

  static const List<String> _failedKeywords = [
    'مرفوضة',
    'فشلت العملية',
    'رصيد غير كاف',
    'declined',
    'failed transaction',
    'insufficient balance',
    'unsuccessful',
    'rejected',
  ];

  static const List<String> _marketingKeywords = [
    'عرض حصري',
    'خصم',
    'استرجع نقودك',
    'كاش باك',
    'تمويلك جاهز',
    'promo',
    'discount',
    'exclusive offer',
    'cashback offer',
  ];

  static const List<String> _financialKeywords = [
    'شراء',
    'عملية شراء',
    'دفع',
    'عملية دفع',
    'سداد',
    'سداد فاتورة',
    'نقاط بيع',
    'خصم من حسابك',
    'سحب نقدي',
    'تحويل',
    'حوالة',
    'إيداع',
    'راتب',
    'مدى',
    'فيزا',
    'ماستركارد',
    'purchase',
    'payment',
    'pos',
    'atm withdrawal',
    'transfer',
    'deposit',
    'salary',
    'bill payment',
    'mada',
    'visa',
    'mastercard',
  ];

  /// Classifies incoming bank SMS message.
  static MessageClassification classify(String message) {
    final lower = message.toLowerCase();

    // 1. Strict OTP check: Highest priority to protect user security
    for (final kw in _otpKeywords) {
      if (lower.contains(kw)) {
        return MessageClassification.otp;
      }
    }

    // 2. Failed / Declined transaction check
    for (final kw in _failedKeywords) {
      if (lower.contains(kw)) {
        return MessageClassification.failedTransaction;
      }
    }

    // 3. Security alert
    for (final kw in _securityKeywords) {
      if (lower.contains(kw)) {
        return MessageClassification.securityAlert;
      }
    }

    // 4. Marketing messages
    for (final kw in _marketingKeywords) {
      if (lower.contains(kw) && !lower.contains('شراء') && !lower.contains('purchase')) {
        return MessageClassification.marketing;
      }
    }

    // 5. Balance Inquiry only
    if ((lower.contains('رصيد حسابك') || lower.contains('available balance')) &&
        !lower.contains('شراء') &&
        !lower.contains('سحب') &&
        !lower.contains('خصم') &&
        !lower.contains('تحويل') &&
        !lower.contains('purchase')) {
      return MessageClassification.balanceInformation;
    }

    // 6. Financial transaction
    for (final kw in _financialKeywords) {
      if (lower.contains(kw)) {
        return MessageClassification.financialTransaction;
      }
    }

    return MessageClassification.other;
  }

  /// Determines if message is eligible to create a financial transaction candidate.
  static bool isEligibleForParsing(String message) {
    final classification = classify(message);
    return classification == MessageClassification.financialTransaction;
  }
}
