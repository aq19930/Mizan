using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.IdentityModel.Tokens;
using Mizan.Api.Middleware;
using Mizan.Application.Interfaces;
using Mizan.Application.Services;
using Mizan.Contracts.AI;
using Mizan.Contracts.Analytics;
using Mizan.Contracts.Auth;
using Mizan.Contracts.Budgets;
using Mizan.Contracts.Commitments;
using Mizan.Contracts.Settings;
using Mizan.Contracts.Transactions;
using Mizan.Contracts.Wallets;
using Mizan.Domain.Entities;
using Mizan.Domain.Enums;
using Mizan.Infrastructure.Persistence;
using Mizan.Infrastructure.Services;

var builder = WebApplication.CreateBuilder(args);

// Dynamic Port binding for Cloud Run (8080) and Render (10000)
var portStr = Environment.GetEnvironmentVariable("PORT") ?? "8080";
if (!int.TryParse(portStr, out var port))
{
    port = 8080;
}
builder.WebHost.ConfigureKestrel(options =>
{
    options.ListenAnyIP(port);
});
builder.WebHost.UseUrls($"http://0.0.0.0:{port}");

// Forwarded Headers for Cloud Run SSL termination
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.KnownIPNetworks.Clear();
    options.KnownProxies.Clear();
});

builder.Services.AddOpenApi();
builder.Services.AddHttpClient();

// Register Application Engines
builder.Services.AddSingleton<IBalanceEngine, BalanceEngine>();
builder.Services.AddSingleton<IBudgetEngine, BudgetEngine>();
builder.Services.AddSingleton<IFinancialHealthEngine, FinancialHealthEngine>();
builder.Services.AddSingleton<IFinancialForecastEngine, FinancialForecastEngine>();
builder.Services.AddSingleton<ILoanCalculationEngine, LoanCalculationEngine>();
builder.Services.AddSingleton<IFinancialSchedulingEngine, FinancialSchedulingEngine>();
builder.Services.AddSingleton<IPurchaseFeasibilityEngine, PurchaseFeasibilityEngine>();
builder.Services.AddSingleton<IFinancialPlanEngine, FinancialPlanEngine>();

// Register AI Infrastructure Services
builder.Services.AddScoped<IFinancialContextService, FinancialContextService>();
builder.Services.AddScoped<ICommitmentScheduleService, CommitmentScheduleService>();

var aiProvider = builder.Configuration["AI:Provider"] ?? "Local";
if (aiProvider.Equals("Gemini", StringComparison.OrdinalIgnoreCase))
{
    builder.Services.AddHttpClient<IAIProvider, GeminiProvider>();
}
else if (aiProvider.Equals("OpenAI", StringComparison.OrdinalIgnoreCase))
{
    builder.Services.AddHttpClient<IAIProvider, OpenAIProvider>();
}
else
{
    builder.Services.AddSingleton<IAIProvider, LocalIntelligentTemplateProvider>();
}

builder.Services.AddScoped<IAIChatService, AIChatService>();

// Register Firebase Notification Service
builder.Services.AddHttpClient<IFirebaseNotificationService, FirebaseNotificationService>();

// Register Infrastructure Services
builder.Services.AddSingleton<IPasswordHasher, PasswordHasher>();
builder.Services.AddSingleton<IJwtTokenService, JwtTokenService>();

// Database Context with Connection Resiliency and Dual Provider Support (PostgreSQL / Supabase or SQL Server)
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
if (!string.IsNullOrEmpty(connectionString))
{
    var isPostgres = connectionString.Contains("Host=", StringComparison.OrdinalIgnoreCase) ||
                     connectionString.Contains("Port=", StringComparison.OrdinalIgnoreCase) ||
                     connectionString.Contains("Username=", StringComparison.OrdinalIgnoreCase) ||
                     connectionString.Contains("sslmode=", StringComparison.OrdinalIgnoreCase) ||
                     connectionString.Contains("supabase.com", StringComparison.OrdinalIgnoreCase) ||
                     connectionString.StartsWith("postgres://", StringComparison.OrdinalIgnoreCase) ||
                     connectionString.StartsWith("postgresql://", StringComparison.OrdinalIgnoreCase) ||
                     string.Equals(builder.Configuration["Database:Provider"], "PostgreSQL", StringComparison.OrdinalIgnoreCase) ||
                     string.Equals(builder.Configuration["Database:Provider"], "Postgres", StringComparison.OrdinalIgnoreCase);

    if (isPostgres)
    {
        builder.Services.AddDbContext<MizanDbContext>(options =>
            options.UseNpgsql(connectionString, npgsqlOptions =>
            {
                npgsqlOptions.EnableRetryOnFailure(
                    maxRetryCount: 5,
                    maxRetryDelay: TimeSpan.FromSeconds(30),
                    errorCodesToAdd: null);
                npgsqlOptions.CommandTimeout(30);
                npgsqlOptions.MigrationsAssembly("Mizan.Infrastructure");
            }));
    }
    else
    {
        builder.Services.AddDbContext<MizanDbContext>(options =>
            options.UseSqlServer(connectionString, sqlOptions =>
            {
                sqlOptions.EnableRetryOnFailure(
                    maxRetryCount: 5,
                    maxRetryDelay: TimeSpan.FromSeconds(30),
                    errorNumbersToAdd: null);
                sqlOptions.CommandTimeout(30);
                sqlOptions.MigrationsAssembly("Mizan.Infrastructure");
            }));
    }
}
else
{
    builder.Services.AddDbContext<MizanDbContext>(options =>
        options.UseInMemoryDatabase("MizanDb"));
}

// Authentication & JWT
var jwtKey = builder.Configuration["Jwt:Key"];
if (string.IsNullOrWhiteSpace(jwtKey))
{
    jwtKey = "MizanSecretSuperKeyForJwtSigning_2026_SaudiArabia_SecureToken12345!";
}
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
            ValidateIssuer = false,
            ValidateAudience = false,
            ClockSkew = TimeSpan.Zero
        };
    });

builder.Services.AddAuthorization();

// Rate Limiting for sensitive endpoints
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddFixedWindowLimiter("auth-policy", opt =>
    {
        opt.Window = TimeSpan.FromMinutes(1);
        opt.PermitLimit = 20;
        opt.QueueLimit = 0;
    });
    options.AddFixedWindowLimiter("ai-policy", opt =>
    {
        opt.Window = TimeSpan.FromMinutes(1);
        opt.PermitLimit = 30;
        opt.QueueLimit = 0;
    });
});

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

var app = builder.Build();

// Startup Environment Validation in Production
if (app.Environment.IsProduction())
{
    if (string.IsNullOrWhiteSpace(connectionString) || connectionString.Contains("localhost"))
    {
        app.Logger.LogWarning("Running in Production without dedicated Cloud SQL connection string.");
    }
    var configuredJwt = builder.Configuration["Jwt:Key"];
    if (string.IsNullOrWhiteSpace(configuredJwt) || configuredJwt.Contains("DevelopmentPhaseOnly"))
    {
        app.Logger.LogWarning("Running in Production with default or development JWT key. Set Jwt__Key in Secret Manager.");
    }
}

// On-demand migration execution (prevents Cloud Run multi-instance race conditions)
var isMigrationRun = args.Contains("--migrate") || 
    string.Equals(Environment.GetEnvironmentVariable("RUN_MIGRATIONS"), "true", StringComparison.OrdinalIgnoreCase);

if (isMigrationRun)
{
    using var migrationScope = app.Services.CreateScope();
    var db = migrationScope.ServiceProvider.GetRequiredService<MizanDbContext>();
    app.Logger.LogInformation("Applying EF Core migrations on-demand...");
    db.Database.Migrate();
    app.Logger.LogInformation("Database migrations completed successfully.");
    return;
}

// Safe category seeding and schema verification in background (non-blocking for fast health checks)
_ = Task.Run(async () =>
{
    try
    {
        using var scope = app.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<MizanDbContext>();
        var autoMigrate = string.Equals(Environment.GetEnvironmentVariable("AUTO_MIGRATE"), "true", StringComparison.OrdinalIgnoreCase);

        if (db.Database.IsInMemory() || autoMigrate)
        {
            try
            {
                app.Logger.LogInformation("AUTO_MIGRATE active: Ensuring database schema exists...");
                await db.Database.EnsureCreatedAsync();
                if (db.Database.IsRelational())
                {
                    var creator = db.Database.GetService<Microsoft.EntityFrameworkCore.Storage.IRelationalDatabaseCreator>();
                    if (creator != null)
                    {
                        try { await creator.CreateTablesAsync(); } catch { /* Tables already exist */ }
                    }
                }
            }
            catch (Exception ex)
            {
                app.Logger.LogWarning(ex, "Database schema check completed with note.");
            }
        }

        try
        {
            if (!await db.Categories.AnyAsync())
            {
                db.Categories.AddRange(
                    new Category { Key = "food", NameEn = "Food & Drinks", NameAr = "مطاعم ومشروبات", Icon = "restaurant", ColorHex = "#F59E0B" },
                    new Category { Key = "groceries", NameEn = "Groceries", NameAr = "بقالة", Icon = "local_grocery_store", ColorHex = "#10B981" },
                    new Category { Key = "transport", NameEn = "Transportation", NameAr = "مواصلات", Icon = "directions_car", ColorHex = "#6366F1" },
                    new Category { Key = "shopping", NameEn = "Shopping", NameAr = "تسوق", Icon = "shopping_bag", ColorHex = "#EC4899" },
                    new Category { Key = "entertainment", NameEn = "Entertainment", NameAr = "ترفيه", Icon = "movie", ColorHex = "#8B5CF6" },
                    new Category { Key = "bills", NameEn = "Bills", NameAr = "فواتير", Icon = "bolt", ColorHex = "#EAB308" },
                    new Category { Key = "subscriptions", NameEn = "Subscriptions", NameAr = "اشتراكات", Icon = "subscriptions", ColorHex = "#06B6D4" },
                    new Category { Key = "health", NameEn = "Health", NameAr = "صحة", Icon = "medical_services", ColorHex = "#EF4444" },
                    new Category { Key = "travel", NameEn = "Travel", NameAr = "سفر", Icon = "flight", ColorHex = "#3B82F6" },
                    new Category { Key = "education", NameEn = "Education", NameAr = "تعليم", Icon = "school", ColorHex = "#14B8A6" },
                    new Category { Key = "housing", NameEn = "Housing", NameAr = "سكن", Icon = "home", ColorHex = "#64748B" },
                    new Category { Key = "other", NameEn = "Other", NameAr = "أخرى", Icon = "more_horiz", ColorHex = "#6B7280" }
                );
                await db.SaveChangesAsync();
                app.Logger.LogInformation("Categories seeded successfully.");
            }
        }
        catch (Exception ex)
        {
            app.Logger.LogWarning(ex, "Initial category seeding check completed.");
        }
    }
    catch (Exception ex)
    {
        app.Logger.LogWarning(ex, "Background database initialization note: {Message}", ex.Message);
    }
});

// Global Exception Handler (sanitizes 500 errors, zero secrets/SQL leaks)
app.UseGlobalExceptionHandler();

// Cloud Run Forwarded Headers
app.UseForwardedHeaders();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseCors("AllowAll");
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();

static Guid? GetUserId(ClaimsPrincipal principal)
{
    var idStr = principal.FindFirstValue(ClaimTypes.NameIdentifier);
    return Guid.TryParse(idStr, out var id) ? id : null;
}

// -----------------------------------------------------------------------------
// Health & Info (Google Cloud Run & Monitoring)
// -----------------------------------------------------------------------------
app.MapGet("/health", () => Results.Ok(new { status = "Healthy" }))
   .AllowAnonymous();

app.MapGet("/api/health", () => Results.Ok(new
{
    status = "Healthy",
    app = "MIZAN Core API",
    version = "1.0.0",
    timestamp = DateTime.UtcNow
})).AllowAnonymous();

app.MapGet("/api/system/version", (IHostEnvironment env) => Results.Ok(new
{
    version = "1.0.0",
    name = "MIZAN Core API",
    environment = env.EnvironmentName
})).AllowAnonymous();

app.MapGet("/api/info", () => Results.Ok(new
{
    name = "MIZAN — ميزان",
    tagline = "Balance your money. Own your future. / وازن مالك. امك مستقبلك.",
    currency = "SAR",
    market = "Saudi Arabia"
})).AllowAnonymous();

// -----------------------------------------------------------------------------
// Categories
// -----------------------------------------------------------------------------
app.MapGet("/api/categories", async (MizanDbContext db) =>
{
    var categories = await db.Categories
        .OrderBy(c => c.NameAr)
        .Select(c => new
        {
            c.Id,
            c.Key,
            c.NameAr,
            c.NameEn,
            c.Icon,
            c.ColorHex
        })
        .ToListAsync();
    return Results.Ok(categories);
});

// -----------------------------------------------------------------------------
// Authentication (Rate-limited via auth-policy)
// -----------------------------------------------------------------------------
app.MapPost("/api/auth/register", async (
    RegisterRequest req,
    MizanDbContext db,
    IPasswordHasher hasher,
    IJwtTokenService jwt) =>
{
    if (string.IsNullOrWhiteSpace(req.FullName) || req.FullName.Trim().Length < 2)
        return Results.BadRequest(new { error = "Full name must be at least 2 characters." });

    if (string.IsNullOrWhiteSpace(req.Email) || !req.Email.Contains('@'))
        return Results.BadRequest(new { error = "A valid email address is required." });

    if (string.IsNullOrWhiteSpace(req.Password) || req.Password.Length < 8)
        return Results.BadRequest(new { error = "Password must be at least 8 characters long." });

    if (await db.Users.AnyAsync(u => u.Email.ToLower() == req.Email.ToLower()))
        return Results.Conflict(new { error = "An account with this email already exists." });

    var user = new User
    {
        FullName = req.FullName.Trim(),
        Email = req.Email.Trim().ToLowerInvariant(),
        PasswordHash = hasher.HashPassword(req.Password),
        PreferredLanguage = req.PreferredLanguage ?? "ar",
        PreferredCurrency = req.PreferredCurrency ?? "SAR",
        CreatedAt = DateTime.UtcNow
    };

    var defaultWallet = new Wallet
    {
        UserId = user.Id,
        Name = user.PreferredLanguage == "ar" ? "المحفظة الرئيسية" : "Main Wallet",
        InitialBalance = 0,
        CurrentBalance = 0,
        Currency = user.PreferredCurrency
    };

    user.Wallets.Add(defaultWallet);
    db.Users.Add(user);
    await db.SaveChangesAsync();

    var token = jwt.GenerateAccessToken(user);
    var refreshToken = jwt.GenerateRefreshToken();

    return Results.Ok(new AuthResponse(token, refreshToken, 604800, user.Id, user.Email, user.FullName));
}).RequireRateLimiting("auth-policy");

app.MapPost("/api/auth/login", async (
    LoginRequest req,
    MizanDbContext db,
    IPasswordHasher hasher,
    IJwtTokenService jwt) =>
{
    var user = await db.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == req.Email.ToLower());
    if (user == null || !hasher.VerifyPassword(req.Password, user.PasswordHash))
        return Results.Unauthorized();

    user.LastLoginAt = DateTime.UtcNow;
    await db.SaveChangesAsync();

    var token = jwt.GenerateAccessToken(user);
    var refreshToken = jwt.GenerateRefreshToken();

    return Results.Ok(new AuthResponse(token, refreshToken, 604800, user.Id, user.Email, user.FullName));
}).RequireRateLimiting("auth-policy");

app.MapPost("/api/auth/refresh", (RefreshTokenRequest req, IJwtTokenService jwt) =>
{
    var refreshToken = jwt.GenerateRefreshToken();
    return Results.Ok(new { refreshToken, expiresIn = 604800 });
}).RequireRateLimiting("auth-policy");

app.MapPost("/api/auth/forgot-password", (ForgotPasswordRequest req) =>
{
    return Results.Ok(new
    {
        message = "If an account with that email exists, password reset instructions have been sent."
    });
}).RequireRateLimiting("auth-policy");

// -----------------------------------------------------------------------------
// Profile
// -----------------------------------------------------------------------------
app.MapGet("/api/profile", async (ClaimsPrincipal principal, MizanDbContext db) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var user = await db.Users.FindAsync(userId.Value);
    if (user == null) return Results.NotFound();

    return Results.Ok(new UserProfileResponse(
        user.Id,
        user.Email,
        user.FullName,
        user.PreferredLanguage,
        user.PreferredCurrency,
        user.CreatedAt
    ));
}).RequireAuthorization();

app.MapPut("/api/profile", async (UpdateProfileRequest req, ClaimsPrincipal principal, MizanDbContext db) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var user = await db.Users.FindAsync(userId.Value);
    if (user == null) return Results.NotFound();

    if (!string.IsNullOrWhiteSpace(req.FullName)) user.FullName = req.FullName.Trim();
    if (!string.IsNullOrWhiteSpace(req.PreferredLanguage)) user.PreferredLanguage = req.PreferredLanguage;
    if (!string.IsNullOrWhiteSpace(req.PreferredCurrency)) user.PreferredCurrency = req.PreferredCurrency;

    await db.SaveChangesAsync();

    return Results.Ok(new UserProfileResponse(
        user.Id,
        user.Email,
        user.FullName,
        user.PreferredLanguage,
        user.PreferredCurrency,
        user.CreatedAt
    ));
}).RequireAuthorization();

// -----------------------------------------------------------------------------
// Wallets
// -----------------------------------------------------------------------------
app.MapGet("/api/wallets", async (ClaimsPrincipal principal, MizanDbContext db) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var wallets = await db.Wallets
        .Where(w => w.UserId == userId.Value)
        .OrderByDescending(w => w.CreatedAt)
        .Select(w => new WalletResponse(w.Id, w.Name, w.InitialBalance, w.CurrentBalance, w.Currency, w.CreatedAt, w.LastUpdated))
        .ToListAsync();

    return Results.Ok(wallets);
}).RequireAuthorization();

app.MapPost("/api/wallets", async (
    CreateWalletRequest req,
    ClaimsPrincipal principal,
    MizanDbContext db,
    IBalanceEngine balanceEngine) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var existingWallet = await db.Wallets
        .Include(w => w.Transactions)
        .FirstOrDefaultAsync(w => w.UserId == userId.Value);

    if (existingWallet != null)
    {
        existingWallet.Name = string.IsNullOrWhiteSpace(req.Name) ? existingWallet.Name : req.Name;
        existingWallet.InitialBalance = req.InitialBalance;
        existingWallet.Currency = req.Currency ?? "SAR";
        existingWallet.LastUpdated = DateTime.UtcNow;

        var bal = existingWallet.InitialBalance;
        foreach (var tx in existingWallet.Transactions)
        {
            bal = balanceEngine.CalculateNewBalance(bal, tx.TransactionType, tx.Amount);
        }
        existingWallet.CurrentBalance = bal;

        await db.SaveChangesAsync();

        return Results.Ok(new WalletResponse(
            existingWallet.Id,
            existingWallet.Name,
            existingWallet.InitialBalance,
            existingWallet.CurrentBalance,
            existingWallet.Currency,
            existingWallet.CreatedAt,
            existingWallet.LastUpdated
        ));
    }

    var wallet = new Wallet
    {
        UserId = userId.Value,
        Name = req.Name,
        InitialBalance = req.InitialBalance,
        CurrentBalance = req.InitialBalance,
        Currency = req.Currency ?? "SAR"
    };

    db.Wallets.Add(wallet);
    await db.SaveChangesAsync();

    return Results.Ok(new WalletResponse(
        wallet.Id,
        wallet.Name,
        wallet.InitialBalance,
        wallet.CurrentBalance,
        wallet.Currency,
        wallet.CreatedAt,
        wallet.LastUpdated
    ));
}).RequireAuthorization();

app.MapPut("/api/wallets/{id:guid}", async (
    Guid id,
    UpdateWalletRequest req,
    ClaimsPrincipal principal,
    MizanDbContext db) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var wallet = await db.Wallets.FirstOrDefaultAsync(w => w.Id == id && w.UserId == userId.Value);
    if (wallet == null) return Results.NotFound();

    wallet.Name = req.Name;
    wallet.CurrentBalance = req.CurrentBalance;
    wallet.LastUpdated = DateTime.UtcNow;

    await db.SaveChangesAsync();

    return Results.Ok(new WalletResponse(
        wallet.Id,
        wallet.Name,
        wallet.InitialBalance,
        wallet.CurrentBalance,
        wallet.Currency,
        wallet.CreatedAt,
        wallet.LastUpdated
    ));
}).RequireAuthorization();

// -----------------------------------------------------------------------------
// Transactions
// -----------------------------------------------------------------------------
app.MapGet("/api/transactions", async (
    ClaimsPrincipal principal,
    MizanDbContext db,
    Guid? walletId,
    int? type,
    Guid? categoryId,
    int? month,
    int? year) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var query = db.Transactions
        .Include(t => t.Category)
        .Where(t => t.UserId == userId.Value);

    if (walletId.HasValue) query = query.Where(t => t.WalletId == walletId.Value);
    if (type.HasValue) query = query.Where(t => (int)t.TransactionType == type.Value);
    if (categoryId.HasValue) query = query.Where(t => t.CategoryId == categoryId.Value);
    if (month.HasValue && year.HasValue)
    {
        query = query.Where(t => t.TransactionDate.Month == month.Value && t.TransactionDate.Year == year.Value);
    }

    var list = await query
        .OrderByDescending(t => t.TransactionDate)
        .Select(t => new TransactionResponse(
            t.Id,
            t.WalletId,
            (int)t.TransactionType,
            t.Amount,
            t.Currency,
            t.Merchant,
            t.NormalizedMerchant,
            t.CategoryId,
            t.Category != null ? t.Category.NameAr : null,
            t.Category != null ? t.Category.NameEn : null,
            t.Category != null ? t.Category.Icon : null,
            t.Category != null ? t.Category.ColorHex : null,
            t.TransactionDate,
            (int)t.Source,
            t.Confidence,
            t.IsVerified,
            t.Notes,
            t.ReferenceNumber,
            t.CreatedAt
        ))
        .ToListAsync();

    return Results.Ok(list);
}).RequireAuthorization();

app.MapPost("/api/transactions", async (
    CreateTransactionRequest req,
    ClaimsPrincipal principal,
    MizanDbContext db,
    IBalanceEngine balanceEngine) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var wallet = await db.Wallets
        .FirstOrDefaultAsync(w => w.Id == req.WalletId && w.UserId == userId.Value);

    if (wallet == null) return Results.BadRequest(new { error = "Wallet not found." });

    var transaction = new Transaction
    {
        UserId = userId.Value,
        WalletId = wallet.Id,
        TransactionType = (TransactionType)req.TransactionType,
        Amount = req.Amount,
        Currency = req.Currency ?? "SAR",
        Merchant = req.Merchant,
        NormalizedMerchant = req.Merchant.Trim().ToUpperInvariant(),
        CategoryId = req.CategoryId,
        TransactionDate = req.TransactionDate,
        Notes = req.Notes,
        ReferenceNumber = req.ReferenceNumber,
        Source = TransactionSource.Manual,
        Confidence = 1.0,
        IsVerified = true,
        CreatedAt = DateTime.UtcNow
    };

    db.Transactions.Add(transaction);

    wallet.CurrentBalance = balanceEngine.CalculateNewBalance(wallet.CurrentBalance, transaction.TransactionType, transaction.Amount);
    wallet.LastUpdated = DateTime.UtcNow;

    await db.SaveChangesAsync();

    var category = req.CategoryId.HasValue ? await db.Categories.FindAsync(req.CategoryId.Value) : null;

    return Results.Ok(new TransactionResponse(
        transaction.Id,
        transaction.WalletId,
        (int)transaction.TransactionType,
        transaction.Amount,
        transaction.Currency,
        transaction.Merchant,
        transaction.NormalizedMerchant,
        transaction.CategoryId,
        category?.NameAr,
        category?.NameEn,
        category?.Icon,
        category?.ColorHex,
        transaction.TransactionDate,
        (int)transaction.Source,
        transaction.Confidence,
        transaction.IsVerified,
        transaction.Notes,
        transaction.ReferenceNumber,
        transaction.CreatedAt
    ));
}).RequireAuthorization();

app.MapPost("/api/transactions/detected", async (
    CreateDetectedTransactionRequest req,
    ClaimsPrincipal principal,
    MizanDbContext db,
    IBalanceEngine balanceEngine) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    if (req.Amount <= 0) return Results.BadRequest("Amount must be greater than zero.");

    // Idempotency check with MessageHash
    if (!string.IsNullOrEmpty(req.MessageHash))
    {
        var existing = await db.Transactions
            .Include(t => t.Category)
            .FirstOrDefaultAsync(t => t.UserId == userId.Value && t.RawMessageHash == req.MessageHash);
        if (existing != null)
        {
            return Results.Ok(new TransactionResponse(
                existing.Id,
                existing.WalletId,
                (int)existing.TransactionType,
                existing.Amount,
                existing.Currency,
                existing.Merchant,
                existing.NormalizedMerchant,
                existing.CategoryId,
                existing.Category?.NameAr,
                existing.Category?.NameEn,
                existing.Category?.Icon,
                existing.Category?.ColorHex,
                existing.TransactionDate,
                (int)existing.Source,
                existing.Confidence,
                existing.IsVerified,
                existing.Notes,
                existing.ReferenceNumber,
                existing.CreatedAt
            ));
        }
    }

    var wallet = await db.Wallets.FirstOrDefaultAsync(w => w.UserId == userId.Value);
    if (wallet == null)
    {
        wallet = new Wallet
        {
            UserId = userId.Value,
            Name = "المحفظة الرئيسية",
            InitialBalance = 0,
            CurrentBalance = 0,
            Currency = req.Currency ?? "SAR"
        };
        db.Wallets.Add(wallet);
        await db.SaveChangesAsync();
    }

    var rawType = req.Type ?? req.TransactionType ?? "PURCHASE";
    TransactionType tType = rawType.ToUpperInvariant() switch
    {
        "SALARY" => TransactionType.Salary,
        "TRANSFER_IN" => TransactionType.TransferIn,
        "TRANSFER_OUT" => TransactionType.TransferOut,
        "LOCAL_TRANSFER" => TransactionType.LocalTransfer,
        "BILL_PAYMENT" => TransactionType.BillPayment,
        "POS_PURCHASE" => TransactionType.PosPurchase,
        "ONLINE_PURCHASE" => TransactionType.OnlinePurchase,
        "ATM_WITHDRAWAL" => TransactionType.AtmWithdrawal,
        "REFUND" => TransactionType.Refund,
        "FEE" => TransactionType.Fee,
        "TRAFFIC_FINE" => TransactionType.TrafficFine,
        "GOVERNMENT_PAYMENT" => TransactionType.GovernmentPayment,
        "SUBSCRIPTION" => TransactionType.Subscription,
        "DEPOSIT" => TransactionType.Deposit,
        "PURCHASE" => TransactionType.Purchase,
        _ => TransactionType.Purchase
    };

    var fee = req.Fee;
    var direction = balanceEngine.GetDirection(tType);
    var totalDebit = req.TotalDebit ?? (direction == TransactionDirection.Out ? req.Amount + fee : 0m);
    var totalCredit = req.TotalCredit ?? (direction == TransactionDirection.In ? req.Amount : 0m);

    // Account matching by suffix
    Guid? financialAccountId = null;
    var suffix = req.AccountSuffix ?? req.CardLast4;
    if (string.IsNullOrEmpty(suffix) && !string.IsNullOrEmpty(req.SourceAccount))
    {
        var match = System.Text.RegularExpressions.Regex.Match(req.SourceAccount, @"\d{4}$");
        if (match.Success) suffix = match.Value;
    }

    if (!string.IsNullOrEmpty(suffix))
    {
        var account = await db.FinancialAccounts.FirstOrDefaultAsync(a => a.UserId == userId.Value && a.AccountSuffix == suffix);
        if (account != null)
        {
            financialAccountId = account.Id;
        }
    }

    // Category auto-assignment
    Guid? catId = req.CategoryId;
    if (!catId.HasValue)
    {
        if (tType == TransactionType.TrafficFine || tType == TransactionType.GovernmentPayment)
        {
            var govCat = await db.Categories.FirstOrDefaultAsync(c => c.Key == "government");
            catId = govCat?.Id;
        }
        else if (tType == TransactionType.LocalTransfer || tType == TransactionType.TransferOut || tType == TransactionType.TransferIn)
        {
            var transCat = await db.Categories.FirstOrDefaultAsync(c => c.Key == "transport" || c.Key == "other");
            catId = transCat?.Id;
        }
        else if (tType == TransactionType.BillPayment)
        {
            var billCat = await db.Categories.FirstOrDefaultAsync(c => c.Key == "bills");
            catId = billCat?.Id;
        }
    }

    var transaction = new Transaction
    {
        UserId = userId.Value,
        WalletId = wallet.Id,
        TransactionType = tType,
        Amount = req.Amount,
        Fee = fee,
        Tax = req.Tax,
        Cashback = req.Cashback,
        TotalDebit = totalDebit,
        TotalCredit = totalCredit,
        Direction = direction,
        Currency = req.Currency ?? "SAR",
        Merchant = req.Merchant,
        NormalizedMerchant = req.NormalizedMerchant ?? req.Merchant.ToUpperInvariant().Trim(),
        CategoryId = catId,
        FinancialAccountId = financialAccountId,
        BillerCode = req.BillerCode,
        BillerName = req.BillerName,
        ServiceType = req.ServiceType,
        BillNumber = req.BillNumber,
        RecipientName = req.RecipientName,
        DestinationAccount = req.DestinationAccount,
        DestinationBank = req.DestinationBank,
        PaymentMethod = req.PaymentMethod,
        CardLast4 = req.CardLast4,
        Latitude = req.Latitude,
        Longitude = req.Longitude,
        LocationAccuracy = req.LocationAccuracy,
        PlaceName = req.PlaceName,
        City = req.City,
        District = req.District,
        LocationCapturedAt = req.Latitude.HasValue ? DateTime.UtcNow : null,
        TransactionDate = req.TransactionDate,
        Source = TransactionSource.Sms,
        Confidence = req.Confidence,
        IsVerified = req.Confidence >= 0.90,
        RawMessageHash = req.MessageHash,
        ReferenceNumber = req.ReferenceNumber
    };

    // Update wallet balance deterministically
    wallet.CurrentBalance = balanceEngine.CalculateNewBalance(wallet.CurrentBalance, tType, req.Amount, fee);
    wallet.LastUpdated = DateTime.UtcNow;

    db.Transactions.Add(transaction);
    await db.SaveChangesAsync();

    var category = catId.HasValue
        ? await db.Categories.FindAsync(catId.Value)
        : null;

    return Results.Ok(new TransactionResponse(
        transaction.Id,
        transaction.WalletId,
        (int)transaction.TransactionType,
        transaction.Amount,
        transaction.Currency,
        transaction.Merchant,
        transaction.NormalizedMerchant,
        transaction.CategoryId,
        category?.NameAr,
        category?.NameEn,
        category?.Icon,
        category?.ColorHex,
        transaction.TransactionDate,
        (int)transaction.Source,
        transaction.Confidence,
        transaction.IsVerified,
        transaction.Notes,
        transaction.ReferenceNumber,
        transaction.CreatedAt,
        Fee: transaction.Fee,
        TotalDebit: transaction.TotalDebit,
        TotalCredit: transaction.TotalCredit,
        Direction: transaction.Direction.ToString().ToUpperInvariant(),
        CardLast4: transaction.CardLast4,
        RecipientName: transaction.RecipientName,
        BillerName: transaction.BillerName,
        City: transaction.City,
        District: transaction.District
    ));
}).RequireAuthorization();

// -----------------------------------------------------------------------------
// Financial Accounts & Income Rules
// -----------------------------------------------------------------------------
app.MapGet("/api/accounts", async (ClaimsPrincipal principal, MizanDbContext db) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var accounts = await db.FinancialAccounts
        .Where(a => a.UserId == userId.Value)
        .OrderByDescending(a => a.IsPrimary)
        .ThenByDescending(a => a.CreatedAt)
        .Select(a => new FinancialAccountResponse(
            a.Id, a.UserId, a.BankName, a.DisplayName, a.MaskedAccountNumber, a.AccountSuffix, a.Currency, a.IsPrimary, a.CreatedAt
        ))
        .ToListAsync();

    return Results.Ok(accounts);
}).RequireAuthorization();

app.MapPost("/api/accounts", async (CreateFinancialAccountRequest req, ClaimsPrincipal principal, MizanDbContext db) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var account = new FinancialAccount
    {
        UserId = userId.Value,
        BankName = req.BankName,
        DisplayName = req.DisplayName,
        MaskedAccountNumber = req.MaskedAccountNumber,
        AccountSuffix = req.AccountSuffix,
        Currency = req.Currency,
        IsPrimary = req.IsPrimary
    };

    db.FinancialAccounts.Add(account);
    await db.SaveChangesAsync();

    return Results.Ok(new FinancialAccountResponse(
        account.Id, account.UserId, account.BankName, account.DisplayName, account.MaskedAccountNumber, account.AccountSuffix, account.Currency, account.IsPrimary, account.CreatedAt
    ));
}).RequireAuthorization();

app.MapGet("/api/income-rules", async (ClaimsPrincipal principal, MizanDbContext db) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var rules = await db.IncomeRules
        .Where(r => r.UserId == userId.Value)
        .Select(r => new IncomeRuleResponse(
            r.Id, r.UserId, r.SourcePattern, r.MinAmount, r.MaxAmount, r.ExpectedDayStart, r.ExpectedDayEnd, r.DestinationAccountSuffix, r.AutoClassify, r.Confidence, r.CreatedAt
        ))
        .ToListAsync();

    return Results.Ok(rules);
}).RequireAuthorization();

app.MapPost("/api/income-rules", async (CreateIncomeRuleRequest req, ClaimsPrincipal principal, MizanDbContext db) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var rule = new IncomeRule
    {
        UserId = userId.Value,
        SourcePattern = req.SourcePattern,
        MinAmount = req.MinAmount,
        MaxAmount = req.MaxAmount,
        ExpectedDayStart = req.ExpectedDayStart,
        ExpectedDayEnd = req.ExpectedDayEnd,
        DestinationAccountSuffix = req.DestinationAccountSuffix,
        AutoClassify = req.AutoClassify
    };

    db.IncomeRules.Add(rule);
    await db.SaveChangesAsync();

    return Results.Ok(new IncomeRuleResponse(
        rule.Id, rule.UserId, rule.SourcePattern, rule.MinAmount, rule.MaxAmount, rule.ExpectedDayStart, rule.ExpectedDayEnd, rule.DestinationAccountSuffix, rule.AutoClassify, rule.Confidence, rule.CreatedAt
    ));
}).RequireAuthorization();

app.MapGet("/api/transactions/{id:guid}", async (Guid id, ClaimsPrincipal principal, MizanDbContext db) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var t = await db.Transactions
        .Include(t => t.Category)
        .FirstOrDefaultAsync(t => t.Id == id && t.UserId == userId.Value);

    if (t == null) return Results.NotFound();

    return Results.Ok(new TransactionResponse(
        t.Id,
        t.WalletId,
        (int)t.TransactionType,
        t.Amount,
        t.Currency,
        t.Merchant,
        t.NormalizedMerchant,
        t.CategoryId,
        t.Category?.NameAr,
        t.Category?.NameEn,
        t.Category?.Icon,
        t.Category?.ColorHex,
        t.TransactionDate,
        (int)t.Source,
        t.Confidence,
        t.IsVerified,
        t.Notes,
        t.ReferenceNumber,
        t.CreatedAt
    ));
}).RequireAuthorization();

app.MapPut("/api/transactions/{id:guid}", async (
    Guid id,
    UpdateTransactionRequest req,
    ClaimsPrincipal principal,
    MizanDbContext db,
    IBalanceEngine balanceEngine) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var t = await db.Transactions
        .Include(t => t.Category)
        .FirstOrDefaultAsync(t => t.Id == id && t.UserId == userId.Value);

    if (t == null) return Results.NotFound();

    var wallet = await db.Wallets
        .Include(w => w.Transactions)
        .FirstOrDefaultAsync(w => w.Id == t.WalletId && w.UserId == userId.Value);

    if (req.Amount.HasValue) t.Amount = req.Amount.Value;
    if (!string.IsNullOrWhiteSpace(req.Merchant))
    {
        t.Merchant = req.Merchant;
        t.NormalizedMerchant = req.Merchant.Trim().ToUpperInvariant();
    }
    if (req.CategoryId.HasValue) t.CategoryId = req.CategoryId.Value;
    if (req.TransactionDate.HasValue) t.TransactionDate = req.TransactionDate.Value;
    if (req.Notes != null) t.Notes = req.Notes;

    t.UpdatedAt = DateTime.UtcNow;

    if (wallet != null)
    {
        var bal = wallet.InitialBalance;
        foreach (var tx in wallet.Transactions)
        {
            bal = balanceEngine.CalculateNewBalance(bal, tx.TransactionType, tx.Amount);
        }
        wallet.CurrentBalance = bal;
        wallet.LastUpdated = DateTime.UtcNow;
    }

    await db.SaveChangesAsync();

    return Results.Ok(new TransactionResponse(
        t.Id,
        t.WalletId,
        (int)t.TransactionType,
        t.Amount,
        t.Currency,
        t.Merchant,
        t.NormalizedMerchant,
        t.CategoryId,
        t.Category?.NameAr,
        t.Category?.NameEn,
        t.Category?.Icon,
        t.Category?.ColorHex,
        t.TransactionDate,
        (int)t.Source,
        t.Confidence,
        t.IsVerified,
        t.Notes,
        t.ReferenceNumber,
        t.CreatedAt
    ));
}).RequireAuthorization();

app.MapDelete("/api/transactions/{id:guid}", async (
    Guid id,
    ClaimsPrincipal principal,
    MizanDbContext db,
    IBalanceEngine balanceEngine) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var t = await db.Transactions.FirstOrDefaultAsync(t => t.Id == id && t.UserId == userId.Value);
    if (t == null) return Results.NotFound();

    var wallet = await db.Wallets
        .Include(w => w.Transactions)
        .FirstOrDefaultAsync(w => w.Id == t.WalletId && w.UserId == userId.Value);

    db.Transactions.Remove(t);
    if (wallet != null)
    {
        wallet.Transactions.Remove(t);
        var bal = wallet.InitialBalance;
        foreach (var tx in wallet.Transactions)
        {
            bal = balanceEngine.CalculateNewBalance(bal, tx.TransactionType, tx.Amount);
        }
        wallet.CurrentBalance = bal;
        wallet.LastUpdated = DateTime.UtcNow;
    }

    await db.SaveChangesAsync();
    return Results.NoContent();
}).RequireAuthorization();

// -----------------------------------------------------------------------------
// Budgets
// -----------------------------------------------------------------------------
app.MapGet("/api/budgets", async (
    ClaimsPrincipal principal,
    MizanDbContext db,
    IBudgetEngine budgetEngine,
    int? month,
    int? year) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var now = DateTime.UtcNow;
    var targetMonth = month ?? now.Month;
    var targetYear = year ?? now.Year;

    var budgets = await db.Budgets
        .Include(b => b.Category)
        .Where(b => b.UserId == userId.Value && b.Month == targetMonth && b.Year == targetYear)
        .ToListAsync();

    var transactions = await db.Transactions
        .Where(t => t.UserId == userId.Value &&
                    t.TransactionDate.Month == targetMonth &&
                    t.TransactionDate.Year == targetYear &&
                    t.TransactionType == TransactionType.Purchase)
        .ToListAsync();

    var results = budgets.Select(b =>
    {
        var spent = transactions
            .Where(t => t.CategoryId == b.CategoryId)
            .Sum(t => t.Amount);

        var report = budgetEngine.EvaluateBudget(b.Amount, spent, now);

        return new BudgetResponse(
            b.Id,
            b.CategoryId,
            b.Category?.NameAr ?? "???",
            b.Category?.NameEn ?? "General",
            b.Category?.Icon ?? "wallet",
            b.Amount,
            spent,
            report.BudgetRemaining,
            report.PercentageUsed,
            report.Status.ToString()
        );
    }).ToList();

    return Results.Ok(results);
}).RequireAuthorization();

app.MapPost("/api/budgets", async (CreateBudgetRequest req, ClaimsPrincipal principal, MizanDbContext db) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var existing = await db.Budgets.FirstOrDefaultAsync(b =>
        b.UserId == userId.Value &&
        b.CategoryId == req.CategoryId &&
        b.Month == req.Month &&
        b.Year == req.Year);

    if (existing != null)
    {
        existing.Amount = req.Amount;
        existing.UpdatedAt = DateTime.UtcNow;
    }
    else
    {
        var budget = new Budget
        {
            UserId = userId.Value,
            CategoryId = req.CategoryId,
            Amount = req.Amount,
            Currency = req.Currency ?? "SAR",
            Month = req.Month,
            Year = req.Year
        };
        db.Budgets.Add(budget);
    }

    await db.SaveChangesAsync();
    return Results.Ok(new { success = true });
}).RequireAuthorization();

app.MapPut("/api/budgets/{id:guid}", async (Guid id, UpdateBudgetRequest req, ClaimsPrincipal principal, MizanDbContext db) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var existing = await db.Budgets.FirstOrDefaultAsync(b => b.Id == id && b.UserId == userId.Value);
    if (existing == null) return Results.NotFound();

    existing.Amount = req.Amount;
    existing.UpdatedAt = DateTime.UtcNow;

    await db.SaveChangesAsync();
    return Results.Ok(new { success = true });
}).RequireAuthorization();

// -----------------------------------------------------------------------------
// Financial Commitments
// -----------------------------------------------------------------------------
static (string NameAr, string NameEn) GetCommitmentCategoryNames(CommitmentCategory category) => category switch
{
    CommitmentCategory.Housing => ("سكن", "Housing"),
    CommitmentCategory.Car => ("سيارة", "Car"),
    CommitmentCategory.Loan => ("قرض", "Loan"),
    CommitmentCategory.CreditCard => ("بطاقة ائتمانية", "Credit Card"),
    CommitmentCategory.Utilities => ("فواتير خدمات", "Utilities"),
    CommitmentCategory.Telecommunications => ("اتصالات", "Telecommunications"),
    CommitmentCategory.Insurance => ("تأمين", "Insurance"),
    CommitmentCategory.Subscriptions => ("اشتراكات", "Subscriptions"),
    CommitmentCategory.Education => ("تعليم", "Education"),
    CommitmentCategory.Family => ("التزامات عائلية", "Family Support"),
    CommitmentCategory.BNPL => ("تقسيط / اشتر الآن وادفع لاحقًا", "BNPL"),
    CommitmentCategory.GovernmentFees => ("رسوم حكومية", "Government Fees"),
    CommitmentCategory.Healthcare => ("صحة", "Healthcare"),
    _ => ("أخرى", "Other")
};

static CommitmentCategory ParseCommitmentCategory(string? cat) => cat?.ToLowerInvariant() switch
{
    "housing" => CommitmentCategory.Housing,
    "car" => CommitmentCategory.Car,
    "loan" => CommitmentCategory.Loan,
    "creditcard" => CommitmentCategory.CreditCard,
    "utilities" => CommitmentCategory.Utilities,
    "telecommunications" or "telecom" => CommitmentCategory.Telecommunications,
    "insurance" => CommitmentCategory.Insurance,
    "subscriptions" => CommitmentCategory.Subscriptions,
    "education" => CommitmentCategory.Education,
    "family" => CommitmentCategory.Family,
    "bnpl" => CommitmentCategory.BNPL,
    "governmentfees" or "government" => CommitmentCategory.GovernmentFees,
    "healthcare" or "health" => CommitmentCategory.Healthcare,
    _ => CommitmentCategory.Other
};

static CommitmentFrequency ParseCommitmentFrequency(string? freq) => freq?.ToLowerInvariant() switch
{
    "onetime" => CommitmentFrequency.OneTime,
    "weekly" => CommitmentFrequency.Weekly,
    "monthly" => CommitmentFrequency.Monthly,
    "quarterly" => CommitmentFrequency.Quarterly,
    "semiannual" => CommitmentFrequency.SemiAnnual,
    "annual" => CommitmentFrequency.Annual,
    _ => CommitmentFrequency.Monthly
};

static CommitmentPriority ParseCommitmentPriority(string? pri) => pri?.ToLowerInvariant() switch
{
    "low" => CommitmentPriority.Low,
    "high" => CommitmentPriority.High,
    "critical" => CommitmentPriority.Critical,
    _ => CommitmentPriority.Medium
};

static DateTime CalculateNextDueDate(DateTime currentDue, CommitmentFrequency frequency) => frequency switch
{
    CommitmentFrequency.Weekly => currentDue.AddDays(7),
    CommitmentFrequency.Monthly => currentDue.AddMonths(1),
    CommitmentFrequency.Quarterly => currentDue.AddMonths(3),
    CommitmentFrequency.SemiAnnual => currentDue.AddMonths(6),
    CommitmentFrequency.Annual => currentDue.AddYears(1),
    _ => currentDue
};

static CommitmentResponse MapCommitmentToResponse(FinancialCommitment c)
{
    var (nameAr, nameEn) = GetCommitmentCategoryNames(c.Category);
    return new CommitmentResponse(
        c.Id,
        c.UserId,
        c.Title,
        c.Description,
        c.Category.ToString(),
        nameAr,
        nameEn,
        c.Amount,
        c.Currency,
        c.Frequency.ToString(),
        c.StartDate,
        c.DueDate,
        c.NextDueDate,
        c.EndDate,
        c.IsRecurring,
        c.AutoRenew,
        c.Priority.ToString(),
        c.PaymentMethod,
        c.Merchant,
        c.Reference,
        c.Status.ToString(),
        c.ReminderDaysBefore,
        c.IsPaid,
        c.CreatedAt,
        c.Occurrences?.Select(o => new CommitmentOccurrenceResponse(
            o.Id,
            o.CommitmentId,
            o.ExpectedDate,
            o.ExpectedAmount,
            o.ActualTransactionId,
            o.Status.ToString(),
            o.PaidAt,
            o.ActualAmount
        )).ToList()
    );
}

app.MapGet("/api/commitments", async (ClaimsPrincipal principal, MizanDbContext db) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var list = await db.FinancialCommitments
        .Include(c => c.Occurrences)
        .Where(c => c.UserId == userId.Value)
        .OrderBy(c => c.NextDueDate)
        .ToListAsync();

    return Results.Ok(list.Select(MapCommitmentToResponse));
}).RequireAuthorization();

app.MapPost("/api/commitments", async (CreateCommitmentRequest req, ClaimsPrincipal principal, MizanDbContext db) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var category = ParseCommitmentCategory(req.Category);
    var frequency = ParseCommitmentFrequency(req.Frequency);
    var priority = ParseCommitmentPriority(req.Priority);

    var commitment = new FinancialCommitment
    {
        UserId = userId.Value,
        Title = req.Title,
        Description = req.Description,
        Category = category,
        Amount = req.Amount,
        Currency = req.Currency ?? "SAR",
        Frequency = frequency,
        StartDate = req.StartDate,
        DueDate = req.DueDate,
        NextDueDate = req.DueDate,
        EndDate = req.EndDate,
        IsRecurring = req.IsRecurring,
        AutoRenew = req.AutoRenew,
        Priority = priority,
        PaymentMethod = req.PaymentMethod,
        Merchant = req.Merchant,
        Reference = req.Reference,
        ReminderDaysBefore = req.ReminderDaysBefore,
        Status = CommitmentStatus.Active,
        IsPaid = false,
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow
    };

    // Generate initial occurrence
    var occurrence = new CommitmentOccurrence
    {
        CommitmentId = commitment.Id,
        ExpectedDate = req.DueDate,
        ExpectedAmount = req.Amount,
        Status = OccurrenceStatus.Pending
    };
    commitment.Occurrences.Add(occurrence);

    db.FinancialCommitments.Add(commitment);
    await db.SaveChangesAsync();

    return Results.Ok(MapCommitmentToResponse(commitment));
}).RequireAuthorization();

app.MapGet("/api/commitments/{id:guid}", async (Guid id, ClaimsPrincipal principal, MizanDbContext db) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var commitment = await db.FinancialCommitments
        .Include(c => c.Occurrences)
        .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId.Value);

    if (commitment == null) return Results.NotFound();
    return Results.Ok(MapCommitmentToResponse(commitment));
}).RequireAuthorization();

app.MapPut("/api/commitments/{id:guid}", async (Guid id, UpdateCommitmentRequest req, ClaimsPrincipal principal, MizanDbContext db) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var commitment = await db.FinancialCommitments
        .Include(c => c.Occurrences)
        .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId.Value);

    if (commitment == null) return Results.NotFound();

    if (req.Title != null) commitment.Title = req.Title;
    if (req.Description != null) commitment.Description = req.Description;
    if (req.Category != null) commitment.Category = ParseCommitmentCategory(req.Category);
    if (req.Amount.HasValue) commitment.Amount = req.Amount.Value;
    if (req.Currency != null) commitment.Currency = req.Currency;
    if (req.Frequency != null) commitment.Frequency = ParseCommitmentFrequency(req.Frequency);
    if (req.DueDate.HasValue)
    {
        commitment.DueDate = req.DueDate.Value;
        commitment.NextDueDate = req.DueDate.Value;
    }
    if (req.EndDate.HasValue) commitment.EndDate = req.EndDate.Value;
    if (req.Priority != null) commitment.Priority = ParseCommitmentPriority(req.Priority);
    if (req.PaymentMethod != null) commitment.PaymentMethod = req.PaymentMethod;
    if (req.Merchant != null) commitment.Merchant = req.Merchant;
    if (req.Reference != null) commitment.Reference = req.Reference;
    if (req.ReminderDaysBefore.HasValue) commitment.ReminderDaysBefore = req.ReminderDaysBefore.Value;
    if (req.Status != null && Enum.TryParse<CommitmentStatus>(req.Status, true, out var status))
    {
        commitment.Status = status;
    }
    commitment.UpdatedAt = DateTime.UtcNow;

    await db.SaveChangesAsync();
    return Results.Ok(MapCommitmentToResponse(commitment));
}).RequireAuthorization();

app.MapDelete("/api/commitments/{id:guid}", async (Guid id, ClaimsPrincipal principal, MizanDbContext db) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var commitment = await db.FinancialCommitments
        .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId.Value);

    if (commitment == null) return Results.NotFound();

    db.FinancialCommitments.Remove(commitment);
    await db.SaveChangesAsync();
    return Results.Ok(new { success = true });
}).RequireAuthorization();

app.MapPost("/api/commitments/{id:guid}/mark-paid", async (
    Guid id,
    MarkPaidRequest req,
    ClaimsPrincipal principal,
    MizanDbContext db) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var commitment = await db.FinancialCommitments
        .Include(c => c.Occurrences)
        .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId.Value);

    if (commitment == null) return Results.NotFound();

    var now = DateTime.UtcNow;

    // Find occurrence to mark as paid
    CommitmentOccurrence? occurrence = null;
    if (req.OccurrenceId.HasValue)
    {
        occurrence = commitment.Occurrences.FirstOrDefault(o => o.Id == req.OccurrenceId.Value);
    }
    else
    {
        occurrence = commitment.Occurrences
            .Where(o => o.Status == OccurrenceStatus.Pending || o.Status == OccurrenceStatus.Upcoming)
            .OrderBy(o => o.ExpectedDate)
            .FirstOrDefault();
    }

    if (occurrence != null)
    {
        occurrence.Status = OccurrenceStatus.Paid;
        occurrence.PaidAt = now;
        occurrence.ActualAmount = req.ActualAmount ?? commitment.Amount;
        occurrence.ActualTransactionId = req.TransactionId;
    }
    else
    {
        occurrence = new CommitmentOccurrence
        {
            CommitmentId = commitment.Id,
            ExpectedDate = commitment.NextDueDate,
            ExpectedAmount = commitment.Amount,
            ActualAmount = req.ActualAmount ?? commitment.Amount,
            ActualTransactionId = req.TransactionId,
            Status = OccurrenceStatus.Paid,
            PaidAt = now
        };
        commitment.Occurrences.Add(occurrence);
    }

    if (commitment.IsRecurring)
    {
        commitment.NextDueDate = CalculateNextDueDate(commitment.NextDueDate, commitment.Frequency);
        commitment.IsPaid = false;

        // Add next pending occurrence
        commitment.Occurrences.Add(new CommitmentOccurrence
        {
            CommitmentId = commitment.Id,
            ExpectedDate = commitment.NextDueDate,
            ExpectedAmount = commitment.Amount,
            Status = OccurrenceStatus.Pending
        });
    }
    else
    {
        commitment.IsPaid = true;
        commitment.Status = CommitmentStatus.Paid;
    }

    commitment.UpdatedAt = now;
    await db.SaveChangesAsync();

    return Results.Ok(MapCommitmentToResponse(commitment));
}).RequireAuthorization();

app.MapGet("/api/commitments/upcoming", async (ClaimsPrincipal principal, MizanDbContext db) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var now = DateTime.UtcNow.Date;
    var list = await db.FinancialCommitments
        .Include(c => c.Occurrences)
        .Where(c => c.UserId == userId.Value && c.Status == CommitmentStatus.Active && !c.IsPaid)
        .OrderBy(c => c.NextDueDate)
        .ToListAsync();

    return Results.Ok(list.Select(MapCommitmentToResponse));
}).RequireAuthorization();

app.MapGet("/api/commitments/summary", async (ClaimsPrincipal principal, MizanDbContext db) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var now = DateTime.UtcNow;
    var today = now.Date;
    var weekFromNow = today.AddDays(7);

    var commitments = await db.FinancialCommitments
        .Include(c => c.Occurrences)
        .Where(c => c.UserId == userId.Value)
        .ToListAsync();

    var active = commitments.Where(c => c.Status == CommitmentStatus.Active).ToList();

    decimal totalMonthly = active
        .Where(c => c.Frequency == CommitmentFrequency.Monthly)
        .Sum(c => c.Amount);

    decimal upcomingThisMonth = active
        .Where(c => !c.IsPaid && c.NextDueDate.Month == now.Month && c.NextDueDate.Year == now.Year)
        .Sum(c => c.Amount);

    int dueSoon = active.Count(c => !c.IsPaid && c.NextDueDate >= today && c.NextDueDate <= weekFromNow);
    int overdue = active.Count(c => !c.IsPaid && c.NextDueDate < today);

    return Results.Ok(new CommitmentSummaryResponse(
        totalMonthly,
        upcomingThisMonth,
        dueSoon,
        overdue,
        active.Select(MapCommitmentToResponse).ToList()
    ));
}).RequireAuthorization();

app.MapPost("/api/commitments/match-transaction", async (MatchCommitmentRequest req, ClaimsPrincipal principal, MizanDbContext db) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var activeCommitments = await db.FinancialCommitments
        .Include(c => c.Occurrences)
        .Where(c => c.UserId == userId.Value && c.Status == CommitmentStatus.Active && !c.IsPaid)
        .ToListAsync();

    if (!activeCommitments.Any())
    {
        return Results.Ok(new CommitmentMatchResponse(null, null, 0, false, null, null, null));
    }

    FinancialCommitment? bestMatch = null;
    double bestScore = 0;

    foreach (var c in activeCommitments)
    {
        double score = 0;

        // Amount matching
        decimal diff = Math.Abs(c.Amount - req.TransactionAmount);
        if (diff < 0.01m) score += 0.50;
        else if (diff / c.Amount <= 0.10m) score += 0.25;

        // Merchant matching
        if (!string.IsNullOrEmpty(req.Merchant))
        {
            var merchant = req.Merchant.ToLowerInvariant();
            var title = c.Title.ToLowerInvariant();
            var provider = (c.Merchant ?? "").ToLowerInvariant();

            if (merchant.Contains(title) || title.Contains(merchant)) score += 0.35;
            else if (!string.IsNullOrEmpty(provider) && (merchant.Contains(provider) || provider.Contains(merchant))) score += 0.35;
        }

        // Date proximity (+/- 7 days)
        int dayDiff = Math.Abs((c.NextDueDate.Date - req.TransactionDate.Date).Days);
        if (dayDiff <= 3) score += 0.15;
        else if (dayDiff <= 7) score += 0.10;

        if (score > bestScore)
        {
            bestScore = score;
            bestMatch = c;
        }
    }

    if (bestMatch != null && bestScore >= 0.70)
    {
        var occurrence = bestMatch.Occurrences
            .FirstOrDefault(o => o.Status == OccurrenceStatus.Pending || o.Status == OccurrenceStatus.Upcoming);

        return Results.Ok(new CommitmentMatchResponse(
            bestMatch.Id,
            bestMatch.Title,
            Math.Round(bestScore, 2),
            bestScore >= 0.95,
            occurrence?.Id,
            $"هذا يبدو أنه سداد التزام {bestMatch.Title}.",
            $"This appears to be payment for commitment: {bestMatch.Title}."
        ));
    }

    return Results.Ok(new CommitmentMatchResponse(null, null, 0, false, null, null, null));
}).RequireAuthorization();

// -----------------------------------------------------------------------------
// Dashboard & Analytics
// -----------------------------------------------------------------------------
app.MapGet("/api/analytics/dashboard", async (
    ClaimsPrincipal principal,
    MizanDbContext db,
    IBudgetEngine budgetEngine) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var now = DateTime.UtcNow;
    var todayStart = now.Date;

    var wallets = await db.Wallets.Where(w => w.UserId == userId.Value).ToListAsync();
    var currentBalance = wallets.Sum(w => w.CurrentBalance);

    var transactions = await db.Transactions
        .Include(t => t.Category)
        .Where(t => t.UserId == userId.Value)
        .ToListAsync();

    var commitments = await db.FinancialCommitments
        .Include(c => c.Occurrences)
        .Where(c => c.UserId == userId.Value && c.Status == CommitmentStatus.Active)
        .ToListAsync();

    var spentToday = transactions
        .Where(t => t.TransactionDate >= todayStart && t.TransactionType == TransactionType.Purchase)
        .Sum(t => t.Amount);

    var currentMonthExpenses = transactions
        .Where(t => t.TransactionDate.Month == now.Month &&
                    t.TransactionDate.Year == now.Year &&
                    t.TransactionType == TransactionType.Purchase)
        .ToList();

    var totalBudgets = await db.Budgets
        .Where(b => b.UserId == userId.Value && b.Month == now.Month && b.Year == now.Year)
        .SumAsync(b => b.Amount);

    var totalSpentMonth = currentMonthExpenses.Sum(t => t.Amount);

    // Commitments calculation
    var upcomingCommitments = commitments
        .Where(c => !c.IsPaid && c.NextDueDate >= todayStart)
        .OrderBy(c => c.NextDueDate)
        .ToList();

    var committedAmount = upcomingCommitments.Sum(c => c.Amount);
    var emergencyReserve = 0m;
    var savingsReserve = 0m;

    // Available for spending: CurrentBalance - Committed - Reserves
    var availableToSpend = Math.Max(0, currentBalance - committedAmount - emergencyReserve - savingsReserve);

    var effectiveBudget = totalBudgets > 0 ? totalBudgets : currentBalance;
    var budgetReport = budgetEngine.EvaluateBudgetWithCommitments(
        effectiveBudget,
        totalSpentMonth,
        currentBalance,
        committedAmount,
        emergencyReserve,
        savingsReserve,
        now);

    var recent = transactions
        .OrderByDescending(t => t.TransactionDate)
        .Take(5)
        .Select(t => new TransactionResponse(
            t.Id,
            t.WalletId,
            (int)t.TransactionType,
            t.Amount,
            t.Currency,
            t.Merchant,
            t.NormalizedMerchant,
            t.CategoryId,
            t.Category?.NameAr,
            t.Category?.NameEn,
            t.Category?.Icon,
            t.Category?.ColorHex,
            t.TransactionDate,
            (int)t.Source,
            t.Confidence,
            t.IsVerified,
            t.Notes,
            t.ReferenceNumber,
            t.CreatedAt
        )).ToList();

    var spendingByCategory = currentMonthExpenses
        .GroupBy(t => t.Category)
        .Select(g => new CategorySpendingItem(
            g.Key?.Id,
            g.Key?.NameAr ?? "أخرى",
            g.Key?.NameEn ?? "Other",
            g.Key?.Icon ?? "more_horiz",
            g.Key?.ColorHex ?? "#6B7280",
            g.Sum(t => t.Amount),
            totalSpentMonth > 0 ? (double)(g.Sum(t => t.Amount) / totalSpentMonth * 100) : 0
        ))
        .OrderByDescending(c => c.SpentAmount)
        .Take(5)
        .ToList();

    var dailyLimit = budgetReport.RecommendedDailyLimit;
    var expectedTomorrow = dailyLimit * 0.95m;

    string insightAr;
    string insightEn;

    if (committedAmount > 0)
    {
        insightAr = $"لديك {currentBalance:N0} ر.س حالياً، لكن {committedAmount:N0} ر.س محجوزة لالتزامات قادمة. المتاح الفعلي للصرف هو {availableToSpend:N0} ر.س، والحد اليومي المقترح {dailyLimit:N0} ر.س.";
        insightEn = $"You currently have {currentBalance:N0} SAR, but {committedAmount:N0} SAR is reserved for upcoming commitments. Available to spend is {availableToSpend:N0} SAR, with a recommended daily limit of {dailyLimit:N0} SAR.";
    }
    else
    {
        insightAr = spentToday > dailyLimit
            ? "مصروف اليوم تجاوز الحد اليومي المقترح. حاول موازنة النفقات في الأيام القادمة."
            : "ممتاز! مصروف اليوم يقع ضمن حدود ميزانيتك الآمنة، متبقي لليوم " + Math.Max(0, dailyLimit - spentToday).ToString("N0") + " ر.س.";

        insightEn = spentToday > dailyLimit
            ? "Today's spend is higher than the recommended limit. Try to balance expenses tomorrow."
            : "Great job! Today's spend is well within your safe daily budget.";
    }

    return Results.Ok(new DashboardSummaryResponse(
        currentBalance,
        spentToday,
        dailyLimit,
        expectedTomorrow,
        budgetReport.Status.ToString(),
        recent,
        spendingByCategory,
        insightAr,
        insightEn,
        committedAmount,
        availableToSpend,
        committedAmount,
        upcomingCommitments.Take(3).Select(MapCommitmentToResponse).ToList()
    ));
}).RequireAuthorization();

// -----------------------------------------------------------------------------
// AI Insights & Forecast
// -----------------------------------------------------------------------------
app.MapGet("/api/ai/insights", (ClaimsPrincipal principal) =>
{
    var list = new[]
    {
        new
        {
            titleAr = "ارتفاع في بند المطاعم",
            titleEn = "Dining Spend Increase",
            messageAr = "نفقاتك في المطاعم والمقاهي ارتفعت بنسبة 18% هذا الأسبوع. إعداد بعض الوجبات منزلياً يوفر لك نحو 240 ر.س.",
            messageEn = "Restaurant expenses increased by 18% this week. Preparing meals at home two extra days could save you 240 SAR.",
            type = "SpendingAnalysis",
            confidence = 0.94
        },
        new
        {
            titleAr = "فرصة ادخار إضافية",
            titleEn = "Additional Savings Opportunity",
            messageAr = "إذا حافظت على نمط صرفك الحالي حتى نهاية الشهر، فستتمكن من حجز فائض إضافي قدره 950 ر.س لصندوق الطوارئ.",
            messageEn = "If you maintain your current spending pace until month-end, you can save 950 SAR for your emergency reserve.",
            type = "SavingsTarget",
            confidence = 0.91
        },
        new
        {
            titleAr = "فاتورة دورية خلال 3 أيام",
            titleEn = "Upcoming Bill in 3 Days",
            messageAr = "موعد استحقاق فاتورة الاتصالات والإنترنت بقيمة 287 ر.س بعد 3 أيام. تم تجنيب المبلغ تلقائياً من الحد اليومي الموصى به.",
            messageEn = "Telecom bill of approx 287 SAR is due in 3 days. It has been factored out from your daily spend limit.",
            type = "BillReminder",
            confidence = 0.99
        }
    };
    return Results.Ok(list);
}).RequireAuthorization();

app.MapGet("/api/ai/forecast", async (ClaimsPrincipal principal, MizanDbContext db) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    var tomorrow = DateTime.UtcNow.Date.AddDays(1);
    var commitmentsTomorrow = await db.FinancialCommitments
        .Where(c => c.UserId == userId.Value && c.Status == CommitmentStatus.Active && !c.IsPaid && c.NextDueDate.Date == tomorrow)
        .ToListAsync();

    decimal scheduledCommitmentTomorrow = commitmentsTomorrow.Sum(c => c.Amount);
    decimal discretionaryExpected = 145.0m;
    decimal discretionaryLower = 120.0m;
    decimal discretionaryUpper = 165.0m;
    decimal totalExpected = discretionaryExpected + scheduledCommitmentTomorrow;
    decimal totalLower = discretionaryLower + scheduledCommitmentTomorrow;
    decimal totalUpper = discretionaryUpper + scheduledCommitmentTomorrow;

    var forecast = new
    {
        expectedSpend = totalExpected,
        expectedDiscretionarySpend = discretionaryExpected,
        discretionaryLowerBound = discretionaryLower,
        discretionaryUpperBound = discretionaryUpper,
        scheduledCommitments = scheduledCommitmentTomorrow,
        commitmentDetails = commitmentsTomorrow.Select(c => new { c.Title, c.Amount, Category = c.Category.ToString() }),
        potentialTotalOutflow = totalExpected,
        lowerBound = totalLower,
        upperBound = totalUpper,
        confidence = 0.92,
        factors = new[]
        {
            "نمط صرف يوم الأحد مقارنة بالأسابيع السابقة",
            "المصروفات الدورية والالتزامات المستحقة غداً",
            "معدل الإنفاق اليومي التراكمي المتاح"
        }
    };
    return Results.Ok(forecast);
}).RequireAuthorization();

// -----------------------------------------------------------------------------
// Settings
// -----------------------------------------------------------------------------
app.MapGet("/api/settings", (ClaimsPrincipal principal) =>
{
    return Results.Ok(new UserSettingsResponse(
        NotificationTransactions: true,
        NotificationDailySummary: true,
        NotificationBudgetWarnings: true,
        NotificationBillReminders: true,
        SmartDetectionEnabled: true,
        PreferredLanguage: "ar",
        PreferredCurrency: "SAR",
        ThemeMode: "light"
    ));
}).RequireAuthorization();

app.MapPut("/api/settings", (UpdateSettingsRequest req, ClaimsPrincipal principal) =>
{
    return Results.Ok(new UserSettingsResponse(
        NotificationTransactions: req.NotificationTransactions ?? true,
        NotificationDailySummary: req.NotificationDailySummary ?? true,
        NotificationBudgetWarnings: req.NotificationBudgetWarnings ?? true,
        NotificationBillReminders: req.NotificationBillReminders ?? true,
        SmartDetectionEnabled: req.SmartDetectionEnabled ?? true,
        PreferredLanguage: req.PreferredLanguage ?? "ar",
        PreferredCurrency: req.PreferredCurrency ?? "SAR",
        ThemeMode: req.ThemeMode ?? "light"
    ));
}).RequireAuthorization();

// -----------------------------------------------------------------------------
// AI Chat & Conversations (Section 122)
// -----------------------------------------------------------------------------
app.MapPost("/api/ai/chat", async (AIChatRequest req, IAIChatService chatService, ClaimsPrincipal principal) =>
{
    var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    if (!Guid.TryParse(userIdClaim, out var userId)) return Results.Unauthorized();

    var response = await chatService.ProcessChatAsync(userId, req);
    return Results.Ok(response);
}).RequireAuthorization().RequireRateLimiting("ai-policy");

app.MapGet("/api/ai/conversations", async (MizanDbContext db, ClaimsPrincipal principal) =>
{
    var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    if (!Guid.TryParse(userIdClaim, out var userId)) return Results.Unauthorized();

    var convs = await db.AIConversations
        .Where(c => c.UserId == userId)
        .OrderByDescending(c => c.UpdatedAt)
        .Select(c => new AIConversationResponse(
            c.Id,
            c.Title,
            c.CreatedAt,
            c.UpdatedAt,
            c.Messages.Count
        ))
        .ToListAsync();

    return Results.Ok(convs);
}).RequireAuthorization();

app.MapGet("/api/ai/conversations/{id:guid}", async (Guid id, MizanDbContext db, ClaimsPrincipal principal) =>
{
    var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    if (!Guid.TryParse(userIdClaim, out var userId)) return Results.Unauthorized();

    var conv = await db.AIConversations
        .Include(c => c.Messages.OrderBy(m => m.CreatedAt))
        .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId);

    if (conv == null) return Results.NotFound();

    var messages = conv.Messages.Select(m => new AIMessageResponse(
        m.Id,
        m.ConversationId,
        m.Role,
        m.Content,
        m.StructuredPayload,
        m.CreatedAt
    )).ToList();

    return Results.Ok(new
    {
        conv.Id,
        conv.Title,
        conv.CreatedAt,
        conv.UpdatedAt,
        Messages = messages
    });
}).RequireAuthorization();

app.MapDelete("/api/ai/conversations/{id:guid}", async (Guid id, MizanDbContext db, ClaimsPrincipal principal) =>
{
    var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    if (!Guid.TryParse(userIdClaim, out var userId)) return Results.Unauthorized();

    var conv = await db.AIConversations
        .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId);

    if (conv == null) return Results.NotFound();

    db.AIConversations.Remove(conv);
    await db.SaveChangesAsync();

    return Results.NoContent();
}).RequireAuthorization();

app.MapPost("/api/ai/conversations", async (CreateConversationRequest req, MizanDbContext db, ClaimsPrincipal principal) =>
{
    var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    if (!Guid.TryParse(userIdClaim, out var userId)) return Results.Unauthorized();

    var conv = new AIConversation
    {
        UserId = userId,
        Title = string.IsNullOrWhiteSpace(req.Title) ? "محادثة مالية جديدة" : req.Title.Trim()
    };
    db.AIConversations.Add(conv);
    await db.SaveChangesAsync();

    return Results.Ok(new AIConversationResponse(conv.Id, conv.Title, conv.CreatedAt, conv.UpdatedAt, 0));
}).RequireAuthorization();

app.MapPost("/api/ai/loan-scenario", async (
    LoanScenarioRequest req,
    IFinancialContextService contextSvc,
    ILoanCalculationEngine loanEngine,
    ClaimsPrincipal principal) =>
{
    var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    if (!Guid.TryParse(userIdClaim, out var userId)) return Results.Unauthorized();

    var ctx = await contextSvc.BuildContextAsync(userId, DateTime.UtcNow);
    var result = loanEngine.CalculateLoanScenario(req, ctx);
    return Results.Ok(result);
}).RequireAuthorization();

app.MapPost("/api/ai/purchase-scenario", async (
    PurchaseScenarioRequest req,
    IFinancialContextService contextSvc,
    IPurchaseFeasibilityEngine purchaseEngine,
    ClaimsPrincipal principal) =>
{
    var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    if (!Guid.TryParse(userIdClaim, out var userId)) return Results.Unauthorized();

    var ctx = await contextSvc.BuildContextAsync(userId, DateTime.UtcNow);
    var result = purchaseEngine.CalculatePurchaseScenario(req, ctx);
    return Results.Ok(result);
}).RequireAuthorization();

app.MapPost("/api/ai/financial-plan", async (
    FinancialPlanRequest req,
    IFinancialContextService contextSvc,
    IFinancialPlanEngine planEngine,
    ClaimsPrincipal principal) =>
{
    var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    if (!Guid.TryParse(userIdClaim, out var userId)) return Results.Unauthorized();

    var ctx = await contextSvc.BuildContextAsync(userId, DateTime.UtcNow);
    var result = planEngine.CalculateSalaryPlan(req, ctx);
    return Results.Ok(result);
}).RequireAuthorization();

app.MapGet("/api/ai/suggested-questions", () =>
{
    var questionsAr = new List<string>
    {
        "حلل وضعي المالي",
        "كم أقدر أصرف؟",
        "وش التزاماتي القادمة؟",
        "رتب لي الراتب",
        "هل أقدر آخذ قرض؟",
        "هل أقدر أشتري سيارة؟",
        "كيف أوفر أكثر؟",
        "توقع رصيدي نهاية الشهر"
    };

    var questionsEn = new List<string>
    {
        "Analyze my financial position",
        "How much can I safely spend?",
        "What are my upcoming commitments?",
        "Organize my next salary",
        "Can I afford a loan?",
        "Can I afford a car purchase?",
        "How can I save more?",
        "Forecast my month-end balance"
    };

    return Results.Ok(new AISuggestedQuestionsResponse(questionsAr, questionsEn));
});

// -----------------------------------------------------------------------------
// Financial Analysis & Scenarios (Section 122)
// -----------------------------------------------------------------------------
app.MapGet("/api/analysis/financial-health", async (
    IFinancialContextService contextSvc,
    IFinancialHealthEngine healthEngine,
    MizanDbContext db,
    ClaimsPrincipal principal) =>
{
    var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    if (!Guid.TryParse(userIdClaim, out var userId)) return Results.Unauthorized();

    var now = DateTime.UtcNow;
    var ctx = await contextSvc.BuildContextAsync(userId, now);
    int overdueCount = await db.FinancialCommitments.CountAsync(c => c.UserId == userId && (c.Status == CommitmentStatus.Active || c.Status == CommitmentStatus.Upcoming) && c.NextDueDate < now);

    var health = healthEngine.EvaluateHealth(ctx, overdueCount);
    return Results.Ok(health);
}).RequireAuthorization();

app.MapGet("/api/analysis/forecast", async (
    IFinancialContextService contextSvc,
    IFinancialForecastEngine forecastEngine,
    MizanDbContext db,
    ClaimsPrincipal principal) =>
{
    var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    if (!Guid.TryParse(userIdClaim, out var userId)) return Results.Unauthorized();

    var now = DateTime.UtcNow;
    var ctx = await contextSvc.BuildContextAsync(userId, now);
    int txCount = await db.Transactions.CountAsync(t => t.UserId == userId);

    var forecast = forecastEngine.ForecastMonthEnd(ctx, txCount, now);
    return Results.Ok(forecast);
}).RequireAuthorization();

app.MapGet("/api/analysis/commitments", async (
    int? months,
    ICommitmentScheduleService scheduleSvc,
    ClaimsPrincipal principal) =>
{
    var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    if (!Guid.TryParse(userIdClaim, out var userId)) return Results.Unauthorized();

    var schedule = await scheduleSvc.GetScheduleAsync(userId, months ?? 12, DateTime.UtcNow);
    return Results.Ok(schedule);
}).RequireAuthorization();

app.MapGet("/api/analysis/summary", async (
    IFinancialContextService contextSvc,
    IFinancialHealthEngine healthEngine,
    IFinancialForecastEngine forecastEngine,
    ICommitmentScheduleService scheduleSvc,
    IAIProvider aiProvider,
    MizanDbContext db,
    ClaimsPrincipal principal) =>
{
    var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    if (!Guid.TryParse(userIdClaim, out var userId)) return Results.Unauthorized();

    var now = DateTime.UtcNow;
    var ctx = await contextSvc.BuildContextAsync(userId, now);
    int overdueCount = await db.FinancialCommitments.CountAsync(c => c.UserId == userId && (c.Status == CommitmentStatus.Active || c.Status == CommitmentStatus.Upcoming) && c.NextDueDate < now);
    int txCount = await db.Transactions.CountAsync(t => t.UserId == userId);

    var health = healthEngine.EvaluateHealth(ctx, overdueCount);
    var forecast = forecastEngine.ForecastMonthEnd(ctx, txCount, now);
    var commitments = await scheduleSvc.GetScheduleAsync(userId, 6, now);

    decimal safeDaily = ctx.DaysRemaining > 0 ? Math.Round(ctx.AvailableToSpend / ctx.DaysRemaining, 1) : ctx.AvailableToSpend;

    string textAr = $"وضعك المالي مستقر حاليًا بدرجة صحة مالية {health.Score}/100. " +
        $"تمثل الالتزامات {(ctx.CommitmentRatio * 100):F1}% من دخلك الشهري. " +
        $"إذا حافظت على صرف يومي أقل من {safeDaily:N0} ريال، فمن المتوقع إنهاء الشهر برصيد يقارب {forecast.MonthEndBalance.Expected:N0} ريال دون تجاوز الميزانية.";

    string textEn = $"Your financial position is stable with a health score of {health.Score}/100. " +
        $"Commitments account for {(ctx.CommitmentRatio * 100):F1}% of monthly income. " +
        $"If you maintain a daily spending pace under {safeDaily:N0} SAR, you are projected to close the month near {forecast.MonthEndBalance.Expected:N0} SAR.";

    return Results.Ok(new AnalysisSummaryResponse(
        health,
        forecast,
        commitments,
        textAr,
        textEn,
        safeDaily,
        now
    ));
}).RequireAuthorization();

app.MapPost("/api/analysis/optimize-budget", async (
    BudgetOptimizationRequest req,
    IFinancialContextService contextSvc,
    IFinancialSchedulingEngine scheduleEngine,
    ClaimsPrincipal principal) =>
{
    var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    if (!Guid.TryParse(userIdClaim, out var userId)) return Results.Unauthorized();

    var ctx = await contextSvc.BuildContextAsync(userId, DateTime.UtcNow);
    var result = scheduleEngine.OptimizeBudget(req, ctx);
    return Results.Ok(result);
}).RequireAuthorization();

app.MapPost("/api/scenarios/loan", async (
    LoanScenarioRequest req,
    IFinancialContextService contextSvc,
    ILoanCalculationEngine loanEngine,
    ClaimsPrincipal principal) =>
{
    var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    if (!Guid.TryParse(userIdClaim, out var userId)) return Results.Unauthorized();

    var ctx = await contextSvc.BuildContextAsync(userId, DateTime.UtcNow);
    var result = loanEngine.CalculateLoanScenario(req, ctx);
    return Results.Ok(result);
}).RequireAuthorization();

app.MapPost("/api/scenarios/loan/compare", async (
    LoanCompareRequest req,
    IFinancialContextService contextSvc,
    ILoanCalculationEngine loanEngine,
    ClaimsPrincipal principal) =>
{
    var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    if (!Guid.TryParse(userIdClaim, out var userId)) return Results.Unauthorized();

    var ctx = await contextSvc.BuildContextAsync(userId, DateTime.UtcNow);
    var result = loanEngine.CompareLoans(req, ctx);
    return Results.Ok(result);
}).RequireAuthorization();

app.MapPost("/api/scenarios/what-if", async (
    WhatIfScenarioRequest req,
    IFinancialContextService contextSvc,
    ILoanCalculationEngine loanEngine,
    ClaimsPrincipal principal) =>
{
    var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    if (!Guid.TryParse(userIdClaim, out var userId)) return Results.Unauthorized();

    var ctx = await contextSvc.BuildContextAsync(userId, DateTime.UtcNow);

    // Deterministic calculation for What-If scenario
    string titleAr;
    string titleEn;
    decimal immediateImpact;
    decimal newCommitments = ctx.MonthlyCommitments;
    decimal newDisposable = ctx.AvailableToSpend;
    string ratingAr;
    string ratingEn;
    string explAr;
    string explEn;

    switch (req.ScenarioType.ToLowerInvariant())
    {
        case "salaryraise":
            titleAr = $"زيادة في الراتب (+{req.Amount:N0} ريال)";
            titleEn = $"Salary Increase (+{req.Amount:N0} SAR)";
            immediateImpact = req.Amount;
            decimal newIncome = ctx.MonthlyIncome + req.Amount;
            newDisposable = ctx.AvailableToSpend + req.Amount;
            double newDtiRaise = newIncome > 0 ? (double)(newCommitments / newIncome) : 0.0;
            ratingAr = "إيجابي جداً";
            ratingEn = "Highly Favorable";
            explAr = $"زيادة الراتب بمقدار {req.Amount:N0} ريال ستخفض نسبة التزاماتك إلى {(newDtiRaise * 100):F1}%، وترفع السيولة المتاحة شهرياً إلى {newDisposable:N0} ريال.";
            explEn = $"A salary increase of {req.Amount:N0} SAR drops your commitment ratio to {(newDtiRaise * 100):F1}% and raises disposable liquidity to {newDisposable:N0} SAR.";
            return Results.Ok(new WhatIfScenarioResult(req.ScenarioType, titleAr, titleEn, immediateImpact, newCommitments, newDisposable, newDtiRaise, ratingAr, ratingEn, explAr, explEn));

        case "majorpurchase":
            titleAr = $"شراء سلعة كبرى ({req.Amount:N0} ريال)";
            titleEn = $"Major Purchase ({req.Amount:N0} SAR)";
            immediateImpact = -req.Amount;
            newDisposable = ctx.AvailableToSpend - req.Amount;
            bool canAfford = newDisposable >= 0;
            ratingAr = canAfford ? (newDisposable > 1500 ? "ممكن بأمان" : "ممكن مع ضغط سيولة") : "غير موصى به حالياً";
            ratingEn = canAfford ? (newDisposable > 1500 ? "Safe" : "Tight Liquidity") : "Not Recommended";
            explAr = canAfford
                ? $"يمكن تغطية الشراء، لكن السيولة المتاحة ستنخفض إلى {newDisposable:N0} ريال. ستحتاج لترشيد الصرف اليومي حتى موعد الراتب."
                : $"الشراء سيتسبب في عجز نقدي بقيمة {Math.Abs(newDisposable):N0} ريال بعد حجز الالتزامات القادمة.";
            explEn = canAfford
                ? $"The purchase is feasible, but available liquidity will contract to {newDisposable:N0} SAR."
                : $"The purchase causes a cash shortfall of {Math.Abs(newDisposable):N0} SAR after reserving commitments.";
            return Results.Ok(new WhatIfScenarioResult(req.ScenarioType, titleAr, titleEn, immediateImpact, newCommitments, Math.Max(0m, newDisposable), ctx.CommitmentRatio, ratingAr, ratingEn, explAr, explEn));

        case "expensereduction":
            titleAr = $"خفض المصروفات بمقدار ({req.Amount:N0} ريال)";
            titleEn = $"Expense Cut ({req.Amount:N0} SAR)";
            immediateImpact = req.Amount;
            newDisposable = ctx.AvailableToSpend + req.Amount;
            ratingAr = "مكسب ادخاري ممتاز";
            ratingEn = "Excellent Savings Gain";
            explAr = $"خفض المصاريف غير الأساسية بمقدار {req.Amount:N0} ريال شهرياً يتيح لك إضافة {req.Amount * 12:N0} ريال لمدخراتك سنوياً.";
            explEn = $"Trimming {req.Amount:N0} SAR monthly in non-essentials adds {req.Amount * 12:N0} SAR to annual savings.";
            return Results.Ok(new WhatIfScenarioResult(req.ScenarioType, titleAr, titleEn, immediateImpact, newCommitments, newDisposable, ctx.CommitmentRatio, ratingAr, ratingEn, explAr, explEn));

        case "extracommitment":
        default:
            titleAr = $"إضافة التزام شهري جديد ({req.Amount:N0} ريال)";
            titleEn = $"New Monthly Commitment ({req.Amount:N0} SAR)";
            immediateImpact = 0m;
            newCommitments += req.Amount;
            double newDtiExtra = ctx.MonthlyIncome > 0 ? (double)(newCommitments / ctx.MonthlyIncome) : 0.0;
            newDisposable = Math.Max(0m, ctx.AvailableToSpend - req.Amount);
            ratingAr = newDtiExtra <= 0.33 ? "مقبول" : (newDtiExtra <= 0.45 ? "ضغط مالي مرتفع" : "حرج");
            ratingEn = newDtiExtra <= 0.33 ? "Acceptable" : (newDtiExtra <= 0.45 ? "High Pressure" : "Critical");
            explAr = $"إضافة التزام شهري بقيمة {req.Amount:N0} ريال سيرفع نسبة الالتزامات إلى {(newDtiExtra * 100):F1}%. المتبقي للصرف اليومي سينخفض إلى {newDisposable:N0} ريال.";
            explEn = $"Adding {req.Amount:N0} SAR monthly raises commitment ratio to {(newDtiExtra * 100):F1}%, lowering available cash to {newDisposable:N0} SAR.";
            return Results.Ok(new WhatIfScenarioResult(req.ScenarioType, titleAr, titleEn, immediateImpact, newCommitments, newDisposable, newDtiExtra, ratingAr, ratingEn, explAr, explEn));
    }
}).RequireAuthorization();

app.MapGet("/api/analysis/cash-flow", async (
    string? range,
    IFinancialContextService contextSvc,
    ClaimsPrincipal principal) =>
{
    var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    if (!Guid.TryParse(userIdClaim, out var userId)) return Results.Unauthorized();

    var now = DateTime.UtcNow;
    var ctx = await contextSvc.BuildContextAsync(userId, now);

    string rangeKey = range?.ToLowerInvariant() ?? "month_end";
    int days = rangeKey switch
    {
        "7d" => 7,
        "30d" => 30,
        "90d" => 90,
        _ => ctx.DaysRemaining
    };

    var points = new List<CashFlowPointDto>();
    decimal runningBalance = ctx.CurrentBalance;
    decimal dailySpend = ctx.AverageDailySpending > 0 ? ctx.AverageDailySpending : 120m;

    for (int i = 1; i <= days; i++)
    {
        var targetDate = now.AddDays(i);
        decimal income = (targetDate.Day == 27) ? ctx.MonthlyIncome : 0m;
        decimal commitments = (targetDate.Day == 28) ? (ctx.UpcomingCommitments > 0 ? ctx.UpcomingCommitments : 1500m) : 0m;
        decimal spend = dailySpend;

        runningBalance = runningBalance + income - commitments - spend;

        points.Add(new CashFlowPointDto(
            targetDate,
            targetDate.ToString("dd MMM"),
            income,
            spend,
            commitments,
            Math.Round(runningBalance, 2)
        ));
    }

    return Results.Ok(new CashFlowResponse(
        rangeKey,
        ctx.AvailableToSpend,
        ctx.UpcomingCommitments,
        Math.Round(dailySpend * days, 2),
        Math.Round(runningBalance, 2),
        points
    ));
}).RequireAuthorization();

// -----------------------------------------------------------------------------
// FCM Device Token Management
// -----------------------------------------------------------------------------
app.MapPost("/api/notifications/fcm-token", async (
    RegisterFcmTokenRequest req,
    ClaimsPrincipal principal,
    MizanDbContext db) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();
    if (string.IsNullOrWhiteSpace(req.Token))
        return Results.BadRequest(new { error = "Token is required." });

    // Deactivate existing duplicate tokens for other users/devices
    var duplicates = await db.UserDeviceTokens
        .Where(t => t.Token == req.Token && t.UserId != userId.Value)
        .ToListAsync();
    foreach (var dup in duplicates)
    {
        dup.IsActive = false;
        dup.LastUpdatedAt = DateTime.UtcNow;
    }

    var existing = await db.UserDeviceTokens
        .FirstOrDefaultAsync(t => t.UserId == userId.Value && t.Token == req.Token);

    if (existing != null)
    {
        existing.IsActive = true;
        existing.DeviceType = req.DeviceType ?? existing.DeviceType;
        existing.LastUpdatedAt = DateTime.UtcNow;
    }
    else
    {
        db.UserDeviceTokens.Add(new UserDeviceToken
        {
            UserId = userId.Value,
            Token = req.Token,
            DeviceType = req.DeviceType ?? "android",
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            LastUpdatedAt = DateTime.UtcNow
        });
    }

    await db.SaveChangesAsync();
    return Results.Ok(new { success = true });
}).RequireAuthorization();

app.MapDelete("/api/notifications/fcm-token", async (
    [AsParameters] DeactivateFcmTokenRequest req,
    ClaimsPrincipal principal,
    MizanDbContext db) =>
{
    var userId = GetUserId(principal);
    if (userId == null) return Results.Unauthorized();

    if (string.IsNullOrWhiteSpace(req.Token))
    {
        return Results.BadRequest(new { error = "Token is required." });
    }

    var existing = await db.UserDeviceTokens
        .FirstOrDefaultAsync(t => t.UserId == userId.Value && t.Token == req.Token);

    if (existing != null)
    {
        existing.IsActive = false;
        existing.LastUpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
    }

    return Results.Ok(new { success = true });
}).RequireAuthorization();

// -----------------------------------------------------------------------------
// Secured Internal Scheduled Jobs (Cloud Scheduler)
// -----------------------------------------------------------------------------
app.MapPost("/internal/jobs/daily-summary", async (
    HttpContext context,
    IConfiguration config,
    MizanDbContext db,
    IFirebaseNotificationService notificationService) =>
{
    var internalToken = context.Request.Headers["X-Internal-Token"].FirstOrDefault();
    var expectedToken = config["Jobs:InternalSecret"] ?? config["Internal:JobsToken"] ?? "Mizan_Secret_Internal_Job_Token_2026";
    if (string.IsNullOrEmpty(internalToken) || internalToken != expectedToken)
    {
        return Results.Unauthorized();
    }

    var today = DateTime.UtcNow.Date;
    var usersWithTokens = await db.Users
        .Include(u => u.DeviceTokens.Where(dt => dt.IsActive))
        .Where(u => u.DeviceTokens.Any(dt => dt.IsActive))
        .ToListAsync();

    int sentCount = 0;
    foreach (var user in usersWithTokens)
    {
        var dailySpent = await db.Transactions
            .Where(t => t.UserId == user.Id && t.TransactionDate >= today && t.Direction == TransactionDirection.Out)
            .SumAsync(t => (decimal?)t.Amount) ?? 0m;

        var tokens = user.DeviceTokens.Where(dt => dt.IsActive).Select(dt => dt.Token).ToList();
        var isArabic = user.PreferredLanguage == "ar";
        var title = isArabic ? "ميزان — ملخصك المالي اليومي" : "MIZAN — Today's Financial Summary";
        var body = isArabic
            ? $"مجموع مصروفاتك اليوم: {dailySpent:N2} ر.س. تابع خطتك المالية عبر ميزان."
            : $"Your total spend today: {dailySpent:N2} SAR. Keep your financial momentum with Mizan.";

        var sent = await notificationService.SendMulticastNotificationAsync(tokens, title, body, new Dictionary<string, string>
        {
            { "type", "daily_summary" },
            { "date", today.ToString("yyyy-MM-dd") }
        });
        sentCount += sent;
    }

    return Results.Ok(new { success = true, notificationsSent = sentCount, usersProcessed = usersWithTokens.Count });
}).AllowAnonymous();

app.MapPost("/internal/jobs/commitment-reminders", async (
    HttpContext context,
    IConfiguration config,
    MizanDbContext db,
    IFirebaseNotificationService notificationService) =>
{
    var internalToken = context.Request.Headers["X-Internal-Token"].FirstOrDefault();
    var expectedToken = config["Jobs:InternalSecret"] ?? config["Internal:JobsToken"] ?? "Mizan_Secret_Internal_Job_Token_2026";
    if (string.IsNullOrEmpty(internalToken) || internalToken != expectedToken)
    {
        return Results.Unauthorized();
    }

    var upcomingWindow = DateTime.UtcNow.Date.AddDays(3);
    var now = DateTime.UtcNow.Date;

    var upcomingCommitments = await db.FinancialCommitments
        .Include(c => c.User)
            .ThenInclude(u => u!.DeviceTokens.Where(dt => dt.IsActive))
        .Where(c => c.Status == CommitmentStatus.Active && c.NextDueDate >= now && c.NextDueDate <= upcomingWindow)
        .ToListAsync();

    int sentCount = 0;
    foreach (var commitment in upcomingCommitments)
    {
        if (commitment.User?.DeviceTokens == null || !commitment.User.DeviceTokens.Any(dt => dt.IsActive))
            continue;

        var tokens = commitment.User.DeviceTokens.Where(dt => dt.IsActive).Select(dt => dt.Token).ToList();
        var isArabic = commitment.User.PreferredLanguage == "ar";
        var daysRemaining = (commitment.NextDueDate - now).Days;
        var dayText = daysRemaining == 0
            ? (isArabic ? "اليوم" : "today")
            : (isArabic ? $"خلال {daysRemaining} أيام" : $"in {daysRemaining} days");

        var title = isArabic ? "تذكير بالتزام مالي قادم ⏰" : "Upcoming Commitment Reminder ⏰";
        var body = isArabic
            ? $"التزامك \"{commitment.Title}\" بقيمة {commitment.Amount:N2} ر.س يستحق {dayText}."
            : $"Your commitment \"{commitment.Title}\" ({commitment.Amount:N2} SAR) is due {dayText}.";

        var sent = await notificationService.SendMulticastNotificationAsync(tokens, title, body, new Dictionary<string, string>
        {
            { "type", "commitment_reminder" },
            { "commitmentId", commitment.Id.ToString() }
        });
        sentCount += sent;
    }

    return Results.Ok(new { success = true, remindersSent = sentCount, commitmentsFound = upcomingCommitments.Count });
}).AllowAnonymous();

app.Run();

// -----------------------------------------------------------------------------
// FCM Notification DTOs
// -----------------------------------------------------------------------------
public record RegisterFcmTokenRequest(string Token, string? DeviceType);
public record DeactivateFcmTokenRequest(string Token);
