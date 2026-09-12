namespace Mizan.Contracts.Settings;

public record UserSettingsResponse(
    bool NotificationTransactions,
    bool NotificationDailySummary,
    bool NotificationBudgetWarnings,
    bool NotificationBillReminders,
    bool SmartDetectionEnabled,
    string PreferredLanguage,
    string PreferredCurrency,
    string ThemeMode
);

public record UpdateSettingsRequest(
    bool? NotificationTransactions,
    bool? NotificationDailySummary,
    bool? NotificationBudgetWarnings,
    bool? NotificationBillReminders,
    bool? SmartDetectionEnabled,
    string? PreferredLanguage,
    string? PreferredCurrency,
    string? ThemeMode
);
