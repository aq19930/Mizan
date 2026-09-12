using Microsoft.EntityFrameworkCore;
using Mizan.Domain.Entities;

namespace Mizan.Infrastructure.Persistence;

public class MizanDbContext : DbContext
{
    public MizanDbContext(DbContextOptions<MizanDbContext> options) : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<Wallet> Wallets => Set<Wallet>();
    public DbSet<Transaction> Transactions => Set<Transaction>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Budget> Budgets => Set<Budget>();
    public DbSet<MerchantRule> MerchantRules => Set<MerchantRule>();
    public DbSet<DailySummary> DailySummaries => Set<DailySummary>();
    public DbSet<AIInsight> AIInsights => Set<AIInsight>();
    public DbSet<FinancialCommitment> FinancialCommitments => Set<FinancialCommitment>();
    public DbSet<CommitmentOccurrence> CommitmentOccurrences => Set<CommitmentOccurrence>();
    public DbSet<FinancialAccount> FinancialAccounts => Set<FinancialAccount>();
    public DbSet<IncomeRule> IncomeRules => Set<IncomeRule>();
    public DbSet<AIConversation> AIConversations => Set<AIConversation>();
    public DbSet<AIMessage> AIMessages => Set<AIMessage>();
    public DbSet<UserDeviceToken> UserDeviceTokens => Set<UserDeviceToken>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // User indexes & configuration
        modelBuilder.Entity<User>()
            .HasIndex(u => u.Email)
            .IsUnique();

        // Transaction indexes and relations
        modelBuilder.Entity<Transaction>()
            .HasOne(t => t.Wallet)
            .WithMany(w => w.Transactions)
            .HasForeignKey(t => t.WalletId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Transaction>()
            .HasIndex(t => t.UserId);
        modelBuilder.Entity<Transaction>()
            .HasIndex(t => t.TransactionDate);
        modelBuilder.Entity<Transaction>()
            .HasIndex(t => t.Fingerprint);
        modelBuilder.Entity<Transaction>()
            .HasIndex(t => t.NormalizedMerchant);

        // Commitment indexes
        modelBuilder.Entity<FinancialCommitment>()
            .HasIndex(c => c.UserId);
        modelBuilder.Entity<FinancialCommitment>()
            .HasIndex(c => c.NextDueDate);
        modelBuilder.Entity<FinancialCommitment>()
            .HasIndex(c => c.Status);
        modelBuilder.Entity<FinancialCommitment>()
            .HasIndex(c => c.Category);

        modelBuilder.Entity<CommitmentOccurrence>()
            .HasIndex(o => o.CommitmentId);
        modelBuilder.Entity<CommitmentOccurrence>()
            .HasIndex(o => o.ExpectedDate);
        modelBuilder.Entity<CommitmentOccurrence>()
            .HasIndex(o => o.ActualTransactionId);
        modelBuilder.Entity<CommitmentOccurrence>()
            .HasIndex(o => o.Status);

        // FinancialAccount and IncomeRule indexes
        modelBuilder.Entity<FinancialAccount>()
            .HasIndex(a => a.UserId);
        modelBuilder.Entity<FinancialAccount>()
            .HasIndex(a => a.AccountSuffix);
        modelBuilder.Entity<IncomeRule>()
            .HasIndex(r => r.UserId);

        // UserDeviceToken indexes
        modelBuilder.Entity<UserDeviceToken>()
            .HasIndex(d => d.UserId);
        modelBuilder.Entity<UserDeviceToken>()
            .HasIndex(d => d.Token);
        modelBuilder.Entity<UserDeviceToken>()
            .HasIndex(d => d.IsActive);

        // Precision for monetary values
        modelBuilder.Entity<Wallet>()
            .Property(w => w.InitialBalance)
            .HasPrecision(18, 2);
        modelBuilder.Entity<Wallet>()
            .Property(w => w.CurrentBalance)
            .HasPrecision(18, 2);
        modelBuilder.Entity<Transaction>()
            .Property(t => t.Amount)
            .HasPrecision(18, 2);
        modelBuilder.Entity<Transaction>()
            .Property(t => t.Fee)
            .HasPrecision(18, 2);
        modelBuilder.Entity<Transaction>()
            .Property(t => t.Tax)
            .HasPrecision(18, 2);
        modelBuilder.Entity<Transaction>()
            .Property(t => t.Cashback)
            .HasPrecision(18, 2);
        modelBuilder.Entity<Transaction>()
            .Property(t => t.TotalDebit)
            .HasPrecision(18, 2);
        modelBuilder.Entity<Transaction>()
            .Property(t => t.TotalCredit)
            .HasPrecision(18, 2);
        modelBuilder.Entity<IncomeRule>()
            .Property(r => r.MinAmount)
            .HasPrecision(18, 2);
        modelBuilder.Entity<IncomeRule>()
            .Property(r => r.MaxAmount)
            .HasPrecision(18, 2);
        modelBuilder.Entity<Budget>()
            .Property(b => b.Amount)
            .HasPrecision(18, 2);
        modelBuilder.Entity<FinancialCommitment>()
            .Property(c => c.Amount)
            .HasPrecision(18, 2);
        modelBuilder.Entity<CommitmentOccurrence>()
            .Property(o => o.ExpectedAmount)
            .HasPrecision(18, 2);
        modelBuilder.Entity<CommitmentOccurrence>()
            .Property(o => o.ActualAmount)
            .HasPrecision(18, 2);
        modelBuilder.Entity<DailySummary>()
            .Property(d => d.TotalSpent)
            .HasPrecision(18, 2);
        modelBuilder.Entity<DailySummary>()
            .Property(d => d.DailyBudget)
            .HasPrecision(18, 2);
        modelBuilder.Entity<DailySummary>()
            .Property(d => d.BalanceAtEnd)
            .HasPrecision(18, 2);
        modelBuilder.Entity<DailySummary>()
            .Property(d => d.ExpectedNextDay)
            .HasPrecision(18, 2);

        // Commitment relationships
        modelBuilder.Entity<FinancialCommitment>()
            .HasMany(c => c.Occurrences)
            .WithOne(o => o.Commitment)
            .HasForeignKey(o => o.CommitmentId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<CommitmentOccurrence>()
            .HasOne(o => o.ActualTransaction)
            .WithOne(t => t.CommitmentOccurrence)
            .HasForeignKey<CommitmentOccurrence>(o => o.ActualTransactionId)
            .OnDelete(DeleteBehavior.SetNull);

        // AI Conversation & Message indexes
        modelBuilder.Entity<AIConversation>()
            .HasIndex(c => c.UserId);
        modelBuilder.Entity<AIConversation>()
            .HasIndex(c => c.CreatedAt);

        modelBuilder.Entity<AIMessage>()
            .HasIndex(m => m.ConversationId);
        modelBuilder.Entity<AIMessage>()
            .HasIndex(m => m.CreatedAt);
    }
}
