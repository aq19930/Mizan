import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/bank_parser/data/models/field_confidence.dart';
import 'package:mobile/features/bank_parser/data/models/parsed_bank_transaction.dart';
import 'package:mobile/features/bank_parser/parsers/alinma_parser.dart';
import 'package:mobile/features/bank_parser/parsers/alrajhi_parser.dart';
import 'package:mobile/features/bank_parser/parsers/bank_parser_factory.dart';
import 'package:mobile/features/bank_parser/parsers/generic_bank_parser.dart';
import 'package:mobile/features/bank_parser/parsers/riyad_parser.dart';
import 'package:mobile/features/bank_parser/parsers/sab_parser.dart';
import 'package:mobile/features/bank_parser/parsers/saib_parser.dart';
import 'package:mobile/features/bank_parser/parsers/snb_parser.dart';
import 'package:mobile/features/bank_parser/parsers/stc_bank_parser.dart';
import 'package:mobile/features/bank_parser/services/balance_reconciliation_service.dart';
import 'package:mobile/features/bank_parser/services/commitment_matcher_service.dart';
import 'package:mobile/features/bank_parser/services/message_classifier.dart';
import 'package:mobile/features/bank_parser/utils/arabic_number_normalizer.dart';
import 'package:mobile/features/commitments/data/models/commitment_model.dart';

void main() {
  group('1. Arabic Number Normalizer Tests', () {
    test('Normalizes Eastern Arabic numerals to standard digits', () {
      expect(ArabicNumberNormalizer.normalizeDigits('١٢٣٤٥٦٧٨٩٠'), '1234567890');
      expect(ArabicNumberNormalizer.normalizeDigits('المبلغ ١٤٥ ريال'), 'المبلغ 145 ريال');
    });

    test('Parses decimal amounts accurately', () {
      expect(ArabicNumberNormalizer.parseAmount('شراء بمبلغ 1250.75 ر.س'), 1250.75);
      expect(ArabicNumberNormalizer.parseAmount('بمبلغ ١٥٠٠٫٢٥ ريال'), 1500.25);
      expect(ArabicNumberNormalizer.parseAmount('عملية بقيمة 5,430.00 SAR'), 5430.00);
      expect(ArabicNumberNormalizer.parseAmount('لا يوجد مبلغ هنا'), isNull);
    });

    test('Normalizes Arabic dates correctly', () {
      final date = ArabicNumberNormalizer.parseDate('2026/09/11');
      expect(date, isNotNull);
      expect(date!.year, 2026);
      expect(date.month, 9);
      expect(date.day, 11);
    });
  });

  group('2. Message Classifier & Privacy Security Tests', () {
    test('Classifies transactions as financial and eligible', () {
      const sms = 'شراء عبر مدى بمبلغ 85.00 ر.س لدى متجر بنده بتاريخ 11/09/2026';
      expect(MessageClassifier.classify(sms), MessageClassification.financialTransaction);
      expect(MessageClassifier.isEligibleForParsing(sms), isTrue);
    });

    test('STRICT REJECTION: Rejects OTP messages from creating transactions', () {
      const otpSms1 = 'رمز التحقق لمرة واحدة OTP هو: 492018. لا تشارك هذا الرمز مع أي شخص.';
      const otpSms2 = 'Your verification code is 884129. Do not share this code with anyone.';

      expect(MessageClassifier.classify(otpSms1), MessageClassification.otp);
      expect(MessageClassifier.isEligibleForParsing(otpSms1), isFalse);

      expect(MessageClassifier.classify(otpSms2), MessageClassification.otp);
      expect(MessageClassifier.isEligibleForParsing(otpSms2), isFalse);
    });

    test('STRICT REJECTION: Rejects marketing advertisements', () {
      const promoSms = 'عرض حصري! احصل على تمويل شخصي بهامش ربح يبدأ من 1.99%. للتقديم اتصل الآن.';
      expect(MessageClassifier.classify(promoSms), MessageClassification.marketing);
      expect(MessageClassifier.isEligibleForParsing(promoSms), isFalse);
    });

    test('Identifies failed transactions', () {
      const failedSms = 'عملية مرفوضة: رصيد غير كاف لتنفيذ العملية بمبلغ 450 ر.س لدى جرير.';
      expect(MessageClassifier.classify(failedSms), MessageClassification.failedTransaction);
      expect(MessageClassifier.isEligibleForParsing(failedSms), isFalse);
    });
  });

  group('3. Saudi Bank Parsers Verification (All 8 Banks)', () {
    test('Al Rajhi Bank Parser', () {
      const sms =
          'شراء عبر مدى: بمبلغ 1250.00 ر.س من بطاقة مدى *4019 لدى AL RAJHI BANK LEASING في 2026/09/11 09:15. الرصيد: 12845.50 ر.س. الرقم المرجعي: TX-984210.';
      final parser = AlRajhiParser();
      expect(parser.canParse(sms, sender: 'AlRajhiBank'), isTrue);

      final result = parser.parse(sms, sender: 'AlRajhiBank');
      expect(result, isNotNull);
      expect(result!.amount, 1250.00);
      expect(result.currency, 'SAR');
      expect(result.cardLast4, '4019');
      expect(result.reportedBalance, 12845.50);
      expect(result.referenceNumber, 'TX-984210');
      expect(result.confidence.overall, greaterThanOrEqualTo(0.90));
    });

    test('SNB (الأهلي) Parser', () {
      const sms =
          'عملية شراء بمبلغ 145.25 ر.س من بطاقتك مدى المنتهية بـ 8831 لدى PANDA STORES بتاريخ 10/09/2026 18:20. رصيدك الحالي: 5430.00 ر.س.';
      final parser = SnbParser();
      expect(parser.canParse(sms, sender: 'SNB'), isTrue);

      final result = parser.parse(sms, sender: 'SNB');
      expect(result, isNotNull);
      expect(result!.amount, 145.25);
      expect(result.merchant, contains('PANDA'));
      expect(result.reportedBalance, 5430.00);
    });

    test('Riyad Bank (الرياض) Parser', () {
      const sms =
          'تم سداد فاتورة سداد بمبلغ 290.00 ر.س من حسابك الجاري لدى STC Telecom بتاريخ 08/09/2026. الرصيد: 8910.00 ر.س.';
      final parser = RiyadBankParser();
      expect(parser.canParse(sms, sender: 'RiyadBank'), isTrue);

      final result = parser.parse(sms, sender: 'RiyadBank');
      expect(result, isNotNull);
      expect(result!.amount, 290.00);
      expect(result.transactionType, 'BILL_PAYMENT');
      expect(result.reportedBalance, 8910.00);
    });

    test('Alinma Bank (الإنماء) Parser', () {
      const sms =
          'سحب نقدي من صراف آلي بمبلغ 500.00 ر.س باستخدام بطاقة مدى *6102 بتاريخ 2026/09/09 14:00. رصيدك المتاح: 3200.00 ر.س.';
      final parser = AlinmaParser();
      expect(parser.canParse(sms, sender: 'Alinma'), isTrue);

      final result = parser.parse(sms, sender: 'Alinma');
      expect(result, isNotNull);
      expect(result!.amount, 500.00);
      expect(result.transactionType, 'ATM_WITHDRAWAL');
      expect(result.cardLast4, '6102');
      expect(result.reportedBalance, 3200.00);
    });

    test('SAB (البنك الأول) Parser', () {
      const sms =
          'Purchase of SAR 85.50 with SAB credit card ending 1204 at JARIR BOOKSTORE on 11/09/2026. Avail Limit: SAR 15400.00.';
      final parser = SabParser();
      expect(parser.canParse(sms, sender: 'SAB'), isTrue);

      final result = parser.parse(sms, sender: 'SAB');
      expect(result, isNotNull);
      expect(result!.amount, 85.50);
      expect(result.cardLast4, '1204');
      expect(result.merchant, contains('JARIR'));
    });

    test('SAIB (البنك السعودي للاستثمار) Parser - User Requested', () {
      const sms =
          'تمت عملية شراء عبر بطاقة الاستثمار مدى *9942 بمبلغ 320.00 ر.س لدى EXTRA STORES في 11/09/2026 12:40. الرصيد: 9800.00 ر.س.';
      final parser = SaibParser();
      expect(parser.canParse(sms, sender: 'SAIB'), isTrue);

      final result = parser.parse(sms, sender: 'SAIB');
      expect(result, isNotNull);
      expect(result!.bank, 'SAIB');
      expect(result.amount, 320.00);
      expect(result.cardLast4, '9942');
      expect(result.reportedBalance, 9800.00);
    });

    test('STC Bank Parser - User Requested', () {
      const sms =
          'عملية دفع ناجحة عبر بطاقة STC Bank رقم *5512 بمبلغ 68.00 ر.س لدى BARN\'S COFFEE بتاريخ 11/09/2026. الرصيد: 1420.50 ر.س.';
      final parser = StcBankParser();
      expect(parser.canParse(sms, sender: 'STCBank'), isTrue);

      final result = parser.parse(sms, sender: 'STCBank');
      expect(result, isNotNull);
      expect(result!.bank, 'STC_BANK');
      expect(result.amount, 68.00);
      expect(result.cardLast4, '5512');
      expect(result.reportedBalance, 1420.50);
    });

    test('Generic Bank Fallback Parser', () {
      const sms = 'تم تنفيذ عملية شراء بمبلغ 210.00 ريال لدى متجر نون للتجارة بتاريخ 2026/09/10.';
      final parser = GenericBankParser();
      expect(parser.canParse(sms), isTrue);

      final result = parser.parse(sms);
      expect(result, isNotNull);
      expect(result!.amount, 210.00);
      expect(result.currency, 'SAR');
    });

    test('BankMessageParserFactory parses accurately through registered list', () {
      expect(BankMessageParserFactory.registeredParsers.length, 9);

      const sms =
          'عملية دفع ناجحة عبر بطاقة STC Bank رقم *5512 بمبلغ 68.00 ر.س لدى BARN\'S COFFEE بتاريخ 11/09/2026. الرصيد: 1420.50 ر.س.';
      final parsed = BankMessageParserFactory.parse(sms, sender: 'STCBank');
      expect(parsed, isNotNull);
      expect(parsed!.bank, 'STC_BANK');
      expect(parsed.amount, 68.00);
    });
  });

  group('4. Balance Reconciliation & Commitment Matcher Tests', () {
    test('Reconciles expected balance with reported balance', () {
      final reconciliation = BalanceReconciliationService.reconcile(
        mizanCurrentBalance: 9500.00,
        reportedBankBalance: 9500.00,
      );

      expect(reconciliation.hasDiscrepancy, isFalse);
      expect(reconciliation.difference, 0.0);
    });

    test('Identifies discrepancy when balances do not match', () {
      final reconciliation = BalanceReconciliationService.reconcile(
        mizanCurrentBalance: 9500.00,
        reportedBankBalance: 9300.00,
      );

      expect(reconciliation.hasDiscrepancy, isTrue);
      expect(reconciliation.difference, -200.00);
    });

    test('CommitmentMatcherService matches parsed transaction with commitment', () {
      final activeCommitments = [
        CommitmentModel(
          id: 'c-car-1',
          userId: 'u-1',
          title: 'قسط السيارة',
          category: 'Car',
          categoryNameAr: 'سيارة',
          categoryNameEn: 'Car',
          amount: 1250.00,
          frequency: 'Monthly',
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          dueDate: DateTime.now().add(const Duration(days: 2)),
          nextDueDate: DateTime.now().add(const Duration(days: 2)),
          priority: 'High',
          merchant: 'Al Rajhi Leasing',
          status: 'Active',
          isPaid: false,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
      ];

      final tx = ParsedBankTransactionDto(
        bank: 'AlRajhiBank',
        transactionType: 'PURCHASE',
        amount: 1250.00,
        merchant: 'Al Rajhi Leasing',
        transactionDate: DateTime.now(),
        category: 'Car',
        confidence: const FieldConfidence(
          overall: 0.95,
          amount: 1.0,
          merchant: 0.95,
          date: 0.95,
          transactionType: 0.95,
        ),
        messageHash: 'hash-abc',
      );

      final matchResult = CommitmentMatcherService.match(
        transaction: tx,
        activeCommitments: activeCommitments,
      );

      expect(matchResult.hasMatch, isTrue);
      expect(matchResult.matchedCommitment?.id, 'c-car-1');
      expect(matchResult.confidence, greaterThanOrEqualTo(0.80));
    });
  });
}
