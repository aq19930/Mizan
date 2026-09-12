using Mizan.Contracts.AI;

namespace Mizan.Application.Interfaces;

public interface IFinancialHealthEngine
{
    FinancialHealthResult EvaluateHealth(FinancialContextDto context, int overdueCommitmentsCount);
}

public interface IFinancialForecastEngine
{
    FinancialForecastResult ForecastMonthEnd(FinancialContextDto context, int transactionCount, DateTime currentDate);
}

public interface ILoanCalculationEngine
{
    LoanScenarioResult CalculateLoanScenario(LoanScenarioRequest request, FinancialContextDto context);
    LoanCompareResult CompareLoans(LoanCompareRequest request, FinancialContextDto context);
}

public interface IFinancialSchedulingEngine
{
    BudgetOptimizationResult OptimizeBudget(BudgetOptimizationRequest request, FinancialContextDto context);
}

public interface IPurchaseFeasibilityEngine
{
    PurchaseScenarioResult CalculatePurchaseScenario(PurchaseScenarioRequest request, FinancialContextDto context);
}

public interface IFinancialPlanEngine
{
    FinancialPlanResult CalculateSalaryPlan(FinancialPlanRequest request, FinancialContextDto context);
}

public interface ICommitmentScheduleService
{
    Task<CommitmentScheduleResult> GetScheduleAsync(Guid userId, int months, DateTime currentDate);
}

public interface IFinancialContextService
{
    Task<FinancialContextDto> BuildContextAsync(Guid userId, DateTime currentDate);
}

public interface IAIProvider
{
    string ProviderName { get; }
    Task<string> GenerateResponseAsync(string systemPrompt, string userPrompt, string? conversationHistoryJson = null);
}

public interface IAIChatService
{
    Task<AIChatResponse> ProcessChatAsync(Guid userId, AIChatRequest request);
}
