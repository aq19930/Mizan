namespace Mizan.Domain.Enums;

public enum CommitmentCategory
{
    Housing,            // سكن
    Car,                // سيارة
    Loan,               // قرض
    CreditCard,         // بطاقة ائتمانية
    Utilities,          // فواتير خدمات
    Telecommunications, // اتصالات
    Insurance,          // تأمين
    Subscriptions,      // اشتراكات
    Education,          // تعليم
    Family,             // التزامات عائلية
    BNPL,               // تقسيط / اشتر الآن وادفع لاحقًا
    GovernmentFees,     // رسوم حكومية
    Healthcare,         // صحة
    Other               // أخرى
}

public enum CommitmentFrequency
{
    OneTime,
    Weekly,
    Monthly,
    Quarterly,
    SemiAnnual,
    Annual,
    Custom
}

public enum CommitmentStatus
{
    Active,
    Upcoming,
    Paid,
    Overdue,
    Paused,
    Completed,
    Cancelled
}

public enum CommitmentPriority
{
    Low,
    Medium,
    High,
    Critical
}

public enum OccurrenceStatus
{
    Pending,
    Upcoming,
    Paid,
    Overdue,
    Skipped,
    Cancelled
}
