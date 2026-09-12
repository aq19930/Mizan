import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'MIZAN'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Balance your money. Own your future.'**
  String get appTagline;

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'Know where your money goes'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Desc.
  ///
  /// In en, this message translates to:
  /// **'Comprehensive tracking that categorizes your daily spending automatically and gives you complete clarity.'**
  String get onboarding1Desc;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Track automatically'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Desc.
  ///
  /// In en, this message translates to:
  /// **'Detect bank transactions safely and instantly without manual hassle or privacy compromises.'**
  String get onboarding2Desc;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Build a smarter budget'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Desc.
  ///
  /// In en, this message translates to:
  /// **'Dynamic limits that adapt to your lifestyle with real-time health indicators and warnings.'**
  String get onboarding3Desc;

  /// No description provided for @onboarding4Title.
  ///
  /// In en, this message translates to:
  /// **'Plan for tomorrow'**
  String get onboarding4Title;

  /// No description provided for @onboarding4Desc.
  ///
  /// In en, this message translates to:
  /// **'Smart AI forecasts anticipate your spending for tomorrow so you always stay ahead.'**
  String get onboarding4Desc;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @currencySar.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get currencySar;

  /// No description provided for @chooseLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get chooseLanguageTitle;

  /// No description provided for @chooseLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can switch the app language at any time in settings'**
  String get chooseLanguageSubtitle;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @authWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Balance Your Money with Mizan'**
  String get authWelcomeTitle;

  /// No description provided for @authWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join an intelligent experience to budget, save, and track your daily spending with total privacy.'**
  String get authWelcomeSubtitle;

  /// No description provided for @createNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Create New Account'**
  String get createNewAccount;

  /// No description provided for @haveAccountAlready.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccountAlready;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your account credentials to continue'**
  String get loginSubtitle;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account in seconds and start your financial journey'**
  String get registerSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @agreeTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Service & Privacy Policy'**
  String get agreeTerms;

  /// No description provided for @passwordStrength.
  ///
  /// In en, this message translates to:
  /// **'Password Strength'**
  String get passwordStrength;

  /// No description provided for @weak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get weak;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @strong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strong;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @validEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get validEmailRequired;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get nameRequired;

  /// No description provided for @passwordLengthRequired.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordLengthRequired;

  /// No description provided for @mustAgreeTerms.
  ///
  /// In en, this message translates to:
  /// **'You must agree to the terms to continue'**
  String get mustAgreeTerms;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed, please verify your credentials'**
  String get loginFailed;

  /// No description provided for @registerFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed, please try again'**
  String get registerFailed;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered email and we will securely send you password reset instructions.'**
  String get forgotPasswordDesc;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset instructions have been sent to your email'**
  String get resetLinkSent;

  /// No description provided for @accountSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Account is Ready!'**
  String get accountSuccessTitle;

  /// No description provided for @accountSuccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Mizan. Let\'s take a few quick steps to configure your wallet and smart budget.'**
  String get accountSuccessDesc;

  /// No description provided for @startSetup.
  ///
  /// In en, this message translates to:
  /// **'Start Setup'**
  String get startSetup;

  /// No description provided for @setupStepProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get setupStepProfile;

  /// No description provided for @setupStepBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get setupStepBalance;

  /// No description provided for @setupStepBudget.
  ///
  /// In en, this message translates to:
  /// **'Monthly Budget'**
  String get setupStepBudget;

  /// No description provided for @setupStepCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get setupStepCategories;

  /// No description provided for @setupStepNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get setupStepNotifications;

  /// No description provided for @setupStepPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Tracking'**
  String get setupStepPrivacy;

  /// No description provided for @profileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Up Your Profile'**
  String get profileSetupTitle;

  /// No description provided for @profileSetupDesc.
  ///
  /// In en, this message translates to:
  /// **'Tell us how you would like to be addressed and your preferred currency'**
  String get profileSetupDesc;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @preferredCurrency.
  ///
  /// In en, this message translates to:
  /// **'Primary Currency'**
  String get preferredCurrency;

  /// No description provided for @balanceSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'What is your current balance?'**
  String get balanceSetupTitle;

  /// No description provided for @balanceSetupDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter the total funds available across your accounts to establish an accurate starting point.'**
  String get balanceSetupDesc;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get availableBalance;

  /// No description provided for @balanceConfirmQuestion.
  ///
  /// In en, this message translates to:
  /// **'Confirm this balance amount?'**
  String get balanceConfirmQuestion;

  /// No description provided for @balanceConfirmPrompt.
  ///
  /// In en, this message translates to:
  /// **'This amount will be used as the initial baseline for your Mizan balance engine.'**
  String get balanceConfirmPrompt;

  /// No description provided for @yesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Yes, Confirm'**
  String get yesConfirm;

  /// No description provided for @budgetSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Target Monthly Budget'**
  String get budgetSetupTitle;

  /// No description provided for @budgetSetupDesc.
  ///
  /// In en, this message translates to:
  /// **'Set your total desired monthly expenditure cap to safeguard your financial well-being.'**
  String get budgetSetupDesc;

  /// No description provided for @monthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Total Monthly Budget'**
  String get monthlyBudget;

  /// No description provided for @savingsGoal.
  ///
  /// In en, this message translates to:
  /// **'Suggested Savings Goal (20%)'**
  String get savingsGoal;

  /// No description provided for @emergencyReserve.
  ///
  /// In en, this message translates to:
  /// **'Emergency Reserve (10%)'**
  String get emergencyReserve;

  /// No description provided for @categoryBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Category Budget Allocations'**
  String get categoryBudgetTitle;

  /// No description provided for @categoryBudgetDesc.
  ///
  /// In en, this message translates to:
  /// **'Allocate your budget among major spending categories to receive timely alerts.'**
  String get categoryBudgetDesc;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Notification Preferences'**
  String get notificationsTitle;

  /// No description provided for @notificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose alerts that keep you informed without overwhelming you.'**
  String get notificationsDesc;

  /// No description provided for @notifyTransactions.
  ///
  /// In en, this message translates to:
  /// **'Instant alert on each transaction'**
  String get notifyTransactions;

  /// No description provided for @notifyDailySummary.
  ///
  /// In en, this message translates to:
  /// **'Daily evening spending summary'**
  String get notifyDailySummary;

  /// No description provided for @notifyBudgetLimits.
  ///
  /// In en, this message translates to:
  /// **'Warnings when nearing budget limits'**
  String get notifyBudgetLimits;

  /// No description provided for @notifyBillReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders for scheduled bills and commitments'**
  String get notifyBillReminders;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Detection & Privacy'**
  String get privacyTitle;

  /// No description provided for @privacyDesc.
  ///
  /// In en, this message translates to:
  /// **'Mizan strictly protects your privacy. Bank SMS messages are parsed locally on your device and are never transmitted to external servers.'**
  String get privacyDesc;

  /// No description provided for @enableSmartDetection.
  ///
  /// In en, this message translates to:
  /// **'Enable Bank SMS Tracking'**
  String get enableSmartDetection;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now, I will record manually'**
  String get notNow;

  /// No description provided for @setupCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'You Are All Set!'**
  String get setupCompleteTitle;

  /// No description provided for @setupCompleteDesc.
  ///
  /// In en, this message translates to:
  /// **'Your wallet and financial plan are ready. Start tracking and owning your financial future.'**
  String get setupCompleteDesc;

  /// No description provided for @goToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to Dashboard'**
  String get goToDashboard;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalance;

  /// No description provided for @spentToday.
  ///
  /// In en, this message translates to:
  /// **'Spent Today'**
  String get spentToday;

  /// No description provided for @dailyLimit.
  ///
  /// In en, this message translates to:
  /// **'Daily Limit'**
  String get dailyLimit;

  /// No description provided for @expectedTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Expected Tomorrow'**
  String get expectedTomorrow;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @spendingByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by Category'**
  String get spendingByCategory;

  /// No description provided for @budgetHealth.
  ///
  /// In en, this message translates to:
  /// **'Budget Health'**
  String get budgetHealth;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @seeAllTransactions.
  ///
  /// In en, this message translates to:
  /// **'All Transactions'**
  String get seeAllTransactions;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransaction;

  /// No description provided for @transactionType.
  ///
  /// In en, this message translates to:
  /// **'Transaction Type'**
  String get transactionType;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @merchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant / Payee'**
  String get merchant;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @transactionDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get transactionDate;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @referenceNumber.
  ///
  /// In en, this message translates to:
  /// **'Reference Number'**
  String get referenceNumber;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transactionDetails;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @sourceManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get sourceManual;

  /// No description provided for @sourceAuto.
  ///
  /// In en, this message translates to:
  /// **'Bank SMS Detection'**
  String get sourceAuto;

  /// No description provided for @confidenceScore.
  ///
  /// In en, this message translates to:
  /// **'Confidence Score'**
  String get confidenceScore;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @noTransactionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Record your first transaction or enable automatic detection'**
  String get noTransactionsDesc;

  /// No description provided for @searchTransactions.
  ///
  /// In en, this message translates to:
  /// **'Search merchant, category or notes...'**
  String get searchTransactions;

  /// No description provided for @allFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFilter;

  /// No description provided for @expensesFilter.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesFilter;

  /// No description provided for @incomesFilter.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomesFilter;

  /// No description provided for @budgetOverview.
  ///
  /// In en, this message translates to:
  /// **'Budget Overview'**
  String get budgetOverview;

  /// No description provided for @budgetSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get budgetSpent;

  /// No description provided for @budgetRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get budgetRemaining;

  /// No description provided for @daysRemainingInMonth.
  ///
  /// In en, this message translates to:
  /// **'Days remaining'**
  String get daysRemainingInMonth;

  /// No description provided for @safeStatus.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get safeStatus;

  /// No description provided for @warningStatus.
  ///
  /// In en, this message translates to:
  /// **'Caution'**
  String get warningStatus;

  /// No description provided for @dangerStatus.
  ///
  /// In en, this message translates to:
  /// **'Danger'**
  String get dangerStatus;

  /// No description provided for @exceededStatus.
  ///
  /// In en, this message translates to:
  /// **'Exceeded'**
  String get exceededStatus;

  /// No description provided for @aiInsightsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Financial Insights'**
  String get aiInsightsTitle;

  /// No description provided for @aiForecastTitle.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow\'s Spending Forecast'**
  String get aiForecastTitle;

  /// No description provided for @aiConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence Score'**
  String get aiConfidence;

  /// No description provided for @smartRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Personalized Recommendations'**
  String get smartRecommendations;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @securityLock.
  ///
  /// In en, this message translates to:
  /// **'Security & App Lock'**
  String get securityLock;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @aboutMizan.
  ///
  /// In en, this message translates to:
  /// **'About Mizan'**
  String get aboutMizan;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account Permanently'**
  String get deleteAccount;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirm;

  /// No description provided for @setupStepCommitments.
  ///
  /// In en, this message translates to:
  /// **'Financial Commitments'**
  String get setupStepCommitments;

  /// No description provided for @financialCommitments.
  ///
  /// In en, this message translates to:
  /// **'Financial Commitments'**
  String get financialCommitments;

  /// No description provided for @commitmentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage installments, bills, and recurring subscriptions'**
  String get commitmentsSubtitle;

  /// No description provided for @committedAmount.
  ///
  /// In en, this message translates to:
  /// **'Committed Reserved'**
  String get committedAmount;

  /// No description provided for @availableToSpend.
  ///
  /// In en, this message translates to:
  /// **'Available to Spend'**
  String get availableToSpend;

  /// No description provided for @addCommitment.
  ///
  /// In en, this message translates to:
  /// **'Add Commitment'**
  String get addCommitment;

  /// No description provided for @commitmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Commitment Title'**
  String get commitmentTitle;

  /// No description provided for @commitmentCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get commitmentCategory;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @merchantOrEntity.
  ///
  /// In en, this message translates to:
  /// **'Merchant / Payee'**
  String get merchantOrEntity;

  /// No description provided for @markPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark Paid'**
  String get markPaid;

  /// No description provided for @markedAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Successfully marked as paid'**
  String get markedAsPaid;

  /// No description provided for @upcomingCommitments.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Commitments'**
  String get upcomingCommitments;

  /// No description provided for @bankParserPlayground.
  ///
  /// In en, this message translates to:
  /// **'Bank Parser Playground'**
  String get bankParserPlayground;

  /// No description provided for @bankParserDesc.
  ///
  /// In en, this message translates to:
  /// **'Test local parsing engine for Saudi bank SMS messages'**
  String get bankParserDesc;

  /// No description provided for @detectedTransaction.
  ///
  /// In en, this message translates to:
  /// **'Detected Bank Transaction'**
  String get detectedTransaction;

  /// No description provided for @reviewDetectedTransaction.
  ///
  /// In en, this message translates to:
  /// **'Review Detected Transaction'**
  String get reviewDetectedTransaction;

  /// No description provided for @confirmAndSave.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Save Transaction'**
  String get confirmAndSave;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @localPrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Privacy: SMS parsing runs strictly 100% on-device. Raw text is never uploaded to servers.'**
  String get localPrivacyNotice;

  /// No description provided for @matchedCommitmentDetected.
  ///
  /// In en, this message translates to:
  /// **'A matching financial commitment was detected for this transaction'**
  String get matchedCommitmentDetected;

  /// No description provided for @aiAdvisorTitle.
  ///
  /// In en, this message translates to:
  /// **'Mizan Financial Advisor'**
  String get aiAdvisorTitle;

  /// No description provided for @aiAdvisorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask about your finances'**
  String get aiAdvisorSubtitle;

  /// No description provided for @aiWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Hello 👋\nI am Mizan Financial Advisor.'**
  String get aiWelcomeTitle;

  /// No description provided for @aiWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'I can help you understand your spending, commitments, budget, and plan your financial decisions based on your Mizan data.\n\nWhat would you like to know?'**
  String get aiWelcomeBody;

  /// No description provided for @aiInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type your financial question...'**
  String get aiInputHint;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// No description provided for @previousChats.
  ///
  /// In en, this message translates to:
  /// **'Previous Chats'**
  String get previousChats;

  /// No description provided for @clearChat.
  ///
  /// In en, this message translates to:
  /// **'Clear Chat'**
  String get clearChat;

  /// No description provided for @askAboutLoan.
  ///
  /// In en, this message translates to:
  /// **'Ask about a loan'**
  String get askAboutLoan;

  /// No description provided for @askAboutPurchase.
  ///
  /// In en, this message translates to:
  /// **'Ask about a purchase'**
  String get askAboutPurchase;

  /// No description provided for @organizeSalary.
  ///
  /// In en, this message translates to:
  /// **'Organize my budget'**
  String get organizeSalary;

  /// No description provided for @viewCommitments.
  ///
  /// In en, this message translates to:
  /// **'Upcoming commitments'**
  String get viewCommitments;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
