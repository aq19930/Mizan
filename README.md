# MIZAN — ميزان
> **Balance your money. Own your future.**
> **وازن صرفك. خطط لبكرا.**

MIZAN is an AI-powered personal finance and smart budgeting mobile application crafted primarily for users in Saudi Arabia. Built with **Flutter + Dart** on mobile and **ASP.NET Core Web API (.NET 10)** with **Entity Framework Core** on the backend.

---

## 🏛 Clean Architecture & Monorepo Layout

```
e:\all-project\Mizan\
├── Mizan.slnx                         # Modern .NET 10 Solution file
├── .gitignore                         # Standard Git ignore rules
├── README.md                          # Project documentation
├── photo/
│   └── Mizan.png                      # High-resolution brand board & visual truth reference
├── src/
│   ├── Mizan.Domain/                  # Entities (User, Wallet, Transaction, Category, Budget, etc.), Enums
│   ├── Mizan.Application/             # Business Logic, IBalanceEngine, IBudgetEngine, Services, DTOs
│   ├── Mizan.Infrastructure/          # EF Core DbContext (MizanDbContext), SqlServer config
│   ├── Mizan.Contracts/               # Shared API request/response contracts
│   └── Mizan.Api/                     # ASP.NET Core Web API, Minimal endpoints, Health check, CORS
├── tests/
│   ├── Mizan.UnitTests/               # xUnit unit tests (BalanceEngine, BudgetEngine)
│   └── Mizan.IntegrationTests/        # xUnit integration tests
└── mobile/                            # Flutter Mobile Application
    ├── pubspec.yaml                   # Flutter dependencies & assets registration
    ├── l10n.yaml                      # Flutter internationalization config
    ├── assets/
    │   └── images/                    # Extracted Mizan brand logos (light/dark), emblem, app icon
    ├── test/
    │   └── widget_test.dart           # Automated widget and Riverpod state tests
    └── lib/
        ├── main.dart                  # Riverpod ProviderScope bootstrap
        ├── core/
        │   ├── constants/             # AppConstants (assets, endpoints, storage keys)
        │   ├── theme/                 # AppColors, AppTypography, AppTheme, ThemeProvider
        │   ├── network/               # DioClient with auth token & error interceptors
        │   ├── routing/               # GoRouter paths (/splash, /onboarding, /login, /home)
        │   └── localization/          # LocaleProvider (Arabic RTL / English LTR switcher)
        ├── l10n/                      # ARB translations (app_ar.arb, app_en.arb)
        ├── shared/
        │   └── widgets/               # MizanButton, MizanCard, MizanLogo, LanguageSwitcher, ThemeToggle
        └── features/
            ├── splash/                # Animated branded splash screen (#0F4D3A)
            ├── onboarding/            # 4-page interactive onboarding with smooth page indicator
            ├── auth/                  # Branded login screen placeholder
            └── home/                  # High-fidelity dashboard preview from reference design
```

---

## 🎨 Visual Identity & Palette

- **Primary Deep Green**: `#0F4D3A`
- **Accent Green**: `#22C55E`
- **Secondary Sage**: `#A7C957`
- **Background Cream**: `#F5F1E8`
- **Dark Text**: `#1F2937`
- **Neutral Beige**: `#D4C9B6`
- **White**: `#FFFFFF`
- **Typography**: `Inter` (English) and `IBM Plex Sans Arabic` (Arabic) with full RTL support.

---

## 🚀 Getting Started

### 1. Backend (.NET 10)
```bash
# Build the solution
dotnet build

# Run unit tests
dotnet test

# Run API server
dotnet run --project src/Mizan.Api/Mizan.Api.csproj
```
Health Check Endpoint: `https://localhost:5001/api/health`

### 2. Mobile App (Flutter)
```bash
cd mobile

# Fetch dependencies
flutter pub get

# Generate localizations
flutter gen-l10n

# Analyze codebase
flutter analyze

# Run unit and widget tests
flutter test

# Launch mobile application
flutter run
```

---

## ✅ Phase 1 & Phase 2 Verification Status
- **ASP.NET Core Build**: Build succeeded (0 Warning, 0 Error).
- **ASP.NET Core Tests**: 10 passed, 0 failed.
- **Flutter Analyzer**: Clean (No issues found).
- **Flutter Tests**: 8 passed, 0 failed.
