import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/insights/data/models/ai_models.dart';
import 'package:mobile/features/insights/presentation/ai_chat_bottom_sheet.dart';
import 'package:mobile/features/insights/presentation/ai_providers.dart';
import 'package:mobile/features/insights/presentation/insights_screen.dart';
import 'package:mobile/features/insights/presentation/widgets/floating_ai_button.dart';
import 'package:mobile/features/insights/services/ai_service.dart';
import 'package:mobile/l10n/app_localizations.dart';

void main() {
  group('MIZAN AI Models & DTO Tests', () {
    test('FinancialHealthModel deserializes accurately from JSON', () {
      final json = {
        'score': 82,
        'statusAr': 'جيد',
        'statusEn': 'Good',
        'summaryAr': 'وضعك المالي مستقر.',
        'summaryEn': 'Your financial status is stable.',
        'factors': [
          {
            'nameAr': 'معدل الادخار',
            'nameEn': 'Savings Rate',
            'weight': 0.25,
            'score': 85.0,
            'statusAr': 'ممتاز',
            'statusEn': 'Excellent',
            'descriptionAr': 'ادخار شهري 20%',
            'descriptionEn': '20% monthly savings',
          }
        ],
        'scoringFormula': 'Weighted Algorithm',
        'evaluatedAt': DateTime.now().toIso8601String(),
      };

      final model = FinancialHealthModel.fromJson(json);
      expect(model.score, equals(82));
      expect(model.statusAr, equals('جيد'));
      expect(model.factors.length, equals(1));
      expect(model.factors.first.weight, equals(0.25));
      expect(model.factors.first.score, equals(85.0));
    });

    test('LoanScenarioResultModel deserializes with stress tests and ratings', () {
      final json = {
        'loanAmount': 50000.0,
        'annualRate': 5.5,
        'durationMonths': 36,
        'monthlyInstallment': 1509.0,
        'totalPayments': 54324.0,
        'totalFinancingCost': 4324.0,
        'expectedEndDate': DateTime.now().add(const Duration(days: 1095)).toIso8601String(),
        'existingMonthlyCommitments': 2000.0,
        'newTotalCommitments': 3509.0,
        'commitmentRatioBefore': 0.28,
        'commitmentRatioAfter': 0.504,
        'monthlyAvailableCashBefore': 2460.0,
        'monthlyAvailableCashAfter': 951.0,
        'ratingAr': 'ضغط مالي مرتفع',
        'ratingEn': 'High Pressure',
        'explanationAr': 'سيرتفع عبء الالتزام إلى 50.4%.',
        'explanationEn': 'Commitment ratio will reach 50.4%.',
        'stressTests': [
          {
            'scenarioKey': 'SpendingPlus10',
            'titleAr': 'ارتفاع المصاريف 10%',
            'titleEn': 'Spending +10%',
            'monthlyCommitments': 3509.0,
            'disposableCash': 700.0,
            'balanceStaysPositive': true,
            'emergencyReserveRequired': false,
            'riskRatingAr': 'مقبول',
            'riskRatingEn': 'Acceptable',
          }
        ],
        'disclaimerAr': 'ميزان يقدم دراسات تقديرية ولا يُعد جهة تمويل مرخصة.',
        'disclaimerEn': 'Mizan provides planning estimates and is not a licensed lender.',
      };

      final model = LoanScenarioResultModel.fromJson(json);
      expect(model.loanAmount, equals(50000.0));
      expect(model.durationMonths, equals(36));
      expect(model.monthlyInstallment, equals(1509.0));
      expect(model.ratingAr, equals('ضغط مالي مرتفع'));
      expect(model.stressTests.length, equals(1));
      expect(model.stressTests.first.scenarioKey, equals('SpendingPlus10'));
      expect(model.disclaimerAr, contains('دراسات تقديرية'));
    });

    test('BudgetOptimizationModel deserializes comparison plans correctly', () {
      final json = {
        'currentPlan': {
          'planNameAr': 'الخطة الحالية',
          'planNameEn': 'Current Plan',
          'dailySpendTarget': 160.0,
          'savingsTarget': 500.0,
          'emergencyReserve': 300.0,
          'reservedForCommitments': 2150.0,
          'discretionaryPool': 4800.0,
          'rationaleAr': 'النمط الحالي',
          'rationaleEn': 'Current pattern',
        },
        'optimizedPlan': {
          'planNameAr': 'الخطة المحسّنة',
          'planNameEn': 'Optimized Plan',
          'dailySpendTarget': 125.0,
          'savingsTarget': 800.0,
          'emergencyReserve': 600.0,
          'reservedForCommitments': 2150.0,
          'discretionaryPool': 3750.0,
          'rationaleAr': 'نمط محسن',
          'rationaleEn': 'Optimized pattern',
        },
        'explanationAr': 'شرح الخطة',
        'explanationEn': 'Plan explanation',
        'actionStepsAr': ['حجز الالتزامات'],
        'actionStepsEn': ['Ring-fence commitments'],
      };

      final model = BudgetOptimizationModel.fromJson(json);
      expect(model.currentPlan.dailySpendTarget, equals(160.0));
      expect(model.optimizedPlan.dailySpendTarget, equals(125.0));
      expect(model.optimizedPlan.savingsTarget, equals(800.0));
      expect(model.actionStepsAr.first, equals('حجز الالتزامات'));
    });
  });

  group('MIZAN AI Widgets & Presentation Tests', () {
    testWidgets('FloatingMizanAiButton renders with branding and icon', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            locale: Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: FloatingMizanAiButton(),
            ),
          ),
        ),
      );

      expect(find.text('مستشار ميزان'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('InsightsScreen renders 14 core sections including health score, forecast, and loan analyzer', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analysisSummaryProvider.overrideWith(
              (ref) => Future.value(MizanAiService().buildMockSummary()),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: InsightsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header & core sections
      expect(find.text('مؤشر الصحة المالية'), findsOneWidget);
      expect(find.text('التحليل المالي الذكي'), findsWidgets);
      expect(find.text('السيولة المتاحة بعد حجز الالتزامات'), findsOneWidget);
      expect(find.text('توقع الرصيد بنهاية الشهر'), findsOneWidget);
      expect(find.text('مقارنة الدخل بالمصروفات'), findsOneWidget);
      expect(find.text('جدول الالتزامات المجدولة'), findsOneWidget);
      expect(find.text('الجدول الزمني للالتزامات'), findsOneWidget);
      expect(find.text('سقف الصرف اليومي الآمن'), findsOneWidget);
      expect(find.text('محلل القروض والتمويل'), findsOneWidget);
      expect(find.text('مختبر "ماذا لو؟" التفاعلي'), findsOneWidget);
      expect(find.textContaining('إخلاء مسؤولية: ميزان يقدم دراسات'), findsOneWidget);
    });

    testWidgets('MizanAiChatBottomSheet renders suggested prompts and greeting', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            locale: Locale('ar'),
            home: Scaffold(
              body: MizanAiChatBottomSheet(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('مساعد ميزان'), findsOneWidget);
      expect(find.text('كيف وضعي المالي هذا الشهر؟'), findsOneWidget);
      expect(find.text('كم أقدر أصرف يوميًا؟'), findsOneWidget);
      expect(find.text('ما الالتزامات القادمة؟'), findsOneWidget);
      expect(find.text('وش ودك تعرف عن وضعك المالي؟'), findsOneWidget);
    });
  });
}
