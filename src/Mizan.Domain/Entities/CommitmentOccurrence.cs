using Mizan.Domain.Enums;

namespace Mizan.Domain.Entities;

public class CommitmentOccurrence
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CommitmentId { get; set; }
    public DateTime ExpectedDate { get; set; }
    public decimal ExpectedAmount { get; set; }
    public Guid? ActualTransactionId { get; set; }
    public OccurrenceStatus Status { get; set; } = OccurrenceStatus.Pending;
    public DateTime? PaidAt { get; set; }
    public decimal? ActualAmount { get; set; }

    public FinancialCommitment? Commitment { get; set; }
    public Transaction? ActualTransaction { get; set; }
}
