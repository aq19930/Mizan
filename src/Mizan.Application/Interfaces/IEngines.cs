using Mizan.Domain.Enums;

namespace Mizan.Application.Interfaces;

public interface IBalanceEngine
{
    decimal CalculateNewBalance(decimal currentBalance, TransactionType type, decimal amount, decimal fee = 0m);
    TransactionDirection GetDirection(TransactionType type);
    bool IsExpense(TransactionType type);
    bool IsIncome(TransactionType type);
}

public class BudgetHealthReport
{
    public decimal BudgetTotal { get; set; }
    public decimal BudgetSpent { get; set; }
    public decimal BudgetRemaining { get; set; }
    public double PercentageUsed { get; set; }
    public int DaysRemaining { get; set; }
    public decimal RecommendedDailyLimit { get; set; }
    public BudgetStatus Status { get; set; }
    
    // Commitments & Reserves
    public decimal CommittedAmount { get; set; }
    public decimal AvailableForSpending { get; set; }
    public decimal EmergencyReserve { get; set; }
    public decimal SavingsReserve { get; set; }
}

public interface IBudgetEngine
{
    BudgetHealthReport EvaluateBudget(decimal totalBudget, decimal totalSpent, DateTime currentDate);
    
    BudgetHealthReport EvaluateBudgetWithCommitments(
        decimal totalBudget,
        decimal totalSpent,
        decimal currentBalance,
        decimal committedAmount,
        decimal emergencyReserve,
        decimal savingsReserve,
        DateTime currentDate
    );
}
