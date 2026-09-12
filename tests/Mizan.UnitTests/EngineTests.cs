using Mizan.Application.Interfaces;
using Mizan.Application.Services;
using Mizan.Domain.Enums;
using Xunit;

namespace Mizan.UnitTests;

public class EngineTests
{
    private readonly IBalanceEngine _balanceEngine = new BalanceEngine();
    private readonly IBudgetEngine _budgetEngine = new BudgetEngine();

    [Theory]
    [InlineData(1000, TransactionType.Purchase, 150, 850)]
    [InlineData(1000, TransactionType.TransferOut, 200, 800)]
    [InlineData(1000, TransactionType.AtmWithdrawal, 300, 700)]
    [InlineData(1000, TransactionType.Fee, 15, 985)]
    [InlineData(1000, TransactionType.BillPayment, 250, 750)]
    [InlineData(1000, TransactionType.TransferIn, 500, 1500)]
    [InlineData(1000, TransactionType.Salary, 10000, 11000)]
    [InlineData(1000, TransactionType.Refund, 50, 1050)]
    [InlineData(1000, TransactionType.Deposit, 200, 1200)]
    public void BalanceEngine_ShouldCalculateAccurately(decimal start, TransactionType type, decimal amount, decimal expected)
    {
        var result = _balanceEngine.CalculateNewBalance(start, type, amount);
        Assert.Equal(expected, result);
    }

    [Fact]
    public void BudgetEngine_ShouldEvaluateHealthStatusCorrectly()
    {
        var date = new DateTime(2026, 9, 14); // 30 days in September, day 14 -> 17 days remaining
        
        // Healthy: 50% used
        var healthyReport = _budgetEngine.EvaluateBudget(5000, 2500, date);
        Assert.Equal(BudgetStatus.Healthy, healthyReport.Status);
        Assert.Equal(50.0, healthyReport.PercentageUsed);
        Assert.Equal(2500, healthyReport.BudgetRemaining);
        Assert.Equal(17, healthyReport.DaysRemaining);

        // Watch: 75% used
        var watchReport = _budgetEngine.EvaluateBudget(5000, 3750, date);
        Assert.Equal(BudgetStatus.Watch, watchReport.Status);

        // Critical: 90% used
        var criticalReport = _budgetEngine.EvaluateBudget(5000, 4500, date);
        Assert.Equal(BudgetStatus.Critical, criticalReport.Status);

        // Exceeded: 105% used
        var exceededReport = _budgetEngine.EvaluateBudget(5000, 5250, date);
        Assert.Equal(BudgetStatus.Exceeded, exceededReport.Status);
    }

    [Fact]
    public void BudgetEngine_ShouldCalculateCommitmentsAndAvailableToSpendCorrectly()
    {
        var date = new DateTime(2026, 9, 14); // 17 days remaining
        decimal totalBudget = 5000m;
        decimal totalSpent = 1500m;
        decimal currentBalance = 5000m;
        decimal committedAmount = 1800m; // e.g. Car: 1250, Mobile: 300, Internet: 250
        decimal emergencyReserve = 0m;
        decimal savingsReserve = 0m;

        var report = _budgetEngine.EvaluateBudgetWithCommitments(
            totalBudget,
            totalSpent,
            currentBalance,
            committedAmount,
            emergencyReserve,
            savingsReserve,
            date);

        // AvailableForSpending = 5000 - 1800 = 3200
        Assert.Equal(3200m, report.AvailableForSpending);
        Assert.Equal(1800m, report.CommittedAmount);
        // RecommendedDailyLimit = 3200 / 17 = 188.24
        Assert.Equal(188.24m, report.RecommendedDailyLimit);
    }

    [Fact]
    public void BalanceEngine_DeterministicRules_LocalTransferWithFee_DeductsBoth()
    {
        // 1000 - (15 + 0.58) = 984.42
        var newBalance = _balanceEngine.CalculateNewBalance(1000m, TransactionType.LocalTransfer, 15m, 0.58m);
        Assert.Equal(984.42m, newBalance);
        Assert.Equal(TransactionDirection.Out, _balanceEngine.GetDirection(TransactionType.LocalTransfer));
        Assert.True(_balanceEngine.IsExpense(TransactionType.LocalTransfer));
        Assert.False(_balanceEngine.IsIncome(TransactionType.LocalTransfer));
    }

    [Fact]
    public void BalanceEngine_DeterministicRules_TrafficFine_DeductsAmount()
    {
        // 1000 - 100 = 900
        var newBalance = _balanceEngine.CalculateNewBalance(1000m, TransactionType.TrafficFine, 100m);
        Assert.Equal(900m, newBalance);
        Assert.Equal(TransactionDirection.Out, _balanceEngine.GetDirection(TransactionType.TrafficFine));
    }

    [Fact]
    public void BalanceEngine_DeterministicRules_SalaryAndTransferIn_AddsAmount()
    {
        // Salary: 1000 + 6960.45 = 7960.45
        var salaryBalance = _balanceEngine.CalculateNewBalance(1000m, TransactionType.Salary, 6960.45m);
        Assert.Equal(7960.45m, salaryBalance);
        Assert.Equal(TransactionDirection.In, _balanceEngine.GetDirection(TransactionType.Salary));
        Assert.True(_balanceEngine.IsIncome(TransactionType.Salary));

        // Transfer In: 1000 + 6960.45 = 7960.45
        var transferBalance = _balanceEngine.CalculateNewBalance(1000m, TransactionType.TransferIn, 6960.45m);
        Assert.Equal(7960.45m, transferBalance);
        Assert.Equal(TransactionDirection.In, _balanceEngine.GetDirection(TransactionType.TransferIn));
        Assert.True(_balanceEngine.IsIncome(TransactionType.TransferIn));
    }

    [Fact]
    public void BalanceEngine_DeterministicRules_BillPaymentAndPosPurchase_DeductsAmount()
    {
        // Bill payment: 1000 - 171.35 = 828.65
        var billBalance = _balanceEngine.CalculateNewBalance(1000m, TransactionType.BillPayment, 171.35m);
        Assert.Equal(828.65m, billBalance);

        // POS Purchase: 1000 - 11.05 = 988.95
        var posBalance = _balanceEngine.CalculateNewBalance(1000m, TransactionType.PosPurchase, 11.05m);
        Assert.Equal(988.95m, posBalance);
    }
}
