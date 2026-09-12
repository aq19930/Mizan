namespace Mizan.Contracts.Transactions;

public record CreateTransactionRequest(
    Guid WalletId,
    int TransactionType,
    decimal Amount,
    string Currency,
    string Merchant,
    Guid? CategoryId,
    DateTime TransactionDate,
    string? Notes = null,
    string? ReferenceNumber = null
);

public record CreateDetectedTransactionRequest(
    string? Type,
    decimal Amount,
    string Currency,
    string Merchant,
    string? NormalizedMerchant,
    DateTime TransactionDate,
    string Source,
    double Confidence,
    string? MessageHash,
    string? ParserVersion,
    Guid? WalletId = null,
    Guid? CategoryId = null,
    string? ReferenceNumber = null,
    string? TransactionType = null,
    decimal Fee = 0m,
    decimal Tax = 0m,
    decimal Cashback = 0m,
    decimal? TotalDebit = null,
    decimal? TotalCredit = null,
    string? Direction = null,
    string? SourceAccount = null,
    string? DestinationAccount = null,
    string? AccountSuffix = null,
    string? RecipientName = null,
    string? DestinationBank = null,
    string? BillerCode = null,
    string? BillerName = null,
    string? ServiceType = null,
    string? BillNumber = null,
    string? PaymentMethod = null,
    string? CardLast4 = null,
    bool SalaryCandidate = false,
    double? Latitude = null,
    double? Longitude = null,
    double? LocationAccuracy = null,
    string? PlaceName = null,
    string? City = null,
    string? District = null
);

public record UpdateTransactionRequest(
    decimal? Amount,
    string? Merchant,
    Guid? CategoryId,
    DateTime? TransactionDate,
    string? Notes
);

public record TransactionResponse(
    Guid Id,
    Guid WalletId,
    int TransactionType,
    decimal Amount,
    string Currency,
    string Merchant,
    string NormalizedMerchant,
    Guid? CategoryId,
    string? CategoryNameAr,
    string? CategoryNameEn,
    string? CategoryIcon,
    string? CategoryColorHex,
    DateTime TransactionDate,
    int Source,
    double Confidence,
    bool IsVerified,
    string? Notes,
    string? ReferenceNumber,
    DateTime CreatedAt,
    decimal Fee = 0m,
    decimal TotalDebit = 0m,
    decimal TotalCredit = 0m,
    string Direction = "OUT",
    string? CardLast4 = null,
    string? RecipientName = null,
    string? BillerName = null,
    string? City = null,
    string? District = null
);

public record CreateFinancialAccountRequest(
    string BankName,
    string DisplayName,
    string MaskedAccountNumber,
    string AccountSuffix,
    string Currency = "SAR",
    bool IsPrimary = false
);

public record FinancialAccountResponse(
    Guid Id,
    Guid UserId,
    string BankName,
    string DisplayName,
    string MaskedAccountNumber,
    string AccountSuffix,
    string Currency,
    bool IsPrimary,
    DateTime CreatedAt
);

public record CreateIncomeRuleRequest(
    string SourcePattern,
    decimal MinAmount,
    decimal MaxAmount,
    int ExpectedDayStart = 25,
    int ExpectedDayEnd = 28,
    string? DestinationAccountSuffix = null,
    bool AutoClassify = true
);

public record IncomeRuleResponse(
    Guid Id,
    Guid UserId,
    string SourcePattern,
    decimal MinAmount,
    decimal MaxAmount,
    int ExpectedDayStart,
    int ExpectedDayEnd,
    string? DestinationAccountSuffix,
    bool AutoClassify,
    double Confidence,
    DateTime CreatedAt
);
