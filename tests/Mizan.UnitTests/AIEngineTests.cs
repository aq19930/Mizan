using Mizan.Application.Services;
using Mizan.Contracts.AI;
using Xunit;

namespace Mizan.UnitTests;

public class AIEngineTests
{
    private readonly FinancialHealthEngine _healthEngine = new();
    private readonly LoanCalculationEngine _loanEngine = new();
    private readonly FinancialForecastEngine _forecastEngine = new();
    private readonly FinancialSchedulingEngine _schedulingEngine = new();

    private FinancialContextDto CreateSampleContext(
        decimal currentBalance = 14500m,
        decimal monthlyIncome = 6960.45m,
        decimal monthlySpending = 3850m,
        decimal monthlyCommitments = 2150m,
        decimal upcomingCommitments = 1726.35m,
        decimal savingsReserve = 1000m,
        decimal emergencyReserve = 500m)
    {
        int daysRemaining = 14;
        decimal averageDailySpending = 128.30m;
        decimal remainingBudget = 2750m;
        double commitmentRatio = monthlyIncome > 0 ? (double)(monthlyCommitments / monthlyIncome) : 0.0;
        decimal availableToSpend = Math.Max(0m, currentBalance - upcomingCommitments - savingsReserve - emergencyReserve);

        var categories = new Dictionary<string, decimal>
        {
            ["مطاعم ومشروبات"] = 850m,
            ["مواصلات"] = 420m,
            ["ترفيه"] = 310m,
            ["فواتير"] = 640m
        };

        return new FinancialContextDto(
            "SAR",
            currentBalance,
            availableToSpend,
            monthlyIncome,
            monthlyIncome,
            monthlySpending,
            averageDailySpending,
            monthlyCommitments,
            upcomingCommitments,
            savingsReserve,
            emergencyReserve,
            remainingBudget,
            daysRemaining,
            commitmentRatio,
            categories
        );
    }

    [Fact]
    public void FinancialHealthEngine_HealthyUser_ReturnsGoodScore()
    {
        var ctx = CreateSampleContext();
        var result = _healthEngine.EvaluateHealth(ctx, overdueCommitmentsCount: 0);

        Assert.InRange(result.Score, 70, 95);
        Assert.Contains(result.StatusEn, new[] { "Good", "Excellent" });
        Assert.NotEmpty(result.Factors);
        Assert.NotEmpty(result.ScoringFormula);
    }

    [Fact]
    public void FinancialHealthEngine_OverdueCommitments_AppliesStrictPenalty()
    {
        var ctx = CreateSampleContext();
        var cleanResult = _healthEngine.EvaluateHealth(ctx, overdueCommitmentsCount: 0);
        var penalizedResult = _healthEngine.EvaluateHealth(ctx, overdueCommitmentsCount: 2);

        // 2 overdue commitments should deduct 24 points
        Assert.Equal(cleanResult.Score - 24, penalizedResult.Score);
    }

    [Fact]
    public void LoanCalculationEngine_StandardAmortization_CalculatesExactInstallments()
    {
        var ctx = CreateSampleContext();
        var req = new LoanScenarioRequest(
            LoanAmount: 50000m,
            AnnualRate: 5.5m,
            DurationMonths: 36,
            StressTest: true
        );

        var res = _loanEngine.CalculateLoanScenario(req, ctx);

        Assert.Equal(50000m, res.LoanAmount);
        Assert.Equal(36, res.DurationMonths);
        // Monthly payment for 50k at 5.5% for 36 months is approx 1,509 SAR
        Assert.InRange(res.MonthlyInstallment, 1500m, 1525m);
        Assert.True(res.TotalPayments > 50000m);
        Assert.True(res.TotalFinancingCost > 0);

        // New total commitments = existing (2,150) + installment (~1,509) = ~3,659
        Assert.Equal(ctx.MonthlyCommitments + res.MonthlyInstallment, res.NewTotalCommitments);
        Assert.True(res.CommitmentRatioAfter > res.CommitmentRatioBefore);

        // Verify stress tests
        Assert.Equal(5, res.StressTests.Count);
        Assert.Contains(res.StressTests, s => s.ScenarioKey == "NormalMonth");
        Assert.Contains(res.StressTests, s => s.ScenarioKey == "SpendingPlus10");
        Assert.Contains(res.StressTests, s => s.ScenarioKey == "UnexpectedExpense");
        Assert.Contains(res.StressTests, s => s.ScenarioKey == "IncomeDrop10");
        Assert.Contains(res.StressTests, s => s.ScenarioKey == "AnnualCommitment");

        // Mandatory disclaimer
        Assert.False(string.IsNullOrWhiteSpace(res.DisclaimerAr));
        Assert.False(string.IsNullOrWhiteSpace(res.DisclaimerEn));
    }

    [Fact]
    public void LoanCalculationEngine_HighDebtBurden_ClassifiesAsHighPressure()
    {
        // User with existing 3,000 SAR commitments on 6,000 SAR income (50% DTI already)
        var ctx = CreateSampleContext(monthlyIncome: 6000m, monthlyCommitments: 3000m);
        var req = new LoanScenarioRequest(LoanAmount: 50000m, AnnualRate: 6m, DurationMonths: 36);

        var res = _loanEngine.CalculateLoanScenario(req, ctx);

        // New DTI will exceed 60%
        Assert.True(res.CommitmentRatioAfter > 0.50);
        Assert.Equal("Very High Pressure", res.RatingEn);
        Assert.Equal("ضغط مالي حرج", res.RatingAr);
    }

    [Fact]
    public void LoanCalculationEngine_CompareLoans_RecommendsOptimalOption()
    {
        var ctx = CreateSampleContext();
        var req = new LoanCompareRequest(new List<LoanScenarioRequest>
        {
            new(50000m, 5.0m, null, 36),
            new(50000m, 5.0m, null, 48),
            new(50000m, 5.0m, null, 60)
        });

        var compareRes = _loanEngine.CompareLoans(req, ctx);

        Assert.Equal(3, compareRes.Results.Count);
        Assert.InRange(compareRes.RecommendedOptionIndex, 0, 2);
        Assert.False(string.IsNullOrWhiteSpace(compareRes.ComparisonAnalysisAr));
    }

    [Fact]
    public void FinancialForecastEngine_CalculatesBoundsAndConfidence()
    {
        var ctx = CreateSampleContext();
        var forecast = _forecastEngine.ForecastMonthEnd(ctx, transactionCount: 35, DateTime.UtcNow);

        Assert.True(forecast.Confidence >= 0.80);
        Assert.Equal("High Confidence", forecast.ConfidenceLevelEn);
        Assert.True(forecast.MonthEndBalance.Low < forecast.MonthEndBalance.Expected);
        Assert.True(forecast.MonthEndBalance.High > forecast.MonthEndBalance.Expected);
        Assert.True(forecast.ExpectedDiscretionarySpend > 0);
    }

    [Fact]
    public void FinancialForecastEngine_LowDataVolume_DisclosesPreliminaryStatus()
    {
        var ctx = CreateSampleContext();
        var forecast = _forecastEngine.ForecastMonthEnd(ctx, transactionCount: 3, DateTime.UtcNow);

        Assert.True(forecast.Confidence < 0.60);
        Assert.Equal("Preliminary Estimate", forecast.ConfidenceLevelEn);
        Assert.Contains("محدودة", forecast.ExplanationAr);
    }

    [Fact]
    public void FinancialSchedulingEngine_BalancedAndSaveMore_OptimizesLiquidity()
    {
        var ctx = CreateSampleContext();
        var balanced = _schedulingEngine.OptimizeBudget(new BudgetOptimizationRequest("Balanced"), ctx);
        var saveMore = _schedulingEngine.OptimizeBudget(new BudgetOptimizationRequest("SaveMore"), ctx);

        Assert.True(saveMore.OptimizedPlan.SavingsTarget > balanced.OptimizedPlan.SavingsTarget);
        Assert.True(balanced.OptimizedPlan.DailySpendTarget > 0);
        Assert.NotEmpty(balanced.ActionStepsAr);
    }

    [Fact]
    public void PurchaseFeasibilityEngine_AffordableItem_ReturnsComfortableAndCalculatesNewPace()
    {
        var engine = new PurchaseFeasibilityEngine();
        var ctx = CreateSampleContext(currentBalance: 15000m, upcomingCommitments: 2000m);
        var result = engine.CalculatePurchaseScenario(new PurchaseScenarioRequest(5000m, "آيفون"), ctx);

        Assert.Equal(5000m, result.PurchaseAmount);
        Assert.Equal("آيفون", result.ItemName);
        Assert.True(result.AvailableAfter > 0);
        Assert.Contains(result.FeasibilityRatingEn, new[] { "Comfortable", "Manageable" });
        Assert.True(result.NewDailySpend < result.CurrentDailySpend);
        Assert.NotNull(result.VisualCard);
    }

    [Fact]
    public void FinancialPlanEngine_OrganizesSalaryAndRingFencesCommitments()
    {
        var engine = new FinancialPlanEngine();
        var ctx = CreateSampleContext(monthlyIncome: 6960.45m, monthlyCommitments: 1671.35m);
        var result = engine.CalculateSalaryPlan(new FinancialPlanRequest(), ctx);

        Assert.Equal(6960.45m, result.Income);
        Assert.Equal(1671.35m, result.Commitments);
        Assert.True(result.Savings > 0);
        Assert.True(result.Emergency > 0);
        Assert.True(result.AvailableToSpend > 0);
        Assert.True(result.SafeDailySpend > 0);
        Assert.NotNull(result.VisualCard);
    }

    [Fact]
    public void FinancialContextSanitizer_MasksCardsTokensAndCredentials()
    {
        string rawPrompt = "بطاقتي هي 4111 2222 3333 4444 والرمز OTP 982134 والتوكن eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.t-ID وكلمة المرور password:secret";
        string sanitized = FinancialContextSanitizer.SanitizeUserPrompt(rawPrompt);

        Assert.DoesNotContain("4111 2222 3333 4444", sanitized);
        Assert.DoesNotContain("982134", sanitized);
        Assert.DoesNotContain("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9", sanitized);
        Assert.DoesNotContain("secret", sanitized);
        Assert.Contains("****-****-****-4444", sanitized);
    }
}
