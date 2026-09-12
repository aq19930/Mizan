namespace Mizan.Contracts.Wallets;

public record CreateWalletRequest(
    string Name,
    decimal InitialBalance,
    string Currency = "SAR"
);

public record UpdateWalletRequest(
    string Name,
    decimal CurrentBalance
);

public record WalletResponse(
    Guid Id,
    string Name,
    decimal InitialBalance,
    decimal CurrentBalance,
    string Currency,
    DateTime CreatedAt,
    DateTime LastUpdated
);
