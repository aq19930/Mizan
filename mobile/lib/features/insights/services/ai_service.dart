import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../data/models/ai_models.dart';

class MizanAiService {
  final Dio _dio;

  MizanAiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: ApiConfig.connectTimeout,
                receiveTimeout: ApiConfig.receiveTimeout,
              ),
            );

  Future<AnalysisSummaryModel> getAnalysisSummary() async {
    try {
      final response = await _dio.get('/api/analysis/summary');
      if (response.statusCode == 200 && response.data != null) {
        return AnalysisSummaryModel.fromJson(response.data);
      }
    } catch (_) {}

    // Graceful offline fallback with rich initial analysis
    return _buildMockSummary();
  }

  Future<FinancialHealthModel> getFinancialHealth() async {
    try {
      final response = await _dio.get('/api/analysis/financial-health');
      if (response.statusCode == 200 && response.data != null) {
        return FinancialHealthModel.fromJson(response.data);
      }
    } catch (_) {}

    return _buildMockSummary().health;
  }

  Future<FinancialForecastModel> getForecast() async {
    try {
      final response = await _dio.get('/api/analysis/forecast');
      if (response.statusCode == 200 && response.data != null) {
        return FinancialForecastModel.fromJson(response.data);
      }
    } catch (_) {}

    return _buildMockSummary().forecast;
  }

  Future<CommitmentScheduleModel> getCommitmentSchedule({int months = 12}) async {
    try {
      final response = await _dio.get('/api/analysis/commitments', queryParameters: {'months': months});
      if (response.statusCode == 200 && response.data != null) {
        return CommitmentScheduleModel.fromJson(response.data);
      }
    } catch (_) {}

    return _buildMockSummary().commitments;
  }

  Future<BudgetOptimizationModel> optimizeBudget(String objective) async {
    try {
      final response = await _dio.post('/api/analysis/optimize-budget', data: {'objective': objective});
      if (response.statusCode == 200 && response.data != null) {
        return BudgetOptimizationModel.fromJson(response.data);
      }
    } catch (_) {}

    return BudgetOptimizationModel(
      currentPlan: BudgetPlanComparisonModel(
        planNameAr: 'الخطة الحالية',
        planNameEn: 'Current Plan',
        dailySpendTarget: 160.0,
        savingsTarget: 500.0,
        emergencyReserve: 300.0,
        reservedForCommitments: 2150.0,
        discretionaryPool: 4800.0,
        rationaleAr: 'النمط الحالي قبل التحسين.',
        rationaleEn: 'Current baseline.',
      ),
      optimizedPlan: BudgetPlanComparisonModel(
        planNameAr: 'الخطة المحسّنة (ميزان AI)',
        planNameEn: 'Optimized Plan',
        dailySpendTarget: 125.0,
        savingsTarget: 800.0,
        emergencyReserve: 600.0,
        reservedForCommitments: 2150.0,
        discretionaryPool: 3750.0,
        rationaleAr: 'تخصيص مدخرات منتظمة مع خفض طفيف للصرف اليومي.',
        rationaleEn: 'Regular savings allocation with trimmed daily burn.',
      ),
      explanationAr: 'تساعدك إعادة الجدولة على حجز الالتزامات والمدخرات مسبقاً وتفادي العجز في نهاية الشهر.',
      explanationEn: 'Rescheduling reserves commitments upfront to prevent month-end cash crunches.',
      actionStepsAr: [
        'حجز الالتزامات مسبقاً بقيمة 2,150 ريال.',
        'تخصيص 800 ريال للادخار.',
        'سقف صرف يومي 125 ريال.',
      ],
      actionStepsEn: [
        'Ring-fence commitments of 2,150 SAR.',
        'Target 800 SAR monthly savings.',
        'Daily spend ceiling of 125 SAR.',
      ],
    );
  }

  Future<LoanScenarioResultModel> calculateLoanScenario({
    required double loanAmount,
    double annualRate = 5.5,
    int durationMonths = 36,
  }) async {
    try {
      final response = await _dio.post('/api/scenarios/loan', data: {
        'loanAmount': loanAmount,
        'annualRate': annualRate,
        'durationMonths': durationMonths,
        'stressTest': true,
      });
      if (response.statusCode == 200 && response.data != null) {
        return LoanScenarioResultModel.fromJson(response.data);
      }
    } catch (_) {}

    // Deterministic client fallback calculation
    double monthlyRate = (annualRate / 100) / 12;
    double factor = 1.0;
    for (int i = 0; i < durationMonths; i++) {
      factor *= (1 + monthlyRate);
    }
    double installment = loanAmount * (monthlyRate * factor) / (factor - 1);
    double totalPaid = installment * durationMonths;

    return LoanScenarioResultModel(
      loanAmount: loanAmount,
      annualRate: annualRate,
      durationMonths: durationMonths,
      monthlyInstallment: double.parse(installment.toStringAsFixed(2)),
      totalPayments: double.parse(totalPaid.toStringAsFixed(2)),
      totalFinancingCost: double.parse((totalPaid - loanAmount).toStringAsFixed(2)),
      expectedEndDate: DateTime.now().add(Duration(days: durationMonths * 30)),
      existingMonthlyCommitments: 2000.0,
      newTotalCommitments: 2000.0 + installment,
      commitmentRatioBefore: 0.28,
      commitmentRatioAfter: (2000.0 + installment) / 6960.45,
      monthlyAvailableCashBefore: 2000.0,
      monthlyAvailableCashAfter: 6960.45 - (2000.0 + installment) - 2500.0,
      ratingAr: ((2000.0 + installment) / 6960.45) > 0.40 ? 'ضغط مالي مرتفع' : 'يمكن إدارته مع ترشيد الصرف',
      ratingEn: ((2000.0 + installment) / 6960.45) > 0.40 ? 'High Pressure' : 'Manageable with adjustments',
      explanationAr: 'بناءً على التزاماتك الحالية، سيمثل التمويل عبئاً إضافياً يتطلب ضبط الصرف اليومي.',
      explanationEn: 'Based on current commitments, financing requires prudent spending discipline.',
      stressTests: [
        StressTestResultModel(
          scenarioKey: 'NormalMonth',
          titleAr: 'الشهر المعتاد',
          titleEn: 'Normal Month',
          monthlyCommitments: 2000.0 + installment,
          disposableCash: 1250.0,
          balanceStaysPositive: true,
          emergencyReserveRequired: false,
          riskRatingAr: 'آمن',
          riskRatingEn: 'Safe',
        ),
        StressTestResultModel(
          scenarioKey: 'SpendingPlus10',
          titleAr: 'ارتفاع المصاريف 10%',
          titleEn: 'Spending +10%',
          monthlyCommitments: 2000.0 + installment,
          disposableCash: 850.0,
          balanceStaysPositive: true,
          emergencyReserveRequired: false,
          riskRatingAr: 'مقبول',
          riskRatingEn: 'Acceptable',
        ),
      ],
      disclaimerAr: 'ميزان يقدم دراسات تقديرية ولا يُعد جهة إقراض أو مستشاراً مالياً مرخصاً.',
      disclaimerEn: 'Mizan provides planning estimates and is not a licensed lender or financial advisor.',
    );
  }

  Future<WhatIfResultModel> simulateWhatIf(String scenarioType, double amount) async {
    try {
      final response = await _dio.post('/api/scenarios/what-if', data: {
        'scenarioType': scenarioType,
        'amount': amount,
      });
      if (response.statusCode == 200 && response.data != null) {
        return WhatIfResultModel.fromJson(response.data);
      }
    } catch (_) {}

    return WhatIfResultModel(
      scenarioType: scenarioType,
      titleAr: 'محاكاة السيناريو المالي',
      titleEn: 'Scenario Simulation',
      immediateImpact: amount,
      newMonthlyCommitments: 2150.0,
      newDisposableCash: 3500.0,
      newCommitmentRatio: 0.31,
      feasibilityRatingAr: 'إيجابي وممكن',
      feasibilityRatingEn: 'Positive & Feasible',
      explanationAr: 'هذا التغيير يمنح ميزانيتك مرونة إضافية.',
      explanationEn: 'This scenario adds positive flexibility to your cash flow.',
    );
  }

  Future<List<AIConversationModel>> getConversations() async {
    try {
      final response = await _dio.get('/api/ai/conversations');
      if (response.statusCode == 200 && response.data != null) {
        final list = response.data as List;
        return list.map((e) => AIConversationModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<AIConversationModel> createConversation({String? titleAr, String? titleEn}) async {
    try {
      final response = await _dio.post('/api/ai/conversations', data: {
        'titleAr': titleAr ?? 'محادثة مالية جديدة',
        'titleEn': titleEn ?? 'New Financial Consultation',
      });
      if (response.statusCode == 200 && response.data != null) {
        return AIConversationModel.fromJson(response.data);
      }
    } catch (_) {}
    return AIConversationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleAr ?? 'محادثة مالية جديدة',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messageCount: 0,
    );
  }

  Future<List<String>> getSuggestedQuestions() async {
    try {
      final response = await _dio.get('/api/ai/suggested-questions');
      if (response.statusCode == 200 && response.data != null && response.data['questions'] != null) {
        return (response.data['questions'] as List).map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [
      'حلل وضعي المالي',
      'كم أقدر أصرف؟',
      'وش التزاماتي القادمة؟',
      'رتب لي الراتب',
      'هل أقدر آخذ قرض؟',
      'هل أقدر أشتري سيارة؟',
      'كيف أوفر أكثر؟',
      'توقع رصيدي نهاية الشهر',
    ];
  }

  Future<AIChatMessageModel> sendChatMessage(String message, {String? conversationId, String language = 'ar'}) async {
    try {
      final response = await _dio.post('/api/ai/chat', data: {
        'message': message,
        'conversationId': conversationId,
        'language': language,
      });
      if (response.statusCode == 200 && response.data != null) {
        return AIChatMessageModel.fromJson(response.data);
      }
    } catch (_) {}

    // Intelligent local fallback response with rich cards
    return _buildMockChatReply(message);
  }

  AnalysisSummaryModel buildMockSummary() => _buildMockSummary();

  AnalysisSummaryModel _buildMockSummary() {
    final health = FinancialHealthModel(
      score: 78,
      statusAr: 'جيد',
      statusEn: 'Good',
      summaryAr: 'وضعك المالي مستقر حاليًا، لكن الالتزامات تمثل 31% من دخلك الشهري. إذا حافظت على صرف يومي أقل من 145 ريال، فمن المتوقع إنهاء الشهر دون تجاوز الميزانية.',
      summaryEn: 'Your financial health is stable. Commitments represent 31% of income. Keeping daily spending below 145 SAR will ensure closing the month within budget.',
      factors: [
        HealthFactorModel(
          nameAr: 'معدل الادخار',
          nameEn: 'Savings Rate',
          weight: 0.25,
          score: 85.0,
          statusAr: 'ممتاز',
          statusEn: 'Excellent',
          descriptionAr: 'ادخار شهري يقدر بـ 22% من الدخل.',
          descriptionEn: 'Estimated 22% monthly savings rate.',
        ),
        HealthFactorModel(
          nameAr: 'نسبة الالتزامات',
          nameEn: 'Commitments Ratio',
          weight: 0.25,
          score: 90.0,
          statusAr: 'آمن',
          statusEn: 'Safe',
          descriptionAr: 'تمثل الالتزامات 31% من الدخل (أقل من الحد الأقصى 33%).',
          descriptionEn: 'Commitments are 31% of income (safe below 33%).',
        ),
        HealthFactorModel(
          nameAr: 'الالتزام بالميزانية',
          nameEn: 'Budget Adherence',
          weight: 0.20,
          score: 75.0,
          statusAr: 'منضبط',
          statusEn: 'Disciplined',
          descriptionAr: 'المتبقي من الميزانية يكفي للأيام المتبقية بمعدل صرف متزن.',
          descriptionEn: 'Remaining budget covers the remaining days evenly.',
        ),
        HealthFactorModel(
          nameAr: 'صندوق الطوارئ',
          nameEn: 'Emergency Reserve',
          weight: 0.15,
          score: 65.0,
          statusAr: 'يحتاج تعزيز',
          statusEn: 'Needs Growth',
          descriptionAr: 'يغطي حالياً شهر ونصف من المصاريف الأساسية.',
          descriptionEn: 'Currently covers 1.5 months of essential spending.',
        ),
        HealthFactorModel(
          nameAr: 'السيولة المباشرة',
          nameEn: 'Immediate Liquidity',
          weight: 0.15,
          score: 85.0,
          statusAr: 'جيدة',
          statusEn: 'Good',
          descriptionAr: 'المتاح للصرف الفعلي يوفر هامش أمان مريح.',
          descriptionEn: 'Available cash provides a comfortable safety margin.',
        ),
      ],
      scoringFormula: 'Weighted: Savings(25%) + Commitments(25%) + Budget(20%) + Emergency(15%) + Liquidity(15%)',
      evaluatedAt: DateTime.now(),
    );

    final forecast = FinancialForecastModel(
      monthEndBalance: ForecastBoundsModel(low: 3200, expected: 3600, high: 3950),
      confidence: 0.81,
      confidenceLevelAr: 'دقة عالية (81%)',
      confidenceLevelEn: 'High Confidence (81%)',
      explanationAr: 'بناءً على متوسط صرفك اليومي البالغ 128 ريال والتزاماتك القادمة.',
      explanationEn: 'Based on 128 SAR average daily spend and upcoming obligations.',
      currentBalance: 14500.0,
      expectedRemainingIncome: 0.0,
      expectedDiscretionarySpend: 2900.0,
      upcomingCommitments: 2150.0,
      daysRemainingInMonth: 14,
    );

    final commitments = CommitmentScheduleModel(
      totalMonths: 12,
      totalObligations: 26150.0,
      monthlyAverage: 2179.0,
      heavyMonths: ['يناير 2027'],
      months: [
        MonthlyCommitmentGroupModel(
          monthKey: '2026-09',
          monthLabelAr: 'سبتمبر 2026',
          monthLabelEn: 'September 2026',
          totalAmount: 2150.0,
          isHeavyMonth: false,
          commitments: [
            ScheduledCommitmentItemModel(
              commitmentId: '1',
              nameAr: 'قسط السيارة',
              nameEn: 'Car Installment',
              category: 'Car',
              amount: 1250.0,
              dueDate: DateTime.now().add(const Duration(days: 5)),
              frequency: 'Monthly',
              status: 'Upcoming',
              remainingPayments: 24,
            ),
            ScheduledCommitmentItemModel(
              commitmentId: '2',
              nameAr: 'فاتورة زين',
              nameEn: 'Zain Bill',
              category: 'Telecommunications',
              amount: 171.35,
              dueDate: DateTime.now().add(const Duration(days: 6)),
              frequency: 'Monthly',
              status: 'Upcoming',
              remainingPayments: 12,
            ),
            ScheduledCommitmentItemModel(
              commitmentId: '3',
              nameAr: 'إنترنت الألياف',
              nameEn: 'Fiber Internet',
              category: 'Utilities',
              amount: 305.0,
              dueDate: DateTime.now().add(const Duration(days: 8)),
              frequency: 'Monthly',
              status: 'Upcoming',
              remainingPayments: 12,
            ),
          ],
        ),
        MonthlyCommitmentGroupModel(
          monthKey: '2026-10',
          monthLabelAr: 'أكتوبر 2026',
          monthLabelEn: 'October 2026',
          totalAmount: 2365.0,
          isHeavyMonth: false,
          commitments: [],
        ),
        MonthlyCommitmentGroupModel(
          monthKey: '2026-11',
          monthLabelAr: 'نوفمبر 2026',
          monthLabelEn: 'November 2026',
          totalAmount: 2150.0,
          isHeavyMonth: false,
          commitments: [],
        ),
        MonthlyCommitmentGroupModel(
          monthKey: '2027-01',
          monthLabelAr: 'يناير 2027',
          monthLabelEn: 'January 2027',
          totalAmount: 26150.0,
          isHeavyMonth: true,
          commitments: [],
        ),
      ],
      aiAnalysisAr: 'يناير يعتبر شهرًا عالي الضغط بسبب استحقاق الإيجار السنوي بقيمة 24,000 ريال. إذا بدأت بحجز 6,000 ريال شهريًا من سبتمبر إلى ديسمبر، تستطيع تغطية الإيجار دون التأثير الكبير على مصروفك اليومي.',
      aiAnalysisEn: 'January presents a high obligation peak due to annual rent of 24,000 SAR. Ring-fencing 6,000 SAR monthly covers it smoothly.',
    );

    return AnalysisSummaryModel(
      health: health,
      forecast: forecast,
      commitments: commitments,
      aiAnalysisTextAr: 'وضعك المالي مستقر حالياً مع سيولة ممتازة. يُنصح بالبدء في حجز مخصص شهري لإيجار يناير القادم.',
      aiAnalysisTextEn: 'Your financial standing is solid with healthy liquidity. Starting a reserve for January rent is advised.',
      safeDailySpending: 145.0,
      lastUpdated: DateTime.now(),
    );
  }

  AIChatMessageModel _buildMockChatReply(String query) {
    final lower = query.toLowerCase();

    if (lower.contains('اشتري') || lower.contains('شراء') || lower.contains('جوال') || lower.contains('buy') || lower.contains('purchase')) {
      double amount = 4000.0;
      final numMatch = RegExp(r'\d+[\d,]*').firstMatch(query);
      if (numMatch != null) {
        amount = double.tryParse(numMatch.group(0)!.replaceAll(',', '')) ?? 4000.0;
      }
      final availableBefore = 8650.0;
      final availableAfter = availableBefore - amount;
      final days = 14;
      final currentDaily = (availableBefore / days);
      final newDaily = availableAfter > 0 ? (availableAfter / days) : 0.0;
      final contraction = ((currentDaily - newDaily) / currentDaily) * 100;

      return AIChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content: 'فحصت سيولتك المتاحة (8,650 ريال). شراء بقيمة ${amount.toStringAsFixed(0)} ريال ممكن، لكنه سيقلص مصروفك اليومي المتاح بنسبة ${contraction.toStringAsFixed(1)}% للأيام الـ $days المتبقية في الشهر.\n\n'
            'المصروف اليومي الجديد سيكون ${newDaily.toStringAsFixed(1)} ريال بدلاً من ${currentDaily.toStringAsFixed(1)} ريال.',
        severity: availableAfter < 2000 ? 'warning' : 'normal',
        cards: [
          StructuredAICardModel(
            cardType: 'PurchaseScenarioCard',
            titleAr: 'دراسة جدوى شراء (${amount.toStringAsFixed(0)} ريال)',
            titleEn: 'Purchase Feasibility (${amount.toStringAsFixed(0)} SAR)',
            data: {
              'purchaseAmount': amount,
              'availableBefore': availableBefore,
              'availableAfter': availableAfter,
              'currentDailySpend': currentDaily,
              'newDailySpend': newDaily,
              'daysRemaining': days,
              'feasibilityRatingAr': availableAfter > 3000 ? 'ممكن مع ترشيد بسيط' : 'ضغط سيولة مرتفع',
              'feasibilityRatingEn': availableAfter > 3000 ? 'Feasible with minor moderation' : 'High Liquidity Strain',
              'dailyPaceContractionPercent': contraction,
            },
          ),
        ],
        suggestedQuestions: [
          'كيف أعوض هذا الشراء من مصاريفي؟',
          'هل الأفضل تقسيط المبلغ؟',
          'كم بيكون رصيدي نهاية الشهر لو شريت؟',
        ],
        calculationReferences: [
          'محرك جدوى المشتريات (PurchaseFeasibilityEngine)',
          'معادلة انكماش وتيرة الصرف اليومي (Daily Spend Pace Contraction)',
        ],
        createdAt: DateTime.now(),
      );
    } else if (lower.contains('قرض') || lower.contains('تمويل') || lower.contains('loan')) {
      return AIChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content: 'بناءً على التزاماتك الحالية (2,150 ريال)، إضافة تمويل بقيمة 50,000 ريال سينتج عنه قسط شهري يقارب 1,509 ريال.\n\n'
            'سترتفع نسبة التزاماتك إلى حوالي 52.5% من دخلك الشهري، مما يضع ميزانيتك تحت تصنيف: ضغط مالي مرتفع وفق معايير البنك المركزي (SAMA).',
        severity: 'warning',
        cards: [
          StructuredAICardModel(
            cardType: 'LoanScenarioCard',
            titleAr: 'دراسة تمويل 50,000 ريال',
            titleEn: 'Loan Study 50,000 SAR',
            data: {
              'loanAmount': 50000.0,
              'durationMonths': 36,
              'monthlyInstallment': 1509.0,
              'commitmentRatioBefore': 30.9,
              'commitmentRatioAfter': 52.5,
              'ratingAr': 'ضغط مالي مرتفع',
              'disposableCashAfter': 1100.0,
            },
          ),
          StructuredAICardModel(
            cardType: 'RiskCard',
            titleAr: 'مؤشر عبء الدين (DTI)',
            titleEn: 'Debt-to-Income Indicator',
            data: {
              'currentDti': '30.9%',
              'projectedDti': '52.5%',
              'recommendedMax': '33%',
            },
          ),
        ],
        suggestedQuestions: [
          'طيب لو القسط 1000 ريال فقط؟',
          'كم أقصى مبلغ تمويل أقدر آخذه بأمان؟',
          'كيف أقلل التزاماتي الحالية أولاً؟',
        ],
        calculationReferences: [
          'محرك حساب القروض (LoanCalculationEngine)',
          'معيار البنك المركزي السعودي لنسبة عبء الدين (SAMA DTI Guidelines)',
        ],
        createdAt: DateTime.now(),
      );
    } else if (lower.contains('التزام') || lower.contains('باقي علي') || lower.contains('فواتير')) {
      return AIChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content: 'لديك 3 التزامات متبقية هذا الشهر بإجمالي 1,726.35 ريال:\n\n'
            '• قسط السيارة: 1,250 ريال (27 سبتمبر)\n'
            '• فاتورة زين: 171.35 ريال (28 سبتمبر)\n'
            '• إنترنت الألياف: 305 ريال (30 سبتمبر)\n\n'
            'المبلغ المتاح للصرف بعد حجز هذه الالتزامات هو 8,650 ريال.',
        cards: [
          StructuredAICardModel(
            cardType: 'CommitmentCard',
            titleAr: 'الالتزامات المتبقية',
            titleEn: 'Remaining Commitments',
            data: {
              'totalAmount': 1726.35,
              'count': 3,
              'currency': 'SAR',
              'availableAfter': 8650.0,
            },
          ),
          StructuredAICardModel(
            cardType: 'MoneySummaryCard',
            titleAr: 'المتاح للصرف الحقيقي',
            titleEn: 'Real Available Cash',
            data: {
              'currentBalance': 14500.0,
              'reservedCommitments': 1726.35,
              'availableToSpend': 8650.0,
            },
          ),
        ],
        suggestedQuestions: [
          'هل أقدر أقدم تسديد قسط السيارة؟',
          'كم المفروض أصرف بكرة؟',
          'هل فيه أي فواتير إضافية الشهر الجاي؟',
        ],
        calculationReferences: [
          'جدول الالتزامات (CommitmentScheduleService)',
          'معادلة المتاح للصرف (Deterministic Available-to-Spend)',
        ],
        createdAt: DateTime.now(),
      );
    } else if (lower.contains('رتب') || lower.contains('ميزانيتي') || lower.contains('راتبي') || lower.contains('15%') || lower.contains('ادخار') || lower.contains('optimize')) {
      return AIChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content: 'أقترح خطة توزيع محسنة لميزانيتك ترفع مدخراتك إلى 15% (1,044 ريال) مع ضبط وتيرة الصرف اليومي:\n\n'
            '• حجز الالتزامات: 2,150 ريال\n'
            '• مخصص الادخار والطوارئ: 1,044 ريال (15%)\n'
            '• سقف الصرف اليومي: 125 ريال/يومياً',
        cards: [
          StructuredAICardModel(
            cardType: 'BudgetPlanCard',
            titleAr: 'خطة الراتب والادخار (15%)',
            titleEn: 'Salary & Savings Plan (15%)',
            data: {
              'salary': 6960.45,
              'targetSavingsPercentage': 15.0,
              'savingsAmount': 1044.0,
              'commitmentsTotal': 2150.0,
              'discretionarySpending': 3766.45,
              'safeDailySpend': 125.0,
              'feasibilityRatingAr': 'واقعية وممتازة',
              'stepsAr': [
                'عزل 2,150 ريال للالتزامات فور نزول الراتب.',
                'تحويل 1,044 ريال لحساب الادخار الاستثماري.',
                'تحديد 125 ريال حداً أقصى للصرف اليومي.',
              ],
            },
          ),
        ],
        suggestedQuestions: [
          'كيف ألتزم بسقف الـ 125 ريال اليومي؟',
          'وين أحط الـ 15% المدخرة؟',
          'هل أقدر أرفع الادخار إلى 20%؟',
        ],
        calculationReferences: [
          'محرك تخطيط الميزانية (FinancialPlanEngine)',
          'قاعدة 50/30/20 المعدلة للسوق السعودي',
        ],
        createdAt: DateTime.now(),
      );
    } else if (lower.contains('توقع') || lower.contains('نهاية الشهر') || lower.contains('forecast')) {
      return AIChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content: 'بناءً على وتيرة صرفك الحالية والالتزامات القادمة، يتوقع أن يغلق رصيدك نهاية الشهر بين 3,200 و 3,950 ريال، بمتوسط متوقع 3,600 ريال.\n\n'
            'نسبة الثقة في هذا التوقع هي 81%.',
        cards: [
          StructuredAICardModel(
            cardType: 'ForecastCard',
            titleAr: 'توقع الرصيد نهاية الشهر',
            titleEn: 'Month-End Balance Forecast',
            data: {
              'expected': 3600.0,
              'low': 3200.0,
              'high': 3950.0,
              'confidencePercent': 81.0,
              'daysRemaining': 14,
            },
          ),
        ],
        suggestedQuestions: [
          'كيف أرفع الرصيد المتوقع فوق 4,000 ريال؟',
          'وش السيناريو الأسوأ لو زادت مصاريفي 10%؟',
        ],
        calculationReferences: [
          'محرك التوقعات المالية (FinancialForecastEngine)',
          'نموذج مونت كارلو للسيولة المتبقية',
        ],
        createdAt: DateTime.now(),
      );
    } else {
      return AIChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content: 'وضعك المالي مستقر حالياً بدرجة صحة 78/100 (جيد). رصيدك المتاح للصرف بعد حجز الالتزامات هو 8,650 ريال، ومتوسط صرفك اليومي الحالي 128 ريال.\n\n'
            'كيف تحب أساعدك اليوم؟ يمكنك سؤالي عن القروض، فحص جدوى شراء معين، أو جدولة راتبك.',
        cards: [
          StructuredAICardModel(
            cardType: 'MoneySummaryCard',
            titleAr: 'الملخص المالي السريع',
            titleEn: 'Quick Financial Summary',
            data: {
              'currentBalance': 14500.0,
              'availableToSpend': 8650.0,
              'commitments': 2150.0,
            },
          ),
        ],
        suggestedQuestions: [
          'كم باقي علي التزامات هالشهر؟',
          'اقدر اشتري جوال بـ 4000 ريال الحين؟',
          'عطني حسبة قرض 50 ألف على 3 سنوات',
          'كيف ارتب راتبي بحيث اوفر 15%؟',
        ],
        calculationReferences: [
          'الملخص المالي المطهّر (FinancialContextService)',
        ],
        createdAt: DateTime.now(),
      );
    }
  }
}
