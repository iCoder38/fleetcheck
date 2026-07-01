class ApiConstants {
  ApiConstants._();

  static const String _base =
      'https://demo1.evirtualservices.com/fleetcheckapp/api/';

  static String get baseUrl => _base;

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
  static const String uploadPhoto = '/driver/upload-photo';

  // QR
  static const String scanQr = '/qr/scan';

  // Inspection
  static const String submitInspection = '/inspection/submit';
  static const String inspectionList = '/inspection/list';
  static String inspectionDetail(int id) => '/inspection/detail/$id';
  static String downloadReport(int id) => '/inspection/report/$id';

  // Notifications
  static const String notifications = '/notifications';
  static const String markNotifRead = '/notifications/mark-read';
  static const String updateFcmToken = '/notifications/fcm-token';
}
