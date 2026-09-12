using System.Text.RegularExpressions;
using Mizan.Contracts.AI;

namespace Mizan.Application.Services;

/// <summary>
/// Sanitizes financial context and user messages to ensure zero PII, 
/// zero raw bank SMS strings, zero full account numbers, OTPs, or credentials 
/// are ever dispatched to external AI models.
/// </summary>
public static class FinancialContextSanitizer
{
    private static readonly Regex CardRegex = new(@"\b(?:\d[ -]*?){13,16}\b", RegexOptions.Compiled);
    private static readonly Regex IbanRegex = new(@"\b[A-Z]{2}\d{2}[A-Z0-9]{10,30}\b", RegexOptions.Compiled | RegexOptions.IgnoreCase);
    private static readonly Regex JwtRegex = new(@"\beyJ[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*\b", RegexOptions.Compiled);
    private static readonly Regex OtpRegex = new(@"\b(?i)(?:otp|رمز التحقق|كود التفعيل|verification code)\s*[:=]?\s*([0-9A-Za-z]{4,8})\b", RegexOptions.Compiled);
    private static readonly Regex PasswordRegex = new(@"\b(?i)(?:password|كلمة المرور|الرمز السري)\s*[:=]?\s*(\S+)", RegexOptions.Compiled);
    private static readonly Regex NationalIdRegex = new(@"\b[12]\d{9}\b", RegexOptions.Compiled); // Saudi National ID / Iqama

    /// <summary>
    /// Strips any sensitive PII from incoming user text before passing it to AI prompts.
    /// </summary>
    public static string SanitizeUserPrompt(string rawPrompt)
    {
        if (string.IsNullOrWhiteSpace(rawPrompt)) return string.Empty;

        string sanitized = rawPrompt;

        // Strip JWT tokens
        sanitized = JwtRegex.Replace(sanitized, "[REDACTED_TOKEN]");

        // Strip OTPs & Passwords
        sanitized = OtpRegex.Replace(sanitized, "[REDACTED_OTP]");
        sanitized = PasswordRegex.Replace(sanitized, "[REDACTED_CREDENTIAL]");

        // Mask payment cards (preserve last 4 if present)
        sanitized = CardRegex.Replace(sanitized, match =>
        {
            var digits = Regex.Replace(match.Value, @"\D", "");
            return digits.Length >= 4 ? $"****-****-****-{digits[^4..]}" : "[REDACTED_CARD]";
        });

        // Mask IBANs
        sanitized = IbanRegex.Replace(sanitized, "[REDACTED_IBAN]");

        // Mask Saudi National ID / Iqama
        sanitized = NationalIdRegex.Replace(sanitized, "[REDACTED_ID]");

        return sanitized;
    }

    /// <summary>
    /// Generates a privacy-safe, structured text summary of the financial context
    /// containing only aggregated mathematical figures, category totals, and days remaining.
    /// </summary>
    public static string ToSafeSummaryPrompt(FinancialContextDto context)
    {
        var categoryList = context.Categories.Any()
            ? string.Join(", ", context.Categories.Select(c => $"{c.Key}: {c.Value:N0} {context.Currency}"))
            : "No category breakdown available";

        return $@"
[AUTHORIZED SANITIZED FINANCIAL CONTEXT]
Currency: {context.Currency}
Current Balance: {context.CurrentBalance:N2}
Available To Spend: {context.AvailableToSpend:N2}
Monthly Income: {context.MonthlyIncome:N2}
Monthly Spending: {context.MonthlySpending:N2}
Average Daily Spending: {context.AverageDailySpending:N2}
Monthly Commitments: {context.MonthlyCommitments:N2}
Upcoming Commitments (This Month): {context.UpcomingCommitments:N2}
Emergency Reserve: {context.EmergencyReserve:N2}
Savings Reserve: {context.SavingsReserve:N2}
Remaining Monthly Budget: {context.RemainingBudget:N2}
Days Remaining in Month: {context.DaysRemaining}
Commitment Ratio (DTI): {(context.CommitmentRatio * 100):F1}%
Top Spending Categories: {categoryList}
";
    }
}
