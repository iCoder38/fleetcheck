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
  static const String sessionExpiredMessage = 'Session expired. Please log in again.';

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
  static const String gpsEnabledLabel      = 'GPS ENABLED';
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
    'Welcome to Y-CheckPro',
    'Inspect Vehicles Anywhere',
    'Stay Ahead of Vehicle Issues',
    'Drive Compliance with Confidence',
  ];

  static const List<String> introDescriptions = [
    'Manage vehicle inspections, track fleet conditions, and maintain compliance with an easy-to-use digital inspection platform designed for modern fleet operations.',
    'Complete detailed vehicle inspections directly from your mobile device. Record issues, capture photos, add notes, and submit reports instantly from the field.',
    'Identify defects before they become costly repairs. Monitor inspection results, track maintenance needs, and keep every vehicle operating safely and efficiently.',
    'Maintain accurate inspection records, meet regulatory requirements, and ensure your fleet remains safe, compliant, and road-ready at all times.',
  ];

  // ── Validation ─────────────────────────────────────────
  static const String allFieldsRequired = 'All checklist items must be marked before proceeding.';

  // ── Intro ──────────────────────────────────────────────
  static const String introSkip       = 'Skip';
  static const String introBack       = 'Back';
  static const String introNext       = 'Next';
  static const String introGetStarted = 'Get Started';

  // ── Login ──────────────────────────────────────────────
  static const String driverLoginTitle    = 'Driver Login';
  static const String driverLoginSubtitle = 'Sign in with your Employee ID or Phone';
  static const String labelIdentifier     = 'Employee ID / Badge ID / Phone';
  static const String labelPassword       = 'Password';
  static const String welcomeBackTitle    = 'Welcome Back!';
  static const String pleaseLoginToContinue = 'Please login to continue';
  static const String needHelpPrefix      = 'Need help? ';
  static String copyright(int year) => '© $year Y-CheckPro. All rights reserved.';

  // ── Verify OTP ─────────────────────────────────────────
  static const String otpHeaderTitle   = 'Enter Verification Code';
  static String otpSentTo(String identifier) => 'We sent a 6-digit code to\n$identifier';
  static const String otpExpiredShort  = 'OTP has expired.';
  static const String otpExpiresInPrefix = 'Expires in ';
  static const String otpResentSuccess = 'OTP resent successfully.';
  static const String otpDigitsRequired = 'Please enter all 6 digits.';
  static const String otpSubtitle =
      'We have sent the verification code to your phone number or registered email ID.';
  static const String otpEnterCaption = 'Enter 6 digits OTP sent to Phone number';
  static const String otpDidntReceive = 'Didn\'t receive? ';

  // ── Forgot Password ────────────────────────────────────
  static const String forgotPasswordAppBarTitle = 'Forgot Password';
  static const String forgotPasswordDescription =
      'Enter your Employee ID / Badge ID / Phone number and we\'ll send a verification code.';
  static const String labelIdentifierFull = 'Employee ID / Badge ID / Phone Number';
  static const String backToLogin = 'Back to Login';
  static const String forgotPasswordWarning =
      'Use the Employee ID or phone number registered with your fleet manager.';
  static const String hintIdentifierForgot = 'Enter your Employee ID / Badge ID';

  // ── Create / Change Password ───────────────────────────
  static const String passwordMinLength     = 'Password must be at least 6 characters.';
  static const String passwordCreatedSuccess = 'Password created successfully! Please log in.';
  static const String createPasswordSubtitle =
      'Your new password must be different from your previous password.';
  static const String labelNewPassword     = 'New Password';
  static const String labelConfirmPassword = 'Confirm Password';
  static const String setNewPassword       = 'Set New Password';
  static const String changePasswordWarning =
      'Choose a strong password you haven\'t used before on this account.';

  // ── Dashboard ──────────────────────────────────────────
  static const String welcomeBack         = 'Welcome back!';
  static const String welcomeBackLabel    = 'Welcome Back';
  static const String defaultDriverName   = 'Driver';
  static const String activeLabel         = 'Active';
  static const String quickStats          = 'Quick Stats';
  static const String viewAll             = 'View All';
  static const String noRecentInspections = 'No recent inspections.';
  static const String totalInspectionsLabel = 'Total Inspections';
  static const String scanQrSubtitle = 'Tap to scan and start inspection';
  static String empIdLabel(String id) => 'EMP ID: $id';
  static String agoMinutes(int n) => '${n}m ago';
  static String agoHours(int n) => '${n}h ago';
  static String agoDays(int n) => '${n}d ago';
  static const String justNow = 'Just now';
  static const String navHome    = 'Home';
  static const String navHistory = 'History';
  static const String navAlerts  = 'Notifications';
  static const String navProfile = 'Profile';
  static const String navLogout  = 'Logout';

  // ── Inspection Type ────────────────────────────────────
  static const String inspectionTypeAppBarTitle = 'Inspection Type';
  static const String assignedJobLabel = 'Assigned Job';
  static const String qrCodeVerified       = 'QR Code Verified';
  static const String vehicleDriverDetails = 'Vehicle & Driver Details';
  static const String chooseInspectionType = 'Choose Inspection Type';
  static const String preTripShort  = 'Pre-Trip';
  static const String postTripShort = 'Post-Trip';
  static const String preTripCardSubtitle  = 'Inspect vehicle before starting your Trip';
  static const String postTripCardSubtitle = 'Inspect vehicle after completing your Trip';
  static const String selectTypeHint = '⚠  Please select an inspection type to continue.';
  static const String labelVehicleNumber = 'Vehicle Number';
  static const String labelTrailerNumber = 'Trailer Number';
  static const String labelDriverName    = 'Driver Name';
  static const String labelDateTime      = 'Date & Time';
  static const String labelGpsLocation   = 'GPS Location';
  static const String fetchingEllipsis   = 'Fetching…';
  static const String fetchingLocationEllipsis = 'Fetching location…';
  static const String gpsDisabledShort = 'GPS disabled';
  static const String locationPermissionDeniedShort = 'Location permission denied';
  static const String unableToFetchLocation = 'Unable to fetch location';
  static const String assignedInspectionType = 'Assigned Inspection Type';
  static const String requiredBadge = 'Required';

  // ── QR Scanner ─────────────────────────────────────────
  static const String verifyingQrCode   = 'Verifying QR Code...';
  static const String positionQrCodeHint = 'Position the QR code within the frame to scan';

  // ── Truck Info ─────────────────────────────────────────
  static const String vehicleDetails      = 'Vehicle Details';
  static const String driverVerification  = 'Driver Verification';
  static const String autoFilledNote =
      'All details are automatically filled from the scanned QR Code. Please verify before continuing.';
  static const String labelTruckNumber  = 'Truck Number';
  static const String labelVinNumber    = 'VIN Number';
  static const String labelLicensePlate = 'License Plate';
  static const String labelFleetNumber  = 'Fleet Number';
  static const String labelCompanyName  = 'Company Name';
  static const String labelEmployeeId   = 'Employee ID';
  static const String verifiedLabel     = 'Verified';

  // ── Checklist ──────────────────────────────────────────
  static String sectionCounter(int current, int total) => 'Section $current of $total';
  static String sectionLabel(int n) => 'SECTION $n';
  static String itemsFraction(int completed, int total) => '$completed/$total';
  static String percentComplete(int pct) => '$pct% Complete';
  static String notesOptionalHint(int max) => 'Optional — up to $max characters';
  static const String notesHint = 'Add any additional notes or observations here...';
  static const String finishAndContinue = 'Finish & Continue';
  static const String allSetLabel = 'All set';
  static const String notesPendingLabel = 'Optional';
  static String itemsCheckedCounter(int completed, int total) =>
      '$completed / $total items checked';

  // ── Defect Report ──────────────────────────────────────
  static const String defectReportAppBarTitle = 'Defect Report';
  static const String reportDefectDamageTitle = 'Report Defect / Damage';
  static String vehicleLabel(String v)   => 'Vehicle: $v';
  static const String categoryLabel      = 'Category';
  static const String addNewLabel        = 'Add New';
  static const String savedDefects       = 'Saved Defects';
  static const String addDefectReport    = 'Add Defect Report';
  static const String selectCategoryHint = 'Select category';
  static const String describeDamageHint = 'Describe the damage or defect in detail...';
  static const String fillAllFields      = 'Please fill all fields.';
  static const String defectSaved        = 'Defect saved.';
  static const String doneReturnToChecklist = 'Done — Return to Checklist';

  // ── GPS Verification ───────────────────────────────────
  static const String yourCurrentLocation = 'Your Current Location';
  static const String gpsAutoCaptureDesc =
      'We automatically capture your current GPS location for this inspection.';
  static const String gpsDisabled = 'GPS is disabled on this device. Please enable GPS and try again.';
  static const String locationPermissionDenied =
      'Location permission was denied. Please allow location access.';
  static const String locationPermissionPermanentlyDenied =
      'Location permission is permanently denied. Please enable it in device settings.';
  static const String locationCapturedFallback = 'Location captured';
  static const String locationCaptureFailed = 'Failed to capture location. Please try again.';
  static const String gpsError       = 'GPS Error';
  // Per-failure error card titles — shown above the detail message so the
  // driver immediately knows which of the several distinct GPS failure
  // modes they hit, instead of one flat "GPS Error" label for all of them.
  static const String gpsServicesOffTitle = 'Location Services Off';
  static const String permissionDeniedTitle = 'Permission Denied';
  static const String permissionDeniedForeverTitle = 'Permission Permanently Denied';
  static const String locationNotAvailableTitle = 'Location Not Available';
  static const String tryAgain       = 'Try Again';
  static const String refreshLocation = 'Refresh Location';
  static const String capturingLocation = 'Capturing your location...';
  static const String ensureGpsEnabled  = 'Please ensure GPS is enabled.';
  static const String gpsCaptureHint = 'This may take up to 30 seconds. Keep the app open.';
  static const String requestingLocationPermission = 'Requesting location permission…';
  static const String gettingYourLocation = 'Getting your location…';
  static const String tryingBackupLocationMethod = 'Trying backup location method…';
  static const String usingLastKnownLocation = 'Using last known location…';
  static const String fetchingAddress = 'Fetching address…';
  static const String couldNotDetermineLocation =
      'Could not determine your location. Make sure GPS is enabled and you have a clear view of the sky.';
  static String accuracyLabel(int meters, String tier) => 'Accuracy: ±${meters}m ($tier)';
  static const String accuracyHigh   = 'High';
  static const String accuracyMedium = 'Medium';
  static const String accuracyLow    = 'Low';
  static const String lowAccuracyWarning =
      'Low GPS accuracy detected. This may happen indoors or in areas with poor signal. '
      'You can retry for a better fix or continue with the current reading.';
  static const String skipGpsVerification = 'Skip GPS Verification';
  static const String skipGpsTitle = 'Skip GPS?';
  static const String skipGpsBody =
      'Proceeding without GPS location. The inspection will be submitted without location coordinates.\n\nDo you want to continue?';
  static const String continueWithoutGps = 'Continue Without GPS';
  static const String gpsNotAvailable = 'GPS not available';
  static const String gpsCaptured       = 'GPS Captured';
  static const String locationVerifiedSuccess = 'Location verified successfully';
  static const String labelGpsStatus = 'GPS Status';
  static const String gpsStatusEnabled = '✓ Enabled';
  static const String gpsActiveBanner =
      'GPS Active — location captured. You can now submit your inspection.';
  static const String labelLatitude  = 'Latitude';
  static const String labelLongitude = 'Longitude';
  static const String labelAddress   = 'Address';
  static const String labelDate      = 'Date';
  static const String labelTime      = 'Time';

  // ── Submission Success ─────────────────────────────────
  static const String reportDownloadedSuccess = 'Inspection report downloaded successfully.';
  static const String labelInspectionId   = 'Inspection ID';
  static const String labelInspectionType = 'Inspection Type';
  static const String generatingPdf = 'Generating PDF...';
  static const String downloadPdf   = 'Download PDF';
  static const String sharingLabel  = 'Sharing...';
  static const String shareReport   = 'Share Report';
  static const String returnToDashboard = 'Return to Dashboard';

  // ── Inspection Review ──────────────────────────────────
  static const String reviewSubtitle =
      'Review your inspection before submitting. Once submitted you cannot edit it.';
  static const String vehicleInspectionTitle = 'Vehicle & Inspection';
  static const String truckDetailsTitle      = 'Truck Details';
  static const String checklistResultsTitle  = 'Checklist Results';
  static const String defectsFoundTitle      = 'Defects Found';
  static const String totalItemsChecked = 'Total Items Checked';
  static const String statTotal         = 'Total';
  static const String statPassed        = 'Passed';
  static const String statDefects       = 'Defects';
  static String itemsPassedCaption(int passed, int total) => '$passed / $total items passed';
  static const String itemsPassed       = 'Items Passed';
  static const String defectsIssues     = 'Defects / Issues';
  static const String labelCoordinates  = 'Coordinates';
  static const String labelCapturedAt   = 'Captured At';
  static const String labelStartedAt    = 'Started At';
  static String reportedDefectsTitle(int count) => 'Reported Defects ($count)';
  static const String submittingLabel = 'Submitting...';

  // ── Profile ────────────────────────────────────────────
  static const String editProfileSubtitle ='You can update your phone number.';
  static const String labelPhoneNumber = 'Phone Number';
  static const String labelEmailAddress = 'Email Address';
  static const String saveChanges = 'Save Changes';
  static const String minSixChars = 'Min 6 characters';
  static const String labelConfirmNewPassword = 'Confirm New Password';
  static const String activeVerified = 'Active · Verified';
  static const String inactiveLabel  = 'Inactive';
  static const String personalInformation = 'Personal Information';
  static const String licenseInformation  = 'License Information';
  static const String profileUpdatedSuccess  = 'Profile updated successfully.';
  static const String passwordChangedSuccess = 'Password changed successfully.';
  static const String labelBadgeId       = 'Badge ID';
  static const String labelLicenseNumber = 'License Number';
  static const String labelLicenseExpiry = 'License Expiry';

  // ── History ────────────────────────────────────────────
  static const String dateRangeAll       = 'All';
  static const String dateRangeToday     = 'Today';
  static const String dateRangeYesterday = 'Yesterday';
  static const String dateRangeWeek      = 'Last 7 Days';
  static const String dateRangeCustom    = 'Custom';
  static const String allTypesHint  = 'All Types';
  static const String allStatusHint = 'All Status';
  static const String statusCompletedLabel   = 'Completed';
  static const String statusPendingLabel     = 'Pending';
  static const String statusRejectedLabel    = 'Rejected';
  static const String statusUnderReviewLabel = 'Under Review';
  static const String searchVehicleHint = 'Search by Vehicle Number';
  static const String noInspectionsFound = 'No inspections found.';
  static const String adjustFilters = 'Try adjusting your filters.';

  // ── History Detail ─────────────────────────────────────
  static const String inspectionSummary = 'Inspection Summary';
  static const String labelVin     = 'VIN';
  static const String labelCompany = 'Company';
  static const String labelType    = 'Type';
  static const String labelStatus  = 'Status';
  static String checklistAnswersTitle(int count) => 'Checklist Answers ($count)';
  static String defectsReportedTitle(int count) => 'Defects Reported ($count)';
  static const String shareLabel = 'Share';
  static const String detailFallback = 'Detail';
  static const String inspectionDetailAppBarTitle = 'Inspection Detail';
  static const String retryLabel = 'Retry';

  // ── Notifications ──────────────────────────────────────
  static const String markAllRead = 'Mark all read';
  static const String notifTypeNewAssignment = 'New Assignment';
  static const String notifTypeReminder      = 'Inspection Reminder';
  static const String notifTypeManagement    = 'Management Message';
  static const String noUnreadNotifications  = 'No unread notifications.';
  static const String noNotificationsYet     = 'No notifications yet.';
  static const String vechileInformation     = 'Vehicle information';
  static String referenceLabel(String id) => 'Reference: $id';

  // ── Help ───────────────────────────────────────────────
  static const String contactUs = 'Contact Us';
  static const String contactUsSubtitle = 'Reach out through any of the options below.';
  static const String labelWebsite = 'Website';
  static const String helpSupportSubtitle = 'Get in touch with us';
  static const String designedForFleetOps = 'Designed for modern fleet operations.';
  static String versionLabel(String version) => 'Version $version';
}
