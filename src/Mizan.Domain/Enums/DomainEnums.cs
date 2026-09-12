namespace Mizan.Domain.Enums;

public enum TransactionType
{
    Purchase,
    TransferIn,
    TransferOut,
    LocalTransfer,
    BillPayment,
    PosPurchase,
    OnlinePurchase,
    AtmWithdrawal,
    Refund,
    Fee,
    Salary,
    Deposit,
    TrafficFine,
    GovernmentPayment,
    Subscription,
    BalanceAdjustment,
    Unknown
}

public enum TransactionDirection
{
    In,
    Out,
    Neutral
}

public enum TransactionSource
{
    Manual,
    Sms,
    Notification,
    BankApi,
    Imported
}

public enum BudgetStatus
{
    Healthy,
    Watch,
    Critical,
    Exceeded
}

public enum ConfidenceLevel
{
    Low,
    Medium,
    High
}
