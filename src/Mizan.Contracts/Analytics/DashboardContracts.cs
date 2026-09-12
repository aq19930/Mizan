using Mizan.Contracts.Transactions;
using Mizan.Contracts.Commitments;

namespace Mizan.Contracts.Analytics;

public record CategorySpendingItem(
    Guid? CategoryId,
    string CategoryNameAr,
    string CategoryNameEn,
    string Icon,
    string ColorHex,
    decimal SpentAmount,
    double Percentage
);

public record DailyForecastItem(
    DateTime Date,
    decimal ExpectedSpend,
    decimal LowerBound,
    decimal UpperBound,
    double Confidence
);

public record DashboardSummaryResponse(
    decimal CurrentBalance,
    decimal SpentToday,
    decimal DailyLimit,
    decimal ExpectedTomorrow,
    string BudgetHealth,
    IReadOnlyList<TransactionResponse> RecentTransactions,
    IReadOnlyList<CategorySpendingItem> SpendingByCategory,
    string AiInsightAr,
    string AiInsightEn,
    decimal CommittedAmount = 0,
    decimal AvailableToSpend = 0,
    decimal UpcomingCommitmentsTotal = 0,
    IReadOnlyList<CommitmentResponse>? UpcomingCommitments = null
);
