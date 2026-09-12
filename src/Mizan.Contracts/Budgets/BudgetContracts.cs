namespace Mizan.Contracts.Budgets;

public record CreateBudgetRequest(
    Guid? CategoryId,
    decimal Amount,
    string Currency,
    int Month,
    int Year
);

public record UpdateBudgetRequest(
    decimal Amount
);

public record BudgetResponse(
    Guid Id,
    Guid? CategoryId,
    string? CategoryNameAr,
    string? CategoryNameEn,
    string? CategoryIcon,
    decimal Amount,
    decimal Spent,
    decimal Remaining,
    double Percentage,
    string Status
);
