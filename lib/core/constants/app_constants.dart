class AppConstants {
  AppConstants._();

  static const String appName = 'Y-CheckPro';
  static const String appTagline = 'Inspect. Verify. Drive with Confidence.';
  static const String appVersion = '1.0.0';
  static const String packageName = 'Y-CheckPro.Evs';

  // Support Contact
  static const String supportPhone = '+1 (800) 555-3522';
  static const String supportEmail = 'support@ycheckpro.com';
  static const String supportWebsite = 'https://www.ycheckpro.com';

  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyDriverData = 'driver_data';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyFcmToken = 'fcm_token';
  // Saved so an expired token can be silently renewed via /auth/login
  // without interrupting the driver mid-task (see SessionManager).
  static const String keyAuthIdentifier = 'auth_identifier';
  static const String keyAuthPassword = 'auth_password';

  // OTP
  static const int otpLength = 6;
  static const int otpExpirySeconds = 45;
  static const int otpMaxAttempts = 3;

  // Pagination
  static const int pageSize = 20;

  // Additional notes char limitc:\Users\Satish\Downloads\app_icon 2\icon\512.png
  static const int notesMaxChars = 1000;

  // Splash
  static const int splashDurationMs = 2000;

  // Timeout
  static const int apiTimeoutSeconds = 30;
}
