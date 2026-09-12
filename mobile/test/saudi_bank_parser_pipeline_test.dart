import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/bank_parser/data/models/transaction_direction.dart';
import 'package:mobile/features/bank_parser/extractors/account_extractor.dart';
import 'package:mobile/features/bank_parser/parsers/bank_parser_factory.dart';
import 'package:mobile/features/bank_parser/parsers/saudi_bank_message_parser.dart';
import 'package:mobile/features/bank_parser/services/message_classifier.dart';

void main() {
  group('MIZAN Saudi Bank SMS Transaction Engine Specification Tests', () {
    final parser = SaudiBankMessageParser();

    test('1. Fixture 1: Incoming Salary / Transfer In (6,960.45 SAR)', () {
      const sms = 'مبلغ: SAR 6,960.45\nالى: XXX2001\nفي: 08-25 09:22';

      final result = parser.parse(sms, sender: 'SAIB');

      expect(result, isNotNull);
      expect(result!.amount, equals(6960.45));
      expect(result.currency, equals('SAR'));
      expect(result.fee, equals(0.0));
      expect(result.totalCredit, equals(6960.45));
      expect(result.totalDebit, equals(0.0));
      expect(result.direction, equals(TransactionDirection.inDir));
      expect(result.isIncome, isTrue);
      expect(result.transactionType, equals('TRANSFER_IN'));
      expect(result.salaryCandidate, isTrue);
      expect(result.destinationAccount, contains('2001'));
      expect(AccountExtractor.normalizeSuffix(result.destinationAccount), equals('2001'));

      // If explicit salary keyword is present
      const salarySms = 'حوالة واردة: راتب\nمبلغ: SAR 6,960.45\nالى: XXX2001\nفي: 08-25 09:22';
      final salaryResult = parser.parse(salarySms, sender: 'SAIB');
      expect(salaryResult!.transactionType, equals('SALARY'));
      expect(salaryResult.isIncome, isTrue);
    });

    test('2. Fixture 2: Bill Payment Zain (171.35 SAR)', () {
      const sms = 'سداد فاتورة\nمن: XXX2001\nالمبلغ: SAR 171.35\nمفوتر: 044 زين\nخدمة:الاتصالات والانترنت\nرقم الفاتورة: 831032470841\nفي: 08-26 00:34';

      final result = parser.parse(sms, sender: 'SADAD');

      expect(result, isNotNull);
      expect(result!.transactionType, equals('BILL_PAYMENT'));
      expect(result.direction, equals(TransactionDirection.outDir));
      expect(result.isExpense, isTrue);
      expect(result.amount, equals(171.35));
      expect(result.fee, equals(0.0));
      expect(result.totalDebit, equals(171.35));
      expect(result.billerCode, equals('044'));
      expect(result.biller, equals('زين'));
      expect(result.service, equals('الاتصالات والانترنت'));
      expect(result.billNumber, equals('831032470841'));
      expect(result.category, equals('Bills'));
      expect(result.subcategory, equals('الاتصالات والانترنت'));
      expect(AccountExtractor.normalizeSuffix(result.sourceAccount), equals('2001'));
    });

    test('3. Fixture 3: Traffic Fine Semantic Override (100 SAR, TRF)', () {
      const sms = 'حوالة صادرة: محلية\nمن: XXX2001\nمبلغ: SAR 100\nرسوم: SAR 0\nفي: 09-01 20:21\nبناء على المادة رقم (75) من نظام المرور للمخالفة TRF 48100009799845';

      final result = parser.parse(sms, sender: 'MOI');

      expect(result, isNotNull);
      // Verify semantic override: Must NOT be treated as generic transfer
      expect(result!.transactionType, equals('TRAFFIC_FINE'));
      expect(result.direction, equals(TransactionDirection.outDir));
      expect(result.amount, equals(100.0));
      expect(result.fee, equals(0.0));
      expect(result.totalDebit, equals(100.0));
      expect(result.referenceNumber, equals('TRF 48100009799845'));
      expect(result.category, equals('Government'));
      expect(result.subcategory, equals('Traffic Fine'));
      expect(AccountExtractor.normalizeSuffix(result.sourceAccount), equals('2001'));
    });

    test('4. Fixture 4: Local Transfer with Fee (15.00 + 0.58 = 15.58 SAR)', () {
      const sms = 'حوالة محلية\nالمصرف RJHI\nالمبلغ SAR 15\nمن X2001\nالى: عبدالعزيز محمد القحط\nالى X6980\nالرسوم SAR 0.58\nفي 09-08 21:20';

      final result = parser.parse(sms, sender: 'AlRajhiBank');

      expect(result, isNotNull);
      expect(result!.transactionType, equals('LOCAL_TRANSFER'));
      expect(result.direction, equals(TransactionDirection.outDir));
      expect(result.amount, equals(15.0));
      expect(result.fee, equals(0.58));
      expect(result.totalDebit, equals(15.58));
      expect(result.recipientName, equals('عبدالعزيز محمد القحط'));
      expect(result.destinationBank, equals('RJHI'));
      expect(AccountExtractor.normalizeSuffix(result.sourceAccount), equals('2001'));
      expect(AccountExtractor.normalizeSuffix(result.destinationAccount), equals('6980'));
    });

    test('5. Fixture 5: POS Purchase Mathaq (11.05 SAR - Samsung Pay)', () {
      const sms = 'شراء POS\nبSAR 11.05\nمن MATHAQ A\nمدى سامسونج X3232';

      final result = parser.parse(sms, sender: 'Alinma');

      expect(result, isNotNull);
      expect(result!.transactionType, equals('POS_PURCHASE'));
      expect(result.direction, equals(TransactionDirection.outDir));
      expect(result.amount, equals(11.05));
      expect(result.fee, equals(0.0));
      expect(result.totalDebit, equals(11.05));
      expect(result.merchant, equals('MATHAQ A'));
      expect(result.normalizedMerchant, equals('MATHAQ'));
      expect(result.paymentMethod, equals('MADA_SAMSUNG_PAY'));
      expect(result.cardLast4, equals('3232'));
    });

    test('6. Structured JSON Output conforms to Section 17 format', () {
      const sms = 'سداد فاتورة\nمن: XXX2001\nالمبلغ: SAR 171.35\nمفوتر: 044 زين\nخدمة:الاتصالات والانترنت\nرقم الفاتورة: 831032470841\nفي: 08-26 00:34';

      final result = parser.parse(sms)!;
      final structured = result.toStructuredJson();

      expect(structured['schemaVersion'], equals('1.0'));
      expect(structured['messageType'], equals('FINANCIAL_TRANSACTION'));

      final tx = structured['transaction'] as Map<String, dynamic>;
      expect(tx['type'], equals('BILL_PAYMENT'));
      expect(tx['direction'], equals('OUT'));
      expect(tx['amount'], equals(171.35));
      expect(tx['fee'], equals(0.0));
      expect(tx['totalDebit'], equals(171.35));
      expect(tx['currency'], equals('SAR'));

      final bankMeta = structured['bankMetadata'] as Map<String, dynamic>;
      expect(bankMeta['billerCode'], equals('044'));
      expect(bankMeta['biller'], equals('زين'));
      expect(bankMeta['billNumber'], equals('831032470841'));
    });

    test('7. Duplicate detection generates identical message hashes for identical SMS', () {
      const sms = 'شراء POS\nبSAR 11.05\nمن MATHAQ A\nمدى سامسونج X3232';

      final res1 = parser.parse(sms)!;
      final res2 = parser.parse(sms)!;

      expect(res1.messageHash, equals(res2.messageHash));
      expect(res1.messageHash, isNotEmpty);
    });

    test('8. Strict rejection of OTP and Marketing ensures zero balance effect', () {
      const otp = 'رمز التحقق (OTP) للدخول هو: 984120. لا تشارك هذا الرمز.';
      expect(MessageClassifier.isEligibleForParsing(otp), isFalse);
      expect(BankMessageParserFactory.parse(otp), isNull);

      const promo = 'عرض خاص! احصل على تمويل شخصي بهامش ربح يبدأ من 1.99%.';
      expect(MessageClassifier.isEligibleForParsing(promo), isFalse);
      expect(BankMessageParserFactory.parse(promo), isNull);
    });
  });
}