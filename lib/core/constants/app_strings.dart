class AppStrings {
  AppStrings._();

  // Auth
  static const String login            = 'Login';
  static const String tagline          = 'Inspect. Verify. Drive with Confidence.';
  static const String logout           = 'Logout';
  static const String forgotPassword   = 'Forgot Password?';
  static const String contactSupport   = 'Contact Support';
  static const String sendOtp          = 'Send OTP';
  static const String verifyOtp        = 'Verify OTP';
  static const String resendOtp        = 'Resend OTP';
  static const String createPassword   = 'Create New Password';
  static const String enterNewPassword = 'Enter New Password';
  static const String confirmPassword  = 'Confirm Password';

  // Login hints
  static const String hintIdentifier  = 'Enter your ID or Phone number';
  static const String hintPassword    = 'Enter your Password';

  // Validation
  static const String fieldRequired    = 'This field is required';
  static const String invalidCreds     = 'Invalid Employee ID/Badge ID or Phone Number';
  static const String invalidPassword  = 'Invalid Password';
  static const String passwordMismatch = 'The new password does not match the confirmed password.';
  static const String otpExpired       = 'OTP has expired. Please request a new OTP.';
  static const String otpInvalid       = 'You have entered an invalid OTP.';
  static const String otpMaxAttempts   = 'Maximum OTP attempts reached. Please try again after 24 hours.';
  static const String invalidIdentifier = 'Invalid Employee ID / Badge ID / Phone number';

  // Dashboard
  static const String scanQrCode          = 'Scan QR Code';
  static const String totalAssigned       = 'Total Assigned';
  static const String preTripCompleted    = 'Pre-Trip Done';
  static const String postTripCompleted   = 'Post-Trip Done';
  static const String pendingInspections  = 'Pending';
  static const String recentActivity      = 'Recent Activity';

  // Inspection
  static const String inspectionType       = 'Select Inspection Type';
  static const String preTrip              = 'Pre-Trip Inspection';
  static const String postTrip             = 'Post-Trip Inspection';
  static const String startInspection      = 'Start Inspection';
  static const String truckInformation     = 'Truck Information';
  static const String continueBtn          = 'Continue';
  static const String previousBtn          = 'Previous';
  static const String nextBtn              = 'Next';
  static const String submitBtn            = 'Submit';
  static const String editBtn              = 'Edit';
  static const String confirmContinue      = 'Confirm & Continue';
  static const String additionalNotes      = 'Additional Notes';
  static const String inspectionOverview   = 'Inspection Overview';
  static const String gpsVerification      = 'GPS Verification';
  static const String inspectionReview     = 'Inspection Review';
  static const String submissionSuccess    = 'Inspection Successfully Submitted!';
  static const String submissionSubtitle   = 'Your inspection report has been recorded.';

  // Defect
  static const String defectReport         = 'Vehicle Defect / Damage Report';
  static const String defectCategory       = 'Defect / Damage Category';
  static const String severityLevel        = 'Severity Level';
  static const String description          = 'Description';
  static const String saveDefect           = 'Save Defect';

  // Profile
  static const String driverProfile   = 'Driver Profile';
  static const String editProfile     = 'Edit Profile';
  static const String changePassword  = 'Change Password';
  static const String currentPassword = 'Current Password';

  // Errors
  static const String invalidQrCode   = 'Invalid QR Code or QR Code not registered with the system';
  static const String gpsRequired     = 'GPS must be enabled to submit inspection';
  static const String pdfFailed       = 'Unable to generate report. Please try again.';
  static const String shareFailed     = 'Report sharing failed. Please check back later.';
  static const String dialerFailed    = 'Unable to open dialer.';
  static const String emailFailed     = 'Unable to open email app or email app does not exist.';
  static const String browserFailed   = 'Unable to open website.';

  // Logout confirm
  static const String confirmLogout        = 'Confirm Logout';
  static const String confirmLogoutMessage = 'Are you sure you want to logout?';
  static const String cancel               = 'Cancel';

  // Notifications
  static const String notifications        = 'Notifications';
  static const String allNotifications     = 'All';
  static const String unread               = 'Unread';

  // History
  static const String inspectionHistory    = 'Inspection History';

  // Help
  static const String helpSupport          = 'Help & Support';

  // ── Intro ──────────────────────────────────────────────
  static const List<String> introTitles = [
    'Smart Fleet Inspections',
    'QR Code Scanning',
    'Real-Time GPS Reports',
    'Drive with Confidence',
  ];

  static const List<String> introDescriptions = [
    'Complete pre-trip and post-trip vehicle inspections quickly and efficiently from your phone.',
    'Scan vehicle QR codes to instantly access all vehicle details and start your inspection.',
    'Submit inspection reports in real-time with automatic GPS location verification.',
    'Ensure your fleet meets safety compliance standards. Start inspecting today.',
  ];

  // ── Validation ─────────────────────────────────────────
  static const String allFieldsRequired = 'All checklist items must be marked before proceeding.';
}
