enum AppEnvironment {
  dev,
  prod,
}

class ApiConfig {
  ApiConfig._();

  static const String _envString = String.fromEnvironment('MIZAN_ENV', defaultValue: 'prod');
  static const String _explicitBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Resolves the current runtime environment
  static AppEnvironment get environment {
    switch (_envString.toLowerCase()) {
      case 'dev':
      case 'development':
        return AppEnvironment.dev;
      case 'prod':
      case 'production':
      default:
        return AppEnvironment.prod;
    }
  }

  static bool get isProduction => environment == AppEnvironment.prod;
  static bool get isDevelopment => environment == AppEnvironment.dev;

  /// Development Base URL (Android Emulator to local ASP.NET Core)
  static const String devBaseUrl = 'http://10.0.2.2:5125/api';

  /// Production Base URL (Google Cloud Run HTTPS)
  static const String prodBaseUrl = 'https://mizan-api-production.run.app/api';

  /// Returns the active API base URL
  static String get baseUrl {
    if (_explicitBaseUrl.isNotEmpty) {
      return _explicitBaseUrl;
    }
    return isProduction ? prodBaseUrl : devBaseUrl;
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
