namespace Mizan.Contracts.AI;

// 1. Sanitized Financial Context Snapshot (Section 88)
public record FinancialContextDto(
    string Currency,
    decimal CurrentBalance,
    decimal AvailableToSpend,
    decimal MonthlyIncome,
    decimal MonthlyAverageIncome,
    decimal MonthlySpending,
    decimal AverageDailySpending,
    decimal MonthlyCommitments,
    decimal UpcomingCommitments,
    decimal SavingsReserve,
    decimal EmergencyReserve,
    decimal RemainingBudget,
    int DaysRemaining,
    double CommitmentRatio,
    Dictionary<string, decimal> Categories
);

// 2. Structured AI Visual Card (Section 93 & 114)
public record StructuredAICardDto(
    string CardType, // MoneySummaryCard, LoanScenarioCard, CommitmentCard, BudgetComparisonCard, SuggestedPlanCard, RiskCard
    string TitleAr,
    string TitleEn,
    Dictionary<string, object?> Data,
    string? ActionLabelAr = null,
    string? ActionLabelEn = null,
    string? ActionPayload = null
);

public record AISuggestedActionDto(
    string ActionId,
    string LabelAr,
    string LabelEn,
    string ActionType, // AdjustBudget, AddCommitment, SetSavingsTarget
    Dictionary<string, object?> Parameters
);

// 3. AI Chat Request & Response (Section 90 - 94)
public record AIChatRequest(
    string Message,
    Guid? ConversationId = null,
    string? Language = "ar"
);

public record AIChatResponse(
    Guid ConversationId,
    Guid MessageId,
    string Answer,
    string Severity, // normal, warning, alert, success
    List<StructuredAICardDto> Cards,
    List<AISuggestedActionDto> SuggestedActions,
    List<string> Assumptions,
    List<string> CalculationReferences,
    List<string>? SuggestedQuestions = null
);

public record AIConversationResponse(
    Guid Id,
    string Title,
    DateTime CreatedAt,
    DateTime UpdatedAt,
    int MessageCount
);

public record AIMessageResponse(
    Guid Id,
    Guid ConversationId,
    string Role,
    string Content,
    string? StructuredPayload,
    DateTime CreatedAt
);

// 4. Financial Health Score (Section 96)
public record HealthFactorDto(
    string NameAr,
    string NameEn,
    double Weight,
    double Score,
    string StatusAr,
    string StatusEn,
    string DescriptionAr,
    string DescriptionEn
);

public record FinancialHealthResult(
    int Score, // 0 - 100
    string StatusAr,
    string StatusEn,
    string SummaryAr,
    string SummaryEn,
    List<HealthFactorDto> Factors,
    string ScoringFormula,
    DateTime EvaluatedAt
);

// 5. Forecast (Section 99)
public record ForecastBoundsDto(
    decimal Low,
    decimal Expected,
    decimal High
);

public record FinancialForecastResult(
    ForecastBoundsDto MonthEndBalance,
    double Confidence,
    string ConfidenceLevelAr,
    string ConfidenceLevelEn,
    string ExplanationAr,
    string ExplanationEn,
    decimal CurrentBalance,
    decimal ExpectedRemainingIncome,
    decimal ExpectedDiscretionarySpend,
    decimal UpcomingCommitments,
    int DaysRemainingInMonth
);

// 6. Commitment Schedule & Timeline (Section 100 - 102)
public record ScheduledCommitmentItemDto(
    Guid CommitmentId,
    string NameAr,
    string NameEn,
    string Category,
    decimal Amount,
    DateTime DueDate,
    string Frequency,
    string Status,
    int RemainingPayments
);

public record MonthlyCommitmentGroupDto(
    string MonthKey, // "2026-09"
    string MonthLabelAr,
    string MonthLabelEn,
    decimal TotalAmount,
    bool IsHeavyMonth,
    List<ScheduledCommitmentItemDto> Commitments
);

public record CommitmentScheduleResult(
    int TotalMonths,
    decimal TotalObligations,
    decimal MonthlyAverage,
    List<string> HeavyMonths,
    List<MonthlyCommitmentGroupDto> Months,
    string AIAnalysisAr,
    string AIAnalysisEn
);

// 7. Analysis Summary (Section 97 & 118)
public record AnalysisSummaryResponse(
    FinancialHealthResult Health,
    FinancialForecastResult Forecast,
    CommitmentScheduleResult Commitments,
    string AIAnalysisTextAr,
    string AIAnalysisTextEn,
    decimal SafeDailySpending,
    DateTime LastUpdated
);

// 8. Loan Feasibility & Scenarios (Section 105 - 110, 123)
public record LoanScenarioRequest(
    decimal LoanAmount,
    decimal? AnnualRate = null, // e.g. 5.5 for 5.5%
    decimal? MonthlyPayment = null,
    int DurationMonths = 36,
    decimal Fees = 0m,
    DateTime? StartDate = null,
    bool StressTest = true
);

public record StressTestResultDto(
    string ScenarioKey,
    string TitleAr,
    string TitleEn,
    decimal MonthlyCommitments,
    decimal DisposableCash,
    bool BalanceStaysPositive,
    bool EmergencyReserveRequired,
    string RiskRatingAr,
    string RiskRatingEn
);

public record LoanScenarioResult(
    decimal LoanAmount,
    decimal AnnualRate,
    int DurationMonths,
    decimal MonthlyInstallment,
    decimal TotalPayments,
    decimal TotalFinancingCost,
    DateTime ExpectedEndDate,
    decimal ExistingMonthlyCommitments,
    decimal NewTotalCommitments,
    double CommitmentRatioBefore,
    double CommitmentRatioAfter,
    decimal MonthlyAvailableCashBefore,
    decimal MonthlyAvailableCashAfter,
    string RatingAr, // مريح, يمكن إدارته, ضغط مالي مرتفع, ضغط مالي حرج
    string RatingEn, // Comfortable, Manageable with adjustments, High Pressure, Very High Pressure
    string ExplanationAr,
    string ExplanationEn,
    List<StressTestResultDto> StressTests,
    string DisclaimerAr,
    string DisclaimerEn
);

public record LoanCompareRequest(
    List<LoanScenarioRequest> Options
);

public record LoanCompareResult(
    List<LoanScenarioResult> Results,
    int RecommendedOptionIndex,
    string ComparisonAnalysisAr,
    string ComparisonAnalysisEn
);

// 9. Budget Optimization & Rescheduling (Section 103, 104, 128)
public record BudgetOptimizationRequest(
    string Objective = "Balanced" // Balanced, SaveMore, ReduceDebt, PrepareCommitment, Conservative
);

public record BudgetPlanComparisonDto(
    string PlanNameAr,
    string PlanNameEn,
    decimal DailySpendTarget,
    decimal SavingsTarget,
    decimal EmergencyReserve,
    decimal ReservedForCommitments,
    decimal DiscretionaryPool,
    string RationaleAr,
    string RationaleEn
);

public record BudgetOptimizationResult(
    BudgetPlanComparisonDto CurrentPlan,
    BudgetPlanComparisonDto OptimizedPlan,
    string ExplanationAr,
    string ExplanationEn,
    List<string> ActionStepsAr,
    List<string> ActionStepsEn
);

// 10. What-If Scenarios (Section 112)
public record WhatIfScenarioRequest(
    string ScenarioType, // Loan, MajorPurchase, SalaryRaise, ExpenseReduction, ExtraCommitment
    decimal Amount,
    int DurationMonths = 1,
    Dictionary<string, object?>? Parameters = null
);

public record WhatIfScenarioResult(
    string ScenarioType,
    string TitleAr,
    string TitleEn,
    decimal ImmediateImpact,
    decimal NewMonthlyCommitments,
    decimal NewDisposableCash,
    double NewCommitmentRatio,
    string FeasibilityRatingAr,
    string FeasibilityRatingEn,
    string ExplanationAr,
    string ExplanationEn
);

// 11. Cash Flow (Section 98)
public record CashFlowPointDto(
    DateTime Date,
    string DateLabel,
    decimal ExpectedIncome,
    decimal ExpectedSpending,
    decimal UpcomingCommitments,
    decimal ProjectedBalance
);

public record CashFlowResponse(
    string Range, // 7d, 30d, month_end, 90d
    decimal CurrentAvailable,
    decimal TotalUpcomingCommitments,
    decimal ExpectedDiscretionary,
    decimal ProjectedEndingBalance,
    List<CashFlowPointDto> Points
);

// 12. Purchase Feasibility Scenario
public record PurchaseScenarioRequest(
    decimal PurchaseAmount,
    string? ItemName = "السلعة",
    int Installments = 1
);

public record PurchaseScenarioResult(
    decimal PurchaseAmount,
    string ItemName,
    decimal CurrentAvailable,
    decimal AvailableAfter,
    decimal CurrentDailySpend,
    decimal NewDailySpend,
    string FeasibilityRatingAr, // مريح, يمكن إدارته, ضغط سيولة, غير موصى به حالياً
    string FeasibilityRatingEn, // Comfortable, Manageable, Tight Liquidity, Not Recommended
    string ExplanationAr,
    string ExplanationEn,
    StructuredAICardDto VisualCard
);

// 13. Financial Scheduling / Salary Organization Plan
public record FinancialPlanRequest(
    decimal? CustomIncome = null,
    string? Objective = "Balanced"
);

public record FinancialPlanResult(
    decimal Income,
    decimal Commitments,
    decimal Savings,
    decimal Emergency,
    decimal AvailableToSpend,
    decimal SafeDailySpend,
    string ExplanationAr,
    string ExplanationEn,
    StructuredAICardDto VisualCard
);

// 14. Suggested Questions & Conversation Creation
public record CreateConversationRequest(
    string? Title = null
);

public record AISuggestedQuestionsResponse(
    List<string> QuestionsAr,
    List<string> QuestionsEn
);

