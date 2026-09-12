using Mizan.Domain.Enums;

namespace Mizan.Domain.Entities;

public class User
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string PreferredLanguage { get; set; } = "ar"; // ar or en
    public string PreferredCurrency { get; set; } = "SAR";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? LastLoginAt { get; set; }

    public bool AiAnalysisEnabled { get; set; } = true;
    public bool AiChatEnabled { get; set; } = true;
    public bool AiForecastingEnabled { get; set; } = true;
    public bool PersonalizedRecommendationsEnabled { get; set; } = true;

    public ICollection<Wallet> Wallets { get; set; } = new List<Wallet>();
    public ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
    public ICollection<Budget> Budgets { get; set; } = new List<Budget>();
    public ICollection<FinancialCommitment> Commitments { get; set; } = new List<FinancialCommitment>();
    public ICollection<FinancialAccount> FinancialAccounts { get; set; } = new List<FinancialAccount>();
    public ICollection<IncomeRule> IncomeRules { get; set; } = new List<IncomeRule>();
    public ICollection<AIConversation> AIConversations { get; set; } = new List<AIConversation>();
    public ICollection<UserDeviceToken> DeviceTokens { get; set; } = new List<UserDeviceToken>();
}

public class Wallet
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public string Name { get; set; } = "Main Wallet";
    public decimal InitialBalance { get; set; }
    public decimal CurrentBalance { get; set; }
    public string Currency { get; set; } = "SAR";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime LastUpdated { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
    public ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
}

public class Category
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Key { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public string NameAr { get; set; } = string.Empty;
    public string Icon { get; set; } = string.Empty;
    public string ColorHex { get; set; } = string.Empty;
    public bool IsDefault { get; set; } = true;
    public Guid? UserId { get; set; } // null if default system category
}

public class Transaction
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public Guid WalletId { get; set; }
    public TransactionType TransactionType { get; set; } = TransactionType.Purchase;
    public decimal Amount { get; set; }
    public decimal Fee { get; set; } = 0m;
    public decimal Tax { get; set; } = 0m;
    public decimal Cashback { get; set; } = 0m;
    public decimal TotalDebit { get; set; } = 0m;
    public decimal TotalCredit { get; set; } = 0m;
    public TransactionDirection Direction { get; set; } = TransactionDirection.Out;
    public string Currency { get; set; } = "SAR";
    public string Merchant { get; set; } = string.Empty;
    public string NormalizedMerchant { get; set; } = string.Empty;
    public Guid? CategoryId { get; set; }
    public string? Subcategory { get; set; }
    public Guid? FinancialAccountId { get; set; }
    public string? BillerCode { get; set; }
    public string? BillerName { get; set; }
    public string? ServiceType { get; set; }
    public string? BillNumber { get; set; }
    public string? RecipientName { get; set; }
    public string? DestinationAccount { get; set; }
    public string? DestinationBank { get; set; }
    public string? PaymentMethod { get; set; }
    public string? CardLast4 { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public double? LocationAccuracy { get; set; }
    public string? PlaceName { get; set; }
    public string? City { get; set; }
    public string? District { get; set; }
    public DateTime? LocationCapturedAt { get; set; }
    public DateTime TransactionDate { get; set; } = DateTime.UtcNow;
    public TransactionSource Source { get; set; } = TransactionSource.Manual;
    public double Confidence { get; set; } = 1.0;
    public bool IsVerified { get; set; } = true;
    public string? ReferenceNumber { get; set; }
    public string? Fingerprint { get; set; }
    public string? Notes { get; set; }
    public string? RawMessageHash { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
    public Wallet? Wallet { get; set; }
    public Category? Category { get; set; }
    public FinancialAccount? FinancialAccount { get; set; }
    public Guid? CommitmentOccurrenceId { get; set; }
    public CommitmentOccurrence? CommitmentOccurrence { get; set; }
}

public class Budget
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public Guid? CategoryId { get; set; } // null for overall monthly budget
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "SAR";
    public int Month { get; set; }
    public int Year { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
    public Category? Category { get; set; }
}

public class MerchantRule
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid? UserId { get; set; } // null for system-wide rule
    public string Pattern { get; set; } = string.Empty;
    public string NormalizedName { get; set; } = string.Empty;
    public Guid TargetCategoryId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class DailySummary
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public DateTime Date { get; set; }
    public decimal TotalSpent { get; set; }
    public decimal DailyBudget { get; set; }
    public decimal BalanceAtEnd { get; set; }
    public decimal ExpectedNextDay { get; set; }
    public string SummaryTextAr { get; set; } = string.Empty;
    public string SummaryTextEn { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class AIInsight
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public string TitleAr { get; set; } = string.Empty;
    public string TitleEn { get; set; } = string.Empty;
    public string MessageAr { get; set; } = string.Empty;
    public string MessageEn { get; set; } = string.Empty;
    public string Type { get; set; } = "SpendingAnalysis"; // SpendingAnalysis, BudgetWarning, Forecast
    public double Confidence { get; set; } = 0.85;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class FinancialAccount
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public string BankName { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string MaskedAccountNumber { get; set; } = string.Empty;
    public string AccountSuffix { get; set; } = string.Empty; // e.g. "2001"
    public string Currency { get; set; } = "SAR";
    public bool IsPrimary { get; set; } = false;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
    public ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
}

public class IncomeRule
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public string SourcePattern { get; set; } = string.Empty;
    public decimal MinAmount { get; set; }
    public decimal MaxAmount { get; set; }
    public int ExpectedDayStart { get; set; } = 25;
    public int ExpectedDayEnd { get; set; } = 28;
    public string? DestinationAccountSuffix { get; set; }
    public bool AutoClassify { get; set; } = true;
    public double Confidence { get; set; } = 0.92;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
}

public class AIConversation
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public string Title { get; set; } = "محادثة جديدة";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
    public ICollection<AIMessage> Messages { get; set; } = new List<AIMessage>();
}

public class AIMessage
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ConversationId { get; set; }
    public string Role { get; set; } = "user"; // user or assistant
    public string Content { get; set; } = string.Empty;
    public string? StructuredPayload { get; set; } // JSON format for visual cards, actions, etc.
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public AIConversation? Conversation { get; set; }
}
