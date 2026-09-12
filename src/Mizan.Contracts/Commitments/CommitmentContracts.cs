namespace Mizan.Contracts.Commitments;

public record CreateCommitmentRequest(
    string Title,
    string? Description,
    string Category,
    decimal Amount,
    string Currency,
    string Frequency,
    DateTime StartDate,
    DateTime DueDate,
    DateTime? EndDate = null,
    bool IsRecurring = true,
    bool AutoRenew = true,
    string Priority = "Medium",
    string? PaymentMethod = null,
    string? Merchant = null,
    string? Reference = null,
    int ReminderDaysBefore = 3
);

public record UpdateCommitmentRequest(
    string? Title,
    string? Description,
    string? Category,
    decimal? Amount,
    string? Currency,
    string? Frequency,
    DateTime? DueDate,
    DateTime? EndDate,
    string? Priority,
    string? PaymentMethod,
    string? Merchant,
    string? Reference,
    string? Status,
    int? ReminderDaysBefore
);

public record CommitmentOccurrenceResponse(
    Guid Id,
    Guid CommitmentId,
    DateTime ExpectedDate,
    decimal ExpectedAmount,
    Guid? ActualTransactionId,
    string Status,
    DateTime? PaidAt,
    decimal? ActualAmount
);

public record CommitmentResponse(
    Guid Id,
    Guid UserId,
    string Title,
    string? Description,
    string Category,
    string CategoryNameAr,
    string CategoryNameEn,
    decimal Amount,
    string Currency,
    string Frequency,
    DateTime StartDate,
    DateTime DueDate,
    DateTime NextDueDate,
    DateTime? EndDate,
    bool IsRecurring,
    bool AutoRenew,
    string Priority,
    string? PaymentMethod,
    string? Merchant,
    string? Reference,
    string Status,
    int ReminderDaysBefore,
    bool IsPaid,
    DateTime CreatedAt,
    IReadOnlyList<CommitmentOccurrenceResponse>? Occurrences = null
);

public record CommitmentSummaryResponse(
    decimal TotalMonthlyCommitments,
    decimal UpcomingThisMonthTotal,
    int DueSoonCount,
    int OverdueCount,
    IReadOnlyList<CommitmentResponse> Items
);

public record MatchCommitmentRequest(
    decimal TransactionAmount,
    string Merchant,
    DateTime TransactionDate,
    Guid? CategoryId = null
);

public record CommitmentMatchResponse(
    Guid? MatchedCommitmentId,
    string? CommitmentTitle,
    double ConfidenceScore,
    bool IsExactMatch,
    Guid? SuggestedOccurrenceId,
    string? RecommendationMessageAr,
    string? RecommendationMessageEn
);

public record MarkPaidRequest(
    Guid? OccurrenceId = null,
    decimal? ActualAmount = null,
    Guid? TransactionId = null
);
