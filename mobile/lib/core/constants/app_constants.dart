class AppConstants {
  AppConstants._();

  // App Metadata
  static const String appNameEn = 'MIZAN';
  static const String appNameAr = 'ميزان';
  static const String taglineEn = 'Balance your money. Own your future.';
  static const String taglineAr = 'وازن صرفك. خطط لبكرا.';

  // Image Assets
  static const String logoDark = 'assets/images/mizan_logo_dark.png';
  static const String logoLight = 'assets/images/mizan_logo_light.png';
  static const String appIcon = 'assets/images/mizan_app_icon.png';
  static const String symbol = 'assets/images/mizan_symbol.png';

  // API Config
  static const String defaultBaseUrl = 'https://api.mizan.app/api';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Preference / Storage Keys
  static const String prefKeyOnboardingComplete = 'mizan_onboarding_completed';
  static const String prefKeyLocale = 'mizan_locale_code';
  static const String prefKeyThemeMode = 'mizan_theme_mode';
  static const String storageKeyAccessToken = 'mizan_access_token';
  static const String storageKeyRefreshToken = 'mizan_refresh_token';

  // Currency
  static const String defaultCurrency = 'SAR';
  static const String currencySymbolAr = 'ر.س';
}
