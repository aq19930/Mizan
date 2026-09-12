using Mizan.Application.Interfaces;
using Mizan.Domain.Enums;

namespace Mizan.Application.Services;

public class BalanceEngine : IBalanceEngine
{
    public decimal CalculateNewBalance(decimal currentBalance, TransactionType type, decimal amount, decimal fee = 0m)
    {
        if (amount < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amount), "Amount cannot be negative.");
        }
        if (fee < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(fee), "Fee cannot be negative.");
        }

        return type switch
        {
            // Income types (IN) -> balance += amount
            TransactionType.Salary => currentBalance + amount,
            TransactionType.TransferIn => currentBalance + amount,
            TransactionType.Deposit => currentBalance + amount,
            TransactionType.Refund => currentBalance + amount,

            // Local transfer with fee -> balance -= amount + fee
            TransactionType.LocalTransfer => currentBalance - (amount + fee),

            // Expense types (OUT) -> balance -= amount + fee
            TransactionType.TransferOut => currentBalance - (amount + fee),
            TransactionType.BillPayment => currentBalance - (amount + fee),
            TransactionType.PosPurchase => currentBalance - (amount + fee),
            TransactionType.OnlinePurchase => currentBalance - (amount + fee),
            TransactionType.AtmWithdrawal => currentBalance - (amount + fee),
            TransactionType.TrafficFine => currentBalance - (amount + fee),
            TransactionType.GovernmentPayment => currentBalance - (amount + fee),
            TransactionType.Fee => currentBalance - (amount + fee),
            TransactionType.Subscription => currentBalance - (amount + fee),
            TransactionType.Purchase => currentBalance - (amount + fee),

            // Direct adjustment to target amount
            TransactionType.BalanceAdjustment => amount,

            // Neutral / Unknown
            TransactionType.Unknown => currentBalance,
            _ => throw new ArgumentOutOfRangeException(nameof(type), $"Unhandled transaction type: {type}")
        };
    }

    public TransactionDirection GetDirection(TransactionType type) => type switch
    {
        TransactionType.Salary => TransactionDirection.In,
        TransactionType.TransferIn => TransactionDirection.In,
        TransactionType.Deposit => TransactionDirection.In,
        TransactionType.Refund => TransactionDirection.In,

        TransactionType.LocalTransfer => TransactionDirection.Out,
        TransactionType.TransferOut => TransactionDirection.Out,
        TransactionType.BillPayment => TransactionDirection.Out,
        TransactionType.PosPurchase => TransactionDirection.Out,
        TransactionType.OnlinePurchase => TransactionDirection.Out,
        TransactionType.AtmWithdrawal => TransactionDirection.Out,
        TransactionType.TrafficFine => TransactionDirection.Out,
        TransactionType.GovernmentPayment => TransactionDirection.Out,
        TransactionType.Fee => TransactionDirection.Out,
        TransactionType.Subscription => TransactionDirection.Out,
        TransactionType.Purchase => TransactionDirection.Out,

        _ => TransactionDirection.Neutral
    };

    public bool IsExpense(TransactionType type) => GetDirection(type) == TransactionDirection.Out;

    public bool IsIncome(TransactionType type) => GetDirection(type) == TransactionDirection.In;
}

public class BudgetEngine : IBudgetEngine
{
    public BudgetHealthReport EvaluateBudget(decimal totalBudget, decimal totalSpent, DateTime currentDate)
    {
        return EvaluateBudgetWithCommitments(totalBudget, totalSpent, totalBudget, 0, 0, 0, currentDate);
    }

    public BudgetHealthReport EvaluateBudgetWithCommitments(
        decimal totalBudget,
        decimal totalSpent,
        decimal currentBalance,
        decimal committedAmount,
        decimal emergencyReserve,
        decimal savingsReserve,
        DateTime currentDate)
    {
        if (totalBudget < 0) throw new ArgumentOutOfRangeException(nameof(totalBudget));
        if (totalSpent < 0) throw new ArgumentOutOfRangeException(nameof(totalSpent));

        decimal remaining = Math.Max(0, totalBudget - totalSpent);
        double percentageUsed = totalBudget > 0 ? (double)(totalSpent / totalBudget) * 100 : 0;

        int daysInMonth = DateTime.DaysInMonth(currentDate.Year, currentDate.Month);
        int daysRemaining = Math.Max(1, daysInMonth - currentDate.Day + 1);

        // Section #51:
        // AvailableForSpending = CurrentBalance - UpcomingCommittedExpenses - EmergencyReserve - SavingsReserve
        decimal availableForSpending = Math.Max(0, currentBalance - committedAmount - emergencyReserve - savingsReserve);

        // RecommendedDailySpend = AvailableForSpending / RemainingDays
        decimal recommendedDaily = daysRemaining > 0 ? availableForSpending / daysRemaining : availableForSpending;

        BudgetStatus status = percentageUsed switch
        {
            < 70.0 => BudgetStatus.Healthy,
            < 85.0 => BudgetStatus.Watch,
            <= 100.0 => BudgetStatus.Critical,
            _ => BudgetStatus.Exceeded
        };

        return new BudgetHealthReport
        {
            BudgetTotal = totalBudget,
            BudgetSpent = totalSpent,
            BudgetRemaining = remaining,
            PercentageUsed = Math.Round(percentageUsed, 2),
            DaysRemaining = daysRemaining,
            RecommendedDailyLimit = Math.Round(recommendedDaily, 2),
            Status = status,
            CommittedAmount = committedAmount,
            AvailableForSpending = Math.Round(availableForSpending, 2),
            EmergencyReserve = emergencyReserve,
            SavingsReserve = savingsReserve
        };
    }
}
