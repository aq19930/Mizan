using Mizan.Domain.Enums;

namespace Mizan.Domain.Entities;

public class FinancialCommitment
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public CommitmentCategory Category { get; set; } = CommitmentCategory.Other;
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "SAR";
    public CommitmentFrequency Frequency { get; set; } = CommitmentFrequency.Monthly;
    public DateTime StartDate { get; set; } = DateTime.UtcNow;
    public DateTime DueDate { get; set; } = DateTime.UtcNow;
    public DateTime NextDueDate { get; set; } = DateTime.UtcNow;
    public DateTime? EndDate { get; set; }
    public bool IsRecurring { get; set; } = true;
    public bool AutoRenew { get; set; } = true;
    public CommitmentPriority Priority { get; set; } = CommitmentPriority.Medium;
    public string? PaymentMethod { get; set; }
    public string? Merchant { get; set; }
    public string? Reference { get; set; }
    public CommitmentStatus Status { get; set; } = CommitmentStatus.Active;
    public int ReminderDaysBefore { get; set; } = 3;
    public bool IsPaid { get; set; } = false;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
    public ICollection<CommitmentOccurrence> Occurrences { get; set; } = new List<CommitmentOccurrence>();
}
