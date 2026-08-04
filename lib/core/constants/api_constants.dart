class ApiConstants {
  ApiConstants._();

  static const String baseUrl =
      'https://demo1.evirtualservices.com/fleetcheckapp/api';

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';

  // Driver
  static const String driverProfile = '/driver/profile';
  static const String updateProfile = '/driver/update-profile';
  static const String driverStats = '/driver/stats';

  // QR
  static const String qrScan = '/qr/scan';
  static const String scanQr = '/qr/scan'; // alias for inspection_repository
  static const String qrZoneScan = '/qr/zone-scan'; // Zone QR scan

  // Inspection
  static const String inspectionSubmit = '/inspection/submit';
  static const String inspectionList = '/inspection/list';
  static const String inspectionTemplates = '/inspection/templates';
  static const String inspectionChecklist = '/inspection/checklist';
  static const String zoneSubmit = '/inspection/zone-submit'; // Zone submit
  static const String zoneStatus = '/inspection/zone-status'; // Zone progress
  static String inspectionDetail(int id) => '/inspection/detail/$id';
  static String inspectionReport(int id) => '/inspection/report/$id';

  // Notifications
  static const String notifications = '/notifications';
  static const String markNotificationRead = '/notifications/mark-read';
  static const String fcmToken = '/notifications/fcm-token';
}
