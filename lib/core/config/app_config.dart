enum Environment { uat, prod }

/// Global application environment configuration.
class AppConfig {
  final Environment environment;
  final String appName;
  final String baseUrl;
  final String db;

  static late AppConfig _instance;

  AppConfig._({
    required this.environment,
    required this.appName,
    required this.baseUrl,
    required this.db,
  });

  /// Initialize environment config before launching the app.
  static void init({
    required Environment environment,
    required String appName,
    required String baseUrl,
    required String db,
  }) {
    _instance = AppConfig._(
      environment: environment,
      appName: appName,
      baseUrl: baseUrl,
      db: db,
    );
  }

  /// Active environment configuration instance.
  static AppConfig get instance {
    if (!isInitialized) {
      // Default to UAT configuration if accessed before explicit init
      init(
        environment: Environment.uat,
        appName: 'Timeless Detailing UAT',
        baseUrl:
            'https://keerthan-lfi-lfi-timeless-detailing1-uat-37440283.dev.odoo.com',
        db: 'keerthan-lfi-lfi-timeless-detailing1-uat-37440283',
      );
    }
    return _instance;
  }

  /// Checks if AppConfig has been initialized.
  static bool get isInitialized {
    try {
      // Accessing _instance will throw LateInitializationError if uninitialized
      final _ = _instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  bool get isUat => environment == Environment.uat;
  bool get isProd => environment == Environment.prod;
}
