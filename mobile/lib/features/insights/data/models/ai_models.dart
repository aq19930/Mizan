class HealthFactorModel {
  final String nameAr;
  final String nameEn;
  final double weight;
  final double score;
  final String statusAr;
  final String statusEn;
  final String descriptionAr;
  final String descriptionEn;

  HealthFactorModel({
    required this.nameAr,
    required this.nameEn,
    required this.weight,
    required this.score,
    required this.statusAr,
    required this.statusEn,
    required this.descriptionAr,
    required this.descriptionEn,
  });

  factory HealthFactorModel.fromJson(Map<String, dynamic> json) {
    return HealthFactorModel(
      nameAr: json['nameAr'] ?? '',
      nameEn: json['nameEn'] ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.2,
      score: (json['score'] as num?)?.toDouble() ?? 75.0,
      statusAr: json['statusAr'] ?? '',
      statusEn: json['statusEn'] ?? '',
      descriptionAr: json['descriptionAr'] ?? '',
      descriptionEn: json['descriptionEn'] ?? '',
    );
  }
}

class FinancialHealthModel {
  final int score;
  final String statusAr;
  final String statusEn;
  final String summaryAr;
  final String summaryEn;
  final List<HealthFactorModel> factors;
  final String scoringFormula;
  final DateTime evaluatedAt;

  FinancialHealthModel({
    required this.score,
    required this.statusAr,
    required this.statusEn,
    required this.summaryAr,
    required this.summaryEn,
    required this.factors,
    required this.scoringFormula,
    required this.evaluatedAt,
  });

  factory FinancialHealthModel.fromJson(Map<String, dynamic> json) {
    return FinancialHealthModel(
      score: json['score'] ?? 78,
      statusAr: json['statusAr'] ?? 'جيد',
      statusEn: json['statusEn'] ?? 'Good',
      summaryAr: json['summaryAr'] ?? '',
      summaryEn: json['summaryEn'] ?? '',
      factors: (json['factors'] as List?)
              ?.map((e) => HealthFactorModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      scoringFormula: json['scoringFormula'] ?? '',
      evaluatedAt: DateTime.tryParse(json['evaluatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class ForecastBoundsModel {
  final double low;
  final double expected;
  final double high;

  ForecastBoundsModel({
    required this.low,
    required this.expected,
    required this.high,
  });

  factory ForecastBoundsModel.fromJson(Map<String, dynamic> json) {
    return ForecastBoundsModel(
      low: (json['low'] as num?)?.toDouble() ?? 3200.0,
      expected: (json['expected'] as num?)?.toDouble() ?? 3600.0,
      high: (json['high'] as num?)?.toDouble() ?? 3950.0,
    );
  }
}

class FinancialForecastModel {
  final ForecastBoundsModel monthEndBalance;
  final double confidence;
  final String confidenceLevelAr;
  final String confidenceLevelEn;
  final String explanationAr;
  final String explanationEn;
  final double currentBalance;
  final double expectedRemainingIncome;
  final double expectedDiscretionarySpend;
  final double upcomingCommitments;
  final int daysRemainingInMonth;

  FinancialForecastModel({
    required this.monthEndBalance,
    required this.confidence,
    required this.confidenceLevelAr,
    required this.confidenceLevelEn,
    required this.explanationAr,
    required this.explanationEn,
    required this.currentBalance,
    required this.expectedRemainingIncome,
    required this.expectedDiscretionarySpend,
    required this.upcomingCommitments,
    required this.daysRemainingInMonth,
  });

  factory FinancialForecastModel.fromJson(Map<String, dynamic> json) {
    return FinancialForecastModel(
      monthEndBalance: json['monthEndBalance'] != null
          ? ForecastBoundsModel.fromJson(json['monthEndBalance'])
          : ForecastBoundsModel(low: 3200, expected: 3600, high: 3950),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.81,
      confidenceLevelAr: json['confidenceLevelAr'] ?? 'دقة عالية',
      confidenceLevelEn: json['confidenceLevelEn'] ?? 'High Confidence',
      explanationAr: json['explanationAr'] ?? '',
      explanationEn: json['explanationEn'] ?? '',
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 14500.0,
      expectedRemainingIncome: (json['expectedRemainingIncome'] as num?)?.toDouble() ?? 0.0,
      expectedDiscretionarySpend: (json['expectedDiscretionarySpend'] as num?)?.toDouble() ?? 2900.0,
      upcomingCommitments: (json['upcomingCommitments'] as num?)?.toDouble() ?? 2150.0,
      daysRemainingInMonth: json['daysRemainingInMonth'] ?? 14,
    );
  }
}

class ScheduledCommitmentItemModel {
  final String commitmentId;
  final String nameAr;
  final String nameEn;
  final String category;
  final double amount;
  final DateTime dueDate;
  final String frequency;
  final String status;
  final int remainingPayments;

  ScheduledCommitmentItemModel({
    required this.commitmentId,
    required this.nameAr,
    required this.nameEn,
    required this.category,
    required this.amount,
    required this.dueDate,
    required this.frequency,
    required this.status,
    required this.remainingPayments,
  });

  factory ScheduledCommitmentItemModel.fromJson(Map<String, dynamic> json) {
    return ScheduledCommitmentItemModel(
      commitmentId: json['commitmentId']?.toString() ?? '',
      nameAr: json['nameAr'] ?? '',
      nameEn: json['nameEn'] ?? '',
      category: json['category'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: DateTime.tryParse(json['dueDate'] ?? '') ?? DateTime.now(),
      frequency: json['frequency'] ?? 'Monthly',
      status: json['status'] ?? 'Upcoming',
      remainingPayments: json['remainingPayments'] ?? 12,
    );
  }
}

class MonthlyCommitmentGroupModel {
  final String monthKey;
  final String monthLabelAr;
  final String monthLabelEn;
  final double totalAmount;
  final bool isHeavyMonth;
  final List<ScheduledCommitmentItemModel> commitments;

  MonthlyCommitmentGroupModel({
    required this.monthKey,
    required this.monthLabelAr,
    required this.monthLabelEn,
    required this.totalAmount,
    required this.isHeavyMonth,
    required this.commitments,
  });

  factory MonthlyCommitmentGroupModel.fromJson(Map<String, dynamic> json) {
    return MonthlyCommitmentGroupModel(
      monthKey: json['monthKey'] ?? '',
      monthLabelAr: json['monthLabelAr'] ?? '',
      monthLabelEn: json['monthLabelEn'] ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      isHeavyMonth: json['isHeavyMonth'] ?? false,
      commitments: (json['commitments'] as List?)
              ?.map((e) => ScheduledCommitmentItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class CommitmentScheduleModel {
  final int totalMonths;
  final double totalObligations;
  final double monthlyAverage;
  final List<String> heavyMonths;
  final List<MonthlyCommitmentGroupModel> months;
  final String aiAnalysisAr;
  final String aiAnalysisEn;

  CommitmentScheduleModel({
    required this.totalMonths,
    required this.totalObligations,
    required this.monthlyAverage,
    required this.heavyMonths,
    required this.months,
    required this.aiAnalysisAr,
    required this.aiAnalysisEn,
  });

  factory CommitmentScheduleModel.fromJson(Map<String, dynamic> json) {
    return CommitmentScheduleModel(
      totalMonths: json['totalMonths'] ?? 12,
      totalObligations: (json['totalObligations'] as num?)?.toDouble() ?? 0.0,
      monthlyAverage: (json['monthlyAverage'] as num?)?.toDouble() ?? 0.0,
      heavyMonths: (json['heavyMonths'] as List?)?.map((e) => e.toString()).toList() ?? [],
      months: (json['months'] as List?)
              ?.map((e) => MonthlyCommitmentGroupModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      aiAnalysisAr: json['aiAnalysisAr'] ?? '',
      aiAnalysisEn: json['aiAnalysisEn'] ?? '',
    );
  }
}

class AnalysisSummaryModel {
  final FinancialHealthModel health;
  final FinancialForecastModel forecast;
  final CommitmentScheduleModel commitments;
  final String aiAnalysisTextAr;
  final String aiAnalysisTextEn;
  final double safeDailySpending;
  final DateTime lastUpdated;

  AnalysisSummaryModel({
    required this.health,
    required this.forecast,
    required this.commitments,
    required this.aiAnalysisTextAr,
    required this.aiAnalysisTextEn,
    required this.safeDailySpending,
    required this.lastUpdated,
  });

  factory AnalysisSummaryModel.fromJson(Map<String, dynamic> json) {
    return AnalysisSummaryModel(
      health: FinancialHealthModel.fromJson(json['health'] ?? {}),
      forecast: FinancialForecastModel.fromJson(json['forecast'] ?? {}),
      commitments: CommitmentScheduleModel.fromJson(json['commitments'] ?? {}),
      aiAnalysisTextAr: json['aiAnalysisTextAr'] ?? '',
      aiAnalysisTextEn: json['aiAnalysisTextEn'] ?? '',
      safeDailySpending: (json['safeDailySpending'] as num?)?.toDouble() ?? 120.0,
      lastUpdated: DateTime.tryParse(json['lastUpdated'] ?? '') ?? DateTime.now(),
    );
  }
}

class StressTestResultModel {
  final String scenarioKey;
  final String titleAr;
  final String titleEn;
  final double monthlyCommitments;
  final double disposableCash;
  final bool balanceStaysPositive;
  final bool emergencyReserveRequired;
  final String riskRatingAr;
  final String riskRatingEn;

  StressTestResultModel({
    required this.scenarioKey,
    required this.titleAr,
    required this.titleEn,
    required this.monthlyCommitments,
    required this.disposableCash,
    required this.balanceStaysPositive,
    required this.emergencyReserveRequired,
    required this.riskRatingAr,
    required this.riskRatingEn,
  });

  factory StressTestResultModel.fromJson(Map<String, dynamic> json) {
    return StressTestResultModel(
      scenarioKey: json['scenarioKey'] ?? '',
      titleAr: json['titleAr'] ?? '',
      titleEn: json['titleEn'] ?? '',
      monthlyCommitments: (json['monthlyCommitments'] as num?)?.toDouble() ?? 0.0,
      disposableCash: (json['disposableCash'] as num?)?.toDouble() ?? 0.0,
      balanceStaysPositive: json['balanceStaysPositive'] ?? true,
      emergencyReserveRequired: json['emergencyReserveRequired'] ?? false,
      riskRatingAr: json['riskRatingAr'] ?? '',
      riskRatingEn: json['riskRatingEn'] ?? '',
    );
  }
}

class LoanScenarioResultModel {
  final double loanAmount;
  final double annualRate;
  final int durationMonths;
  final double monthlyInstallment;
  final double totalPayments;
  final double totalFinancingCost;
  final DateTime expectedEndDate;
  final double existingMonthlyCommitments;
  final double newTotalCommitments;
  final double commitmentRatioBefore;
  final double commitmentRatioAfter;
  final double monthlyAvailableCashBefore;
  final double monthlyAvailableCashAfter;
  final String ratingAr;
  final String ratingEn;
  final String explanationAr;
  final String explanationEn;
  final List<StressTestResultModel> stressTests;
  final String disclaimerAr;
  final String disclaimerEn;

  LoanScenarioResultModel({
    required this.loanAmount,
    required this.annualRate,
    required this.durationMonths,
    required this.monthlyInstallment,
    required this.totalPayments,
    required this.totalFinancingCost,
    required this.expectedEndDate,
    required this.existingMonthlyCommitments,
    required this.newTotalCommitments,
    required this.commitmentRatioBefore,
    required this.commitmentRatioAfter,
    required this.monthlyAvailableCashBefore,
    required this.monthlyAvailableCashAfter,
    required this.ratingAr,
    required this.ratingEn,
    required this.explanationAr,
    required this.explanationEn,
    required this.stressTests,
    required this.disclaimerAr,
    required this.disclaimerEn,
  });

  factory LoanScenarioResultModel.fromJson(Map<String, dynamic> json) {
    return LoanScenarioResultModel(
      loanAmount: (json['loanAmount'] as num?)?.toDouble() ?? 50000.0,
      annualRate: (json['annualRate'] as num?)?.toDouble() ?? 5.5,
      durationMonths: json['durationMonths'] ?? 36,
      monthlyInstallment: (json['monthlyInstallment'] as num?)?.toDouble() ?? 1500.0,
      totalPayments: (json['totalPayments'] as num?)?.toDouble() ?? 54000.0,
      totalFinancingCost: (json['totalFinancingCost'] as num?)?.toDouble() ?? 4000.0,
      expectedEndDate: DateTime.tryParse(json['expectedEndDate'] ?? '') ?? DateTime.now().add(const Duration(days: 1095)),
      existingMonthlyCommitments: (json['existingMonthlyCommitments'] as num?)?.toDouble() ?? 2000.0,
      newTotalCommitments: (json['newTotalCommitments'] as num?)?.toDouble() ?? 3500.0,
      commitmentRatioBefore: (json['commitmentRatioBefore'] as num?)?.toDouble() ?? 0.28,
      commitmentRatioAfter: (json['commitmentRatioAfter'] as num?)?.toDouble() ?? 0.50,
      monthlyAvailableCashBefore: (json['monthlyAvailableCashBefore'] as num?)?.toDouble() ?? 2000.0,
      monthlyAvailableCashAfter: (json['monthlyAvailableCashAfter'] as num?)?.toDouble() ?? 500.0,
      ratingAr: json['ratingAr'] ?? 'ضغط مالي مرتفع',
      ratingEn: json['ratingEn'] ?? 'High Pressure',
      explanationAr: json['explanationAr'] ?? '',
      explanationEn: json['explanationEn'] ?? '',
      stressTests: (json['stressTests'] as List?)
              ?.map((e) => StressTestResultModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      disclaimerAr: json['disclaimerAr'] ?? 'ميزان يقدم دراسات تقديرية ولا يُعد جهة إقراض مرخصة.',
      disclaimerEn: json['disclaimerEn'] ?? 'Mizan provides planning estimates and is not a licensed lender.',
    );
  }
}

class LoanCompareResultModel {
  final List<LoanScenarioResultModel> results;
  final int recommendedOptionIndex;
  final String comparisonAnalysisAr;
  final String comparisonAnalysisEn;

  LoanCompareResultModel({
    required this.results,
    required this.recommendedOptionIndex,
    required this.comparisonAnalysisAr,
    required this.comparisonAnalysisEn,
  });

  factory LoanCompareResultModel.fromJson(Map<String, dynamic> json) {
    return LoanCompareResultModel(
      results: (json['results'] as List?)
              ?.map((e) => LoanScenarioResultModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recommendedOptionIndex: json['recommendedOptionIndex'] ?? 0,
      comparisonAnalysisAr: json['comparisonAnalysisAr'] ?? '',
      comparisonAnalysisEn: json['comparisonAnalysisEn'] ?? '',
    );
  }
}

class BudgetPlanComparisonModel {
  final String planNameAr;
  final String planNameEn;
  final double dailySpendTarget;
  final double savingsTarget;
  final double emergencyReserve;
  final double reservedForCommitments;
  final double discretionaryPool;
  final String rationaleAr;
  final String rationaleEn;

  BudgetPlanComparisonModel({
    required this.planNameAr,
    required this.planNameEn,
    required this.dailySpendTarget,
    required this.savingsTarget,
    required this.emergencyReserve,
    required this.reservedForCommitments,
    required this.discretionaryPool,
    required this.rationaleAr,
    required this.rationaleEn,
  });

  factory BudgetPlanComparisonModel.fromJson(Map<String, dynamic> json) {
    return BudgetPlanComparisonModel(
      planNameAr: json['planNameAr'] ?? '',
      planNameEn: json['planNameEn'] ?? '',
      dailySpendTarget: (json['dailySpendTarget'] as num?)?.toDouble() ?? 120.0,
      savingsTarget: (json['savingsTarget'] as num?)?.toDouble() ?? 1000.0,
      emergencyReserve: (json['emergencyReserve'] as num?)?.toDouble() ?? 500.0,
      reservedForCommitments: (json['reservedForCommitments'] as num?)?.toDouble() ?? 2150.0,
      discretionaryPool: (json['discretionaryPool'] as num?)?.toDouble() ?? 3600.0,
      rationaleAr: json['rationaleAr'] ?? '',
      rationaleEn: json['rationaleEn'] ?? '',
    );
  }
}

class BudgetOptimizationModel {
  final BudgetPlanComparisonModel currentPlan;
  final BudgetPlanComparisonModel optimizedPlan;
  final String explanationAr;
  final String explanationEn;
  final List<String> actionStepsAr;
  final List<String> actionStepsEn;

  BudgetOptimizationModel({
    required this.currentPlan,
    required this.optimizedPlan,
    required this.explanationAr,
    required this.explanationEn,
    required this.actionStepsAr,
    required this.actionStepsEn,
  });

  factory BudgetOptimizationModel.fromJson(Map<String, dynamic> json) {
    return BudgetOptimizationModel(
      currentPlan: BudgetPlanComparisonModel.fromJson(json['currentPlan'] ?? {}),
      optimizedPlan: BudgetPlanComparisonModel.fromJson(json['optimizedPlan'] ?? {}),
      explanationAr: json['explanationAr'] ?? '',
      explanationEn: json['explanationEn'] ?? '',
      actionStepsAr: (json['actionStepsAr'] as List?)?.map((e) => e.toString()).toList() ?? [],
      actionStepsEn: (json['actionStepsEn'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class WhatIfResultModel {
  final String scenarioType;
  final String titleAr;
  final String titleEn;
  final double immediateImpact;
  final double newMonthlyCommitments;
  final double newDisposableCash;
  final double newCommitmentRatio;
  final String feasibilityRatingAr;
  final String feasibilityRatingEn;
  final String explanationAr;
  final String explanationEn;

  WhatIfResultModel({
    required this.scenarioType,
    required this.titleAr,
    required this.titleEn,
    required this.immediateImpact,
    required this.newMonthlyCommitments,
    required this.newDisposableCash,
    required this.newCommitmentRatio,
    required this.feasibilityRatingAr,
    required this.feasibilityRatingEn,
    required this.explanationAr,
    required this.explanationEn,
  });

  factory WhatIfResultModel.fromJson(Map<String, dynamic> json) {
    return WhatIfResultModel(
      scenarioType: json['scenarioType'] ?? '',
      titleAr: json['titleAr'] ?? '',
      titleEn: json['titleEn'] ?? '',
      immediateImpact: (json['immediateImpact'] as num?)?.toDouble() ?? 0.0,
      newMonthlyCommitments: (json['newMonthlyCommitments'] as num?)?.toDouble() ?? 0.0,
      newDisposableCash: (json['newDisposableCash'] as num?)?.toDouble() ?? 0.0,
      newCommitmentRatio: (json['newCommitmentRatio'] as num?)?.toDouble() ?? 0.0,
      feasibilityRatingAr: json['feasibilityRatingAr'] ?? '',
      feasibilityRatingEn: json['feasibilityRatingEn'] ?? '',
      explanationAr: json['explanationAr'] ?? '',
      explanationEn: json['explanationEn'] ?? '',
    );
  }
}

class StructuredAICardModel {
  final String cardType;
  final String titleAr;
  final String titleEn;
  final Map<String, dynamic> data;
  final String? actionLabelAr;
  final String? actionLabelEn;
  final String? actionPayload;

  StructuredAICardModel({
    required this.cardType,
    required this.titleAr,
    required this.titleEn,
    required this.data,
    this.actionLabelAr,
    this.actionLabelEn,
    this.actionPayload,
  });

  factory StructuredAICardModel.fromJson(Map<String, dynamic> json) {
    return StructuredAICardModel(
      cardType: json['cardType'] ?? 'MoneySummaryCard',
      titleAr: json['titleAr'] ?? '',
      titleEn: json['titleEn'] ?? '',
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      actionLabelAr: json['actionLabelAr'],
      actionLabelEn: json['actionLabelEn'],
      actionPayload: json['actionPayload'],
    );
  }
}

class AISuggestedActionModel {
  final String actionId;
  final String labelAr;
  final String labelEn;
  final String actionType;
  final Map<String, dynamic> parameters;

  AISuggestedActionModel({
    required this.actionId,
    required this.labelAr,
    required this.labelEn,
    required this.actionType,
    required this.parameters,
  });

  factory AISuggestedActionModel.fromJson(Map<String, dynamic> json) {
    return AISuggestedActionModel(
      actionId: json['actionId'] ?? '',
      labelAr: json['labelAr'] ?? '',
      labelEn: json['labelEn'] ?? '',
      actionType: json['actionType'] ?? '',
      parameters: (json['parameters'] as Map<String, dynamic>?) ?? {},
    );
  }
}

class AIChatMessageModel {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final String severity;
  final List<StructuredAICardModel> cards;
  final List<AISuggestedActionModel> suggestedActions;
  final List<String> calculationReferences;
  final List<String> suggestedQuestions;
  final DateTime createdAt;

  AIChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    this.severity = 'normal',
    this.cards = const [],
    this.suggestedActions = const [],
    this.calculationReferences = const [],
    this.suggestedQuestions = const [],
    required this.createdAt,
  });

  factory AIChatMessageModel.fromJson(Map<String, dynamic> json) {
    return AIChatMessageModel(
      id: json['messageId']?.toString() ?? json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: json['role'] ?? 'assistant',
      content: json['answer'] ?? json['content'] ?? '',
      severity: json['severity'] ?? 'normal',
      cards: (json['cards'] as List?)
              ?.map((e) => StructuredAICardModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      suggestedActions: (json['suggestedActions'] as List?)
              ?.map((e) => AISuggestedActionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      calculationReferences: (json['calculationReferences'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      suggestedQuestions: (json['suggestedQuestions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class AIConversationModel {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  AIConversationModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
  });

  factory AIConversationModel.fromJson(Map<String, dynamic> json) {
    return AIConversationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'محادثة جديدة',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
    );
  }
}
