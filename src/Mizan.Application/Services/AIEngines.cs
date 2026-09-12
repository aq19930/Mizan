using Mizan.Application.Interfaces;
using Mizan.Contracts.AI;

namespace Mizan.Application.Services;

public class FinancialHealthEngine : IFinancialHealthEngine
{
    public FinancialHealthResult EvaluateHealth(FinancialContextDto context, int overdueCommitmentsCount)
    {
        var factors = new List<HealthFactorDto>();

        // 1. Savings Rate Factor (Weight: 25%)
        double savingsRatio = 0.0;
        if (context.MonthlyIncome > 0)
        {
            savingsRatio = (double)((context.MonthlyIncome - context.MonthlySpending) / context.MonthlyIncome);
        }
        double savingsScore = savingsRatio switch
        {
            >= 0.25 => 100.0,
            >= 0.15 => 85.0,
            >= 0.08 => 65.0,
            >= 0.00 => 40.0,
            _ => 15.0
        };
        factors.Add(new HealthFactorDto(
            "معدل الادخار",
            "Savings Rate",
            0.25,
            savingsScore,
            savingsScore >= 80 ? "ممتاز" : savingsScore >= 60 ? "جيد" : "منخفض",
            savingsScore >= 80 ? "Excellent" : savingsScore >= 60 ? "Good" : "Low",
            $"ادخار شهري يقدر بـ {Math.Max(0, (savingsRatio * 100)):F1}% من الدخل.",
            $"Estimated monthly savings of {Math.Max(0, (savingsRatio * 100)):F1}% of income."
        ));

        // 2. Commitment Ratio / DTI Factor (Weight: 25%)
        double dti = context.CommitmentRatio;
        double dtiScore = dti switch
        {
            <= 0.25 => 100.0,
            <= 0.33 => 90.0, // SAMA safe threshold
            <= 0.40 => 70.0,
            <= 0.50 => 45.0,
            _ => 20.0
        };
        factors.Add(new HealthFactorDto(
            "نسبة الالتزامات والديون",
            "Commitment Ratio",
            0.25,
            dtiScore,
            dtiScore >= 85 ? "آمن جداً" : dtiScore >= 65 ? "معتدل" : "مرتفع",
            dtiScore >= 85 ? "Very Safe" : dtiScore >= 65 ? "Moderate" : "High",
            $"تمثل الالتزامات {(dti * 100):F1}% من دخلك الشهري (الحد الموصى به 33%).",
            $"Commitments represent {(dti * 100):F1}% of monthly income (Recommended limit 33%)."
        ));

        // 3. Budget Adherence (Weight: 20%)
        decimal dailyBurnNeeded = context.DaysRemaining > 0
            ? context.RemainingBudget / context.DaysRemaining
            : context.RemainingBudget;
        double budgetScore = 80.0;
        if (context.AverageDailySpending > 0)
        {
            double burnRatio = (double)(dailyBurnNeeded / context.AverageDailySpending);
            budgetScore = burnRatio >= 1.0 ? 100.0 : Math.Max(20.0, burnRatio * 85.0);
        }
        factors.Add(new HealthFactorDto(
            "الالتزام بالميزانية",
            "Budget Adherence",
            0.20,
            budgetScore,
            budgetScore >= 80 ? "منضبط" : "يحتاج ترشيد",
            budgetScore >= 80 ? "Disciplined" : "Needs Control",
            $"المتبقي من الميزانية {context.RemainingBudget:N0} {context.Currency} لـ {context.DaysRemaining} يوماً.",
            $"Remaining budget is {context.RemainingBudget:N0} {context.Currency} for {context.DaysRemaining} days."
        ));

        // 4. Emergency Reserve Factor (Weight: 15%)
        decimal targetReserve = Math.Max(3000m, context.MonthlyCommitments + (context.MonthlySpending * 0.5m));
        double reserveScore = targetReserve > 0
            ? Math.Min(100.0, (double)(context.EmergencyReserve / targetReserve) * 100.0)
            : 50.0;
        factors.Add(new HealthFactorDto(
            "صندوق الطوارئ",
            "Emergency Reserve",
            0.15,
            reserveScore,
            reserveScore >= 80 ? "محمي" : "غير كافٍ",
            reserveScore >= 80 ? "Protected" : "Insufficient",
            $"احتياطي الطوارئ الحالي {context.EmergencyReserve:N0} {context.Currency} من المستهدف {targetReserve:N0} {context.Currency}.",
            $"Current reserve is {context.EmergencyReserve:N0} {context.Currency} out of target {targetReserve:N0} {context.Currency}."
        ));

        // 5. Spending Volatility & Liquidity (Weight: 15%)
        double liquidityScore = context.AvailableToSpend >= (context.AverageDailySpending * 7) ? 95.0 : 50.0;
        factors.Add(new HealthFactorDto(
            "السيولة الفورية",
            "Immediate Liquidity",
            0.15,
            liquidityScore,
            liquidityScore >= 80 ? "جيدة" : "منخفضة",
            liquidityScore >= 80 ? "Good" : "Tight",
            $"المتاح للصرف حالياً {context.AvailableToSpend:N0} {context.Currency}.",
            $"Current available cash is {context.AvailableToSpend:N0} {context.Currency}."
        ));

        // Calculate weighted score
        double rawScore = factors.Sum(f => f.Score * f.Weight);

        // Penalty for overdue commitments
        int penalty = overdueCommitmentsCount * 12;
        int finalScore = Math.Clamp((int)Math.Round(rawScore) - penalty, 0, 100);

        string statusAr = finalScore switch
        {
            >= 85 => "ممتاز",
            >= 70 => "جيد",
            >= 50 => "مقبول",
            _ => "يحتاج إلى تحسين"
        };

        string statusEn = finalScore switch
        {
            >= 85 => "Excellent",
            >= 70 => "Good",
            >= 50 => "Fair",
            _ => "Needs Attention"
        };

        string summaryAr = $"درجتك المالية {finalScore}/100 ({statusAr}). " +
            (dti > 0.33 ? "تنبيه: التزاماتك تتجاوز ثلث الدخل. " : "التزاماتك في نطاق آمن. ") +
            (finalScore >= 70 ? "لديك مرونة جيدة في إدارة مصاريفك اليومية." : "يُنصح بخفض المصاريف غير الأساسية وبناء صندوق الطوارئ.");

        string summaryEn = $"Your financial health score is {finalScore}/100 ({statusEn}). " +
            (dti > 0.33 ? "Warning: Commitments exceed one-third of income. " : "Commitments are within a safe threshold. ") +
            (finalScore >= 70 ? "You maintain healthy flexibility for daily spending." : "We recommend curbing discretionary spending and building your reserve.");

        return new FinancialHealthResult(
            finalScore,
            statusAr,
            statusEn,
            summaryAr,
            summaryEn,
            factors,
            "Weighted: Savings (25%) + Commitments/DTI (25%) + Budget (20%) + Emergency (15%) + Liquidity (15%) - Overdue Penalties",
            DateTime.UtcNow
        );
    }
}

public class FinancialForecastEngine : IFinancialForecastEngine
{
    public FinancialForecastResult ForecastMonthEnd(FinancialContextDto context, int transactionCount, DateTime currentDate)
    {
        int daysRemaining = context.DaysRemaining;
        decimal expectedDiscretionary = context.AverageDailySpending * daysRemaining;

        // Remaining income expected before month end (e.g. salary on 27th)
        decimal expectedRemainingIncome = 0m;
        if (currentDate.Day < 27 && context.MonthlyIncome > 0)
        {
            // If salary hasn't arrived yet this month
            expectedRemainingIncome = context.MonthlyIncome;
        }

        decimal expectedEndingBalance = context.CurrentBalance + expectedRemainingIncome - context.UpcomingCommitments - expectedDiscretionary;
        decimal variance = expectedDiscretionary * 0.15m;
        decimal lowBound = expectedEndingBalance - variance;
        decimal highBound = expectedEndingBalance + variance;

        // Confidence calculation
        double confidence = transactionCount switch
        {
            >= 30 => 0.88,
            >= 15 => 0.76,
            >= 5 => 0.60,
            _ => 0.42
        };

        string confLevelAr = confidence >= 0.80 ? "دقة عالية" : confidence >= 0.65 ? "دقة متوسطة" : "تقدير أولي";
        string confLevelEn = confidence >= 0.80 ? "High Confidence" : confidence >= 0.65 ? "Medium Confidence" : "Preliminary Estimate";

        string explAr = transactionCount < 10
            ? "البيانات الحالية محدودة، التوقع تقديري أولي سيزداد دقة مع زيادة عملياتك المسجلة."
            : $"التوقع مبني على متوسط صرف يومي {context.AverageDailySpending:N1} ريال والتزامات قادمة بقيمة {context.UpcomingCommitments:N0} ريال.";

        string explEn = transactionCount < 10
            ? "Current data is limited. Projections are preliminary and will gain precision as more transactions are recorded."
            : $"Forecast is based on daily spending average of {context.AverageDailySpending:N1} SAR and upcoming obligations of {context.UpcomingCommitments:N0} SAR.";

        return new FinancialForecastResult(
            new ForecastBoundsDto(Math.Round(lowBound, 2), Math.Round(expectedEndingBalance, 2), Math.Round(highBound, 2)),
            confidence,
            confLevelAr,
            confLevelEn,
            explAr,
            explEn,
            context.CurrentBalance,
            expectedRemainingIncome,
            expectedDiscretionary,
            context.UpcomingCommitments,
            daysRemaining
        );
    }
}

public class LoanCalculationEngine : ILoanCalculationEngine
{
    public LoanScenarioResult CalculateLoanScenario(LoanScenarioRequest request, FinancialContextDto context)
    {
        decimal principal = request.LoanAmount + request.Fees;
        decimal annualRate = request.AnnualRate ?? 5.0m;
        int durationMonths = Math.Max(1, request.DurationMonths);

        decimal monthlyInstallment;
        if (request.MonthlyPayment.HasValue && request.MonthlyPayment.Value > 0)
        {
            monthlyInstallment = request.MonthlyPayment.Value;
        }
        else
        {
            if (annualRate > 0)
            {
                double monthlyRate = (double)(annualRate / 100m / 12m);
                double n = durationMonths;
                double factor = Math.Pow(1.0 + monthlyRate, n);
                double p = (double)principal;
                double m = p * (monthlyRate * factor) / (factor - 1.0);
                monthlyInstallment = Math.Round((decimal)m, 2);
            }
            else
            {
                monthlyInstallment = Math.Round(principal / durationMonths, 2);
            }
        }

        decimal totalPayments = monthlyInstallment * durationMonths;
        decimal totalFinancingCost = Math.Max(0m, totalPayments - request.LoanAmount);
        DateTime startDate = request.StartDate ?? DateTime.UtcNow;
        DateTime expectedEndDate = startDate.AddMonths(durationMonths);

        decimal existingCommitments = context.MonthlyCommitments;
        decimal newTotalCommitments = existingCommitments + monthlyInstallment;

        double ratioBefore = context.MonthlyIncome > 0
            ? (double)(existingCommitments / context.MonthlyIncome)
            : 0.0;
        double ratioAfter = context.MonthlyIncome > 0
            ? (double)(newTotalCommitments / context.MonthlyIncome)
            : 0.0;

        decimal monthlyLivingExpenses = context.MonthlySpending;
        decimal cashBefore = context.MonthlyIncome - existingCommitments - monthlyLivingExpenses;
        decimal cashAfter = context.MonthlyIncome - newTotalCommitments - monthlyLivingExpenses;

        string ratingAr;
        string ratingEn;

        if (ratioAfter <= 0.33)
        {
            ratingAr = "مريح ومناسب للسيولة";
            ratingEn = "Comfortable";
        }
        else if (ratioAfter <= 0.40)
        {
            ratingAr = "يمكن إدارته مع ترشيد الصرف";
            ratingEn = "Manageable with adjustments";
        }
        else if (ratioAfter <= 0.50)
        {
            ratingAr = "ضغط مالي مرتفع";
            ratingEn = "High Pressure";
        }
        else
        {
            ratingAr = "ضغط مالي حرج";
            ratingEn = "Very High Pressure";
        }

        string explAr = $"بعد إضافة هذا التمويل، ستصل التزاماتك الشهرية إلى حوالي {(ratioAfter * 100):F1}% من دخلك. " +
            $"القسط المقدر هو {monthlyInstallment:N0} ريال شهرياً لمدة {durationMonths} شهراً. " +
            $"سيبقى لديك هامش سيولة شهري قدره {cashAfter:N0} ريال بعد تغطية الالتزامات ومصاريف المعيشة الحالية.";

        string explEn = $"After adding this financing, total commitments will reach approximately {(ratioAfter * 100):F1}% of monthly income. " +
            $"Estimated installment is {monthlyInstallment:N0} SAR/month for {durationMonths} months. " +
            $"Net monthly disposable margin will be {cashAfter:N0} SAR after obligations and typical living expenses.";

        // Stress tests
        var stressTests = new List<StressTestResultDto>();
        if (request.StressTest)
        {
            // Scenario A: Normal Month
            stressTests.Add(new StressTestResultDto(
                "NormalMonth",
                "الشهر المعتاد",
                "Normal Month",
                newTotalCommitments,
                cashAfter,
                cashAfter >= 0,
                cashAfter < 500,
                cashAfter >= 0 ? "آمن" : "عجز نقدي",
                cashAfter >= 0 ? "Safe" : "Deficit"
            ));

            // Scenario B: Spending +10%
            decimal stressBSpending = monthlyLivingExpenses * 1.10m;
            decimal stressBCash = context.MonthlyIncome - newTotalCommitments - stressBSpending;
            stressTests.Add(new StressTestResultDto(
                "SpendingPlus10",
                "ارتفاع المصاريف 10%",
                "Spending Increases 10%",
                newTotalCommitments,
                stressBCash,
                stressBCash >= 0,
                stressBCash < 500,
                stressBCash >= 0 ? "مقبول" : "ضغط سيولة",
                stressBCash >= 0 ? "Acceptable" : "Cash Crunch"
            ));

            // Scenario C: Unexpected 2,000 SAR expense
            decimal stressCCash = cashAfter - 2000m;
            stressTests.Add(new StressTestResultDto(
                "UnexpectedExpense",
                "مصروف طارئ (2,000 ريال)",
                "Unexpected Expense (2,000 SAR)",
                newTotalCommitments,
                stressCCash,
                stressCCash >= 0,
                true,
                stressCCash >= 0 ? "يستلزم استخدام الاحتياطي" : "عجز نقدي مؤقت",
                stressCCash >= 0 ? "Requires Reserve" : "Temporary Deficit"
            ));

            // Scenario D: Income -10%
            decimal stressDIncome = context.MonthlyIncome * 0.90m;
            decimal stressDCash = stressDIncome - newTotalCommitments - monthlyLivingExpenses;
            stressTests.Add(new StressTestResultDto(
                "IncomeDrop10",
                "انخفاض الدخل 10%",
                "Income Decreases 10%",
                newTotalCommitments,
                stressDCash,
                stressDCash >= 0,
                stressDCash < 500,
                stressDCash >= 0 ? "ضغط سيولة" : "حرج جداً",
                stressDCash >= 0 ? "Tight" : "Critical"
            ));

            // Scenario E: Major Annual Commitment
            decimal stressECash = cashAfter - 1500m;
            stressTests.Add(new StressTestResultDto(
                "AnnualCommitment",
                "حلول التزام سنوي كبير",
                "Major Annual Commitment Due",
                newTotalCommitments + 1500m,
                stressECash,
                stressECash >= 0,
                stressECash < 500,
                stressECash >= 0 ? "يتطلب تخطيطاً مسبقاً" : "عجز بدون خطة حجز",
                stressECash >= 0 ? "Needs Pre-planning" : "Deficit Without Reserve"
            ));
        }

        const string disclaimerAr = "ميزان يقدم دراسات وتحليلات تخطيط مالي تقديرية ولا يُعد جهة تمويل أو وساطة أو استشارة مالية مرخصة.";
        const string disclaimerEn = "Mizan provides planning estimates and is not a licensed financing, brokerage, or financial advisory institution.";

        return new LoanScenarioResult(
            request.LoanAmount,
            annualRate,
            durationMonths,
            monthlyInstallment,
            totalPayments,
            totalFinancingCost,
            expectedEndDate,
            existingCommitments,
            newTotalCommitments,
            ratioBefore,
            ratioAfter,
            cashBefore,
            cashAfter,
            ratingAr,
            ratingEn,
            explAr,
            explEn,
            stressTests,
            disclaimerAr,
            disclaimerEn
        );
    }

    public LoanCompareResult CompareLoans(LoanCompareRequest request, FinancialContextDto context)
    {
        var results = new List<LoanScenarioResult>();
        foreach (var opt in request.Options)
        {
            results.Add(CalculateLoanScenario(opt, context));
        }

        // Recommend option with lowest DTI that satisfies positive cash flow and least total financing cost
        int recommendedIndex = 0;
        decimal lowestFinancingCost = decimal.MaxValue;
        for (int i = 0; i < results.Count; i++)
        {
            var res = results[i];
            if (res.CommitmentRatioAfter <= 0.40 && res.TotalFinancingCost < lowestFinancingCost)
            {
                lowestFinancingCost = res.TotalFinancingCost;
                recommendedIndex = i;
            }
        }

        var rec = results[recommendedIndex];
        string analysisAr = $"الخيار الموصى به هو الخيار رقم ({recommendedIndex + 1}) بقسط {rec.MonthlyInstallment:N0} ريال على مدار {rec.DurationMonths} شهراً، " +
            $"حيث يحقق توازناً أمثل بين أقل تكلفة تمويل إجمالية ({rec.TotalFinancingCost:N0} ريال) ونسبة التزام آمنة ({(rec.CommitmentRatioAfter * 100):F1}%).";

        string analysisEn = $"Recommended option is Option ({recommendedIndex + 1}) with installment of {rec.MonthlyInstallment:N0} SAR over {rec.DurationMonths} months, " +
            $"balancing lowest financing cost ({rec.TotalFinancingCost:N0} SAR) with safe commitment ratio ({(rec.CommitmentRatioAfter * 100):F1}%).";

        return new LoanCompareResult(results, recommendedIndex, analysisAr, analysisEn);
    }
}

public class FinancialSchedulingEngine : IFinancialSchedulingEngine
{
    public BudgetOptimizationResult OptimizeBudget(BudgetOptimizationRequest request, FinancialContextDto context)
    {
        decimal income = Math.Max(context.MonthlyIncome, 4000m);
        decimal commitments = context.MonthlyCommitments;
        decimal afterCommitments = Math.Max(0m, income - commitments);

        // Current Plan
        decimal currentDailySpend = context.AverageDailySpending > 0 ? context.AverageDailySpending : 120m;
        decimal currentSavings = context.SavingsReserve;
        decimal currentEmergency = context.EmergencyReserve;

        var currentPlan = new BudgetPlanComparisonDto(
            "الخطة الحالية",
            "Current Plan",
            Math.Round(currentDailySpend, 2),
            currentSavings,
            currentEmergency,
            commitments,
            Math.Round(currentDailySpend * 30, 2),
            "مبنية على نمط الصرف الفعلي الحالي.",
            "Based on current historical spend patterns."
        );

        // Optimized Plan based on objective
        decimal optSavings;
        decimal optEmergency;
        decimal optDailySpend;
        string rationaleAr;
        string rationaleEn;
        var stepsAr = new List<string>();
        var stepsEn = new List<string>();

        switch (request.Objective.ToLowerInvariant())
        {
            case "savemore":
                optSavings = afterCommitments * 0.25m;
                optEmergency = afterCommitments * 0.10m;
                decimal discSave = afterCommitments - optSavings - optEmergency;
                optDailySpend = discSave / 30m;
                rationaleAr = "تكثيف الادخار بنسبة 25% من السيولة المتبقية مع خفض طفيف للمصروفات اليومية.";
                rationaleEn = "Boost savings to 25% of disposable margin while trimming daily discretionary.";
                stepsAr.Add("حجز 25% للادخار فور نزول الراتب.");
                stepsAr.Add($"الالتزام بسقف صرف يومي لا يتجاوز {optDailySpend:N0} ريال.");
                stepsEn.Add("Transfer 25% savings immediately upon income receipt.");
                stepsEn.Add($"Adhere to a daily spend cap of {optDailySpend:N0} SAR.");
                break;

            case "reducedebt":
            case "preparecommitment":
                optSavings = afterCommitments * 0.10m;
                optEmergency = afterCommitments * 0.20m;
                decimal discDebt = afterCommitments - optSavings - optEmergency;
                optDailySpend = discDebt / 30m;
                rationaleAr = "تخصيص احتياطي وقائي 20% لتغطية الالتزامات الكبيرة وتفادي أي ضغوط سداد.";
                rationaleEn = "Allocate a 20% dedicated reserve for large upcoming obligations.";
                stepsAr.Add("حجز رصيد دوري للالتزامات السنوية.");
                stepsAr.Add($"تحديد سقف الصرف اليومي عند {optDailySpend:N0} ريال.");
                stepsEn.Add("Reserve recurring portions for annual commitments.");
                stepsEn.Add($"Set daily spending ceiling to {optDailySpend:N0} SAR.");
                break;

            case "conservative":
                optSavings = afterCommitments * 0.15m;
                optEmergency = afterCommitments * 0.20m;
                decimal discCons = afterCommitments - optSavings - optEmergency;
                optDailySpend = discCons / 30m;
                rationaleAr = "خطة تحوطية تعزز صندوق الطوارئ والسيولة المباشرة.";
                rationaleEn = "Conservative model maximizing emergency buffer and immediate liquidity.";
                stepsAr.Add("دعم صندوق الطوارئ حتى بلوغ أمان 3 أشهر.");
                stepsEn.Add("Fortify emergency fund toward 3-month living benchmark.");
                break;

            case "balanced":
            default:
                optSavings = afterCommitments * 0.15m;
                optEmergency = afterCommitments * 0.08m;
                decimal discBal = afterCommitments - optSavings - optEmergency;
                optDailySpend = discBal / 30m;
                rationaleAr = "توزيع متوازن يوفر مرونة للصرف اليومي مع استمرار نمو المدخرات والطوارئ.";
                rationaleEn = "Balanced distribution preserving daily flexibility while growing savings and reserves.";
                stepsAr.Add($"حجز مبالغ الالتزامات فوراً بقيمة {commitments:N0} ريال.");
                stepsAr.Add($"تخصيص {optSavings:N0} ريال للادخار و {optEmergency:N0} ريال للطوارئ.");
                stepsAr.Add($"سقف صرف يومي مرن يبلغ {optDailySpend:N0} ريال.");
                stepsEn.Add($"Immediately ring-fence commitments of {commitments:N0} SAR.");
                stepsEn.Add($"Allocate {optSavings:N0} SAR for savings and {optEmergency:N0} SAR for reserve.");
                stepsEn.Add($"Maintain a daily spending pace of {optDailySpend:N0} SAR.");
                break;
        }

        var optPlan = new BudgetPlanComparisonDto(
            "الخطة المحسّنة (ميزان AI)",
            "Mizan AI Optimized Plan",
            Math.Round(optDailySpend, 2),
            Math.Round(optSavings, 2),
            Math.Round(optEmergency, 2),
            commitments,
            Math.Round(optDailySpend * 30, 2),
            rationaleAr,
            rationaleEn
        );

        string explAr = $"تساعدك إعادة الجدولة على حجز الالتزامات مسبقاً بقيمة {commitments:N0} ريال، " +
            $"وضبط الصرف اليومي عند {optDailySpend:N0} ريال مع استمرار الادخار بانتظام.";

        string explEn = $"Rescheduling helps ring-fence commitments of {commitments:N0} SAR upfront, " +
            $"anchoring daily spend at {optDailySpend:N0} SAR while building steady savings.";

        return new BudgetOptimizationResult(currentPlan, optPlan, explAr, explEn, stepsAr, stepsEn);
    }
}

public class PurchaseFeasibilityEngine : IPurchaseFeasibilityEngine
{
    public PurchaseScenarioResult CalculatePurchaseScenario(PurchaseScenarioRequest request, FinancialContextDto context)
    {
        decimal amount = Math.Max(0m, request.PurchaseAmount);
        string itemName = string.IsNullOrWhiteSpace(request.ItemName) ? "السلعة" : request.ItemName.Trim();
        decimal availableBefore = context.AvailableToSpend;
        decimal availableAfter = availableBefore - amount;

        int daysLeft = Math.Max(1, context.DaysRemaining);
        decimal currentDailySpend = Math.Round(availableBefore / daysLeft, 1);
        decimal newDailySpend = Math.Max(0m, Math.Round(availableAfter / daysLeft, 1));

        string ratingAr;
        string ratingEn;

        if (availableAfter >= context.EmergencyReserve)
        {
            ratingAr = "مريح";
            ratingEn = "Comfortable";
        }
        else if (availableAfter >= 0)
        {
            ratingAr = "قابل للإدارة";
            ratingEn = "Manageable";
        }
        else if (availableAfter >= -context.EmergencyReserve)
        {
            ratingAr = "يحتاج تعديل";
            ratingEn = "Needs Adjustment";
        }
        else
        {
            ratingAr = "ضغط مرتفع جداً";
            ratingEn = "Very High Pressure";
        }

        string explAr = availableAfter >= 0
            ? $"تقدر تغطي قيمة {itemName} من رصيدك الحالي، لكن بعد حجز التزاماتك القادمة والشراء سينخفض المبلغ المتاح للصرف إلى {availableAfter:N0} ريال.\n" +
              $"هذا سيخفض سقف الصرف اليومي المقترح من {currentDailySpend:N0} إلى {newDailySpend:N0} ريال حتى موعد الراتب القادم."
            : $"شراء {itemName} بقيمة {amount:N0} ريال سيتجاوز السيولة المتاحة حالياً بعد حجز الالتزامات ويحدث عجزاً بقيمة {Math.Abs(availableAfter):N0} ريال.\n" +
              $"يُنصح بتأجيل الشراء أو تقسيمه لتفادي السحب من صندوق الطوارئ.";

        string explEn = availableAfter >= 0
            ? $"You can afford {itemName} from current liquidity, but reserving commitments and executing the purchase contracts available margin to {availableAfter:N0} SAR.\n" +
              $"This reduces safe daily spending pace from {currentDailySpend:N0} to {newDailySpend:N0} SAR until next salary."
            : $"Purchasing {itemName} for {amount:N0} SAR exceeds currently available liquidity after ring-fencing obligations by {Math.Abs(availableAfter):N0} SAR.\n" +
              $"We recommend rescheduling to avoid drawing down emergency reserves.";

        var card = new StructuredAICardDto(
            "PurchaseScenarioCard",
            $"فحص إمكانية شراء {itemName}",
            $"Purchase Feasibility: {itemName}",
            new Dictionary<string, object?>
            {
                ["itemName"] = itemName,
                ["purchaseAmount"] = amount,
                ["availableBefore"] = availableBefore,
                ["availableAfter"] = Math.Max(0m, availableAfter),
                ["currentDailySpend"] = Math.Round(currentDailySpend, 1),
                ["newDailySpend"] = Math.Round(newDailySpend, 1),
                ["feasibilityRatingAr"] = ratingAr,
                ["feasibilityRatingEn"] = ratingEn,
                ["isAffordable"] = availableAfter >= 0
            }
        );

        return new PurchaseScenarioResult(
            amount,
            itemName,
            availableBefore,
            availableAfter,
            Math.Round(currentDailySpend, 1),
            Math.Round(newDailySpend, 1),
            ratingAr,
            ratingEn,
            explAr,
            explEn,
            card
        );
    }
}

public class FinancialPlanEngine : IFinancialPlanEngine
{
    public FinancialPlanResult CalculateSalaryPlan(FinancialPlanRequest request, FinancialContextDto context)
    {
        decimal income = request.CustomIncome ?? (context.MonthlyIncome > 0 ? context.MonthlyIncome : 6960.45m);
        decimal commitments = context.MonthlyCommitments > 0 ? context.MonthlyCommitments : 1671.35m;
        decimal savings = Math.Round(income * 0.15m, 0); // 15% savings
        decimal emergency = Math.Round(income * 0.07m, 0); // 7% emergency buffer
        decimal available = Math.Max(0m, income - commitments - savings - emergency);
        decimal safeDaily = Math.Round(available / 30m, 1);

        string explAr = $"بناءً على دخل شهري {income:N0} ريال:\n" +
                        $"• حجز الالتزامات الثابتة: {commitments:N0} ريال\n" +
                        $"• ادخار مستهدف: {savings:N0} ريال\n" +
                        $"• احتياطي طوارئ: {emergency:N0} ريال\n" +
                        $"• متاح لمصروفات الشهر: {available:N0} ريال (سقف يومي: {safeDaily:N0} ريال/يوم).";

        string explEn = $"Based on monthly income of {income:N0} SAR:\n" +
                        $"• Ring-fenced Commitments: {commitments:N0} SAR\n" +
                        $"• Target Savings: {savings:N0} SAR\n" +
                        $"• Emergency Buffer: {emergency:N0} SAR\n" +
                        $"• Available for Monthly Spend: {available:N0} SAR (Safe daily pace: {safeDaily:N0} SAR/day).";

        var card = new StructuredAICardDto(
            "BudgetPlanCard",
            "خطة توزيع الراتب المقترحة",
            "Proposed Salary Allocation Plan",
            new Dictionary<string, object?>
            {
                ["income"] = income,
                ["commitments"] = commitments,
                ["savings"] = savings,
                ["emergency"] = emergency,
                ["availableToSpend"] = available,
                ["safeDailySpend"] = safeDaily
            },
            "تطبيق الخطة",
            "Apply Plan",
            "action_apply_plan"
        );

        return new FinancialPlanResult(
            income,
            commitments,
            savings,
            emergency,
            available,
            safeDaily,
            explAr,
            explEn,
            card
        );
    }
}

