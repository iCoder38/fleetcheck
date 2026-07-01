import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/services/storage_service.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/intro_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/verify_otp_screen.dart';
import '../screens/auth/create_password_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/inspection/qr_scanner_screen.dart';
import '../screens/inspection/defect_report_screen.dart';
import '../screens/inspection/inspection_type_screen.dart';
import '../screens/inspection/truck_info_screen.dart';
import '../screens/inspection/checklist/checklist_screen.dart';
import '../screens/inspection/gps_verification_screen.dart';
import '../screens/inspection/inspection_review_screen.dart';
import '../screens/inspection/submission_success_screen.dart';
import '../screens/profile/driver_profile_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/history/inspection_history_screen.dart';
import '../screens/history/inspection_history_detail_screen.dart';
import '../screens/help/help_support_screen.dart';
import '../models/inspection_model.dart';

class AppRoutes {
  static const String splash              = '/';
  static const String intro               = '/intro';
  static const String login               = '/login';
  static const String forgotPassword      = '/forgot-password';
  static const String verifyOtp           = '/verify-otp';
  static const String createPassword      = '/create-password';
  static const String dashboard           = '/dashboard';
  static const String qrScanner          = '/qr-scanner';
  static const String inspectionType      = '/inspection-type';
  static const String truckInfo           = '/truck-info';
  static const String checklist           = '/checklist';
  static const String defectReport        = '/defect-report';
  static const String gpsVerification     = '/gps-verification';
  static const String inspectionReview    = '/inspection-review';
  static const String submissionSuccess   = '/submission-success';
  static const String profile             = '/profile';
  static const String notifications       = '/notifications';
  static const String history             = '/history';
  static const String historyDetail       = '/history/:id';
  static const String help                = '/help';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.intro,
      builder: (_, __) => const IntroScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (_, __) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.verifyOtp,
      builder: (context, state) {
        final identifier = state.extra as String? ?? '';
        return VerifyOtpScreen(identifier: identifier);
      },
    ),
    GoRoute(
      path: AppRoutes.createPassword,
      builder: (context, state) {
        final extra = state.extra as Map<String, String>? ?? {};
        return CreatePasswordScreen(
          identifier: extra['identifier'] ?? '',
          resetToken: extra['reset_token'] ?? '',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      builder: (_, __) => const DashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.qrScanner,
      builder: (_, __) => const QrScannerScreen(),
    ),
    GoRoute(
      path: AppRoutes.inspectionType,
      builder: (context, state) {
        final qrData = state.extra as QrData;
        return InspectionTypeScreen(qrData: qrData);
      },
    ),
    GoRoute(
      path: AppRoutes.truckInfo,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return TruckInfoScreen(
          qrData: extra['qrData'] as QrData,
          inspectionType: extra['inspectionType'] as String,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.checklist,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return ChecklistScreen(
          qrData: extra['qrData'] as QrData,
          inspectionType: extra['inspectionType'] as String,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.defectReport,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return DefectReportScreen(
          damagedItems:    extra['damagedItems'] as List<String>,
          existingDefects: extra['defects'] as List<DefectReport>? ?? [],
        );
      },
    ),
        GoRoute(
      path: AppRoutes.gpsVerification,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return GpsVerificationScreen(submission: extra['submission'] as InspectionSubmission);
      },
    ),
    GoRoute(
      path: AppRoutes.inspectionReview,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return InspectionReviewScreen(submission: extra['submission'] as InspectionSubmission);
      },
    ),
    GoRoute(
      path: AppRoutes.submissionSuccess,
      builder: (context, state) {
        final result = state.extra as InspectionResult;
        return SubmissionSuccessScreen(result: result);
      },
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (_, __) => const DriverProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      builder: (_, __) => const NotificationsScreen(),
    ),
    GoRoute(
      path: AppRoutes.history,
      builder: (_, __) => const InspectionHistoryScreen(),
    ),
    GoRoute(
      path: AppRoutes.historyDetail,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
        return InspectionHistoryDetailScreen(inspectionId: id);
      },
    ),
    GoRoute(
      path: AppRoutes.help,
      builder: (_, __) => const HelpSupportScreen(),
    ),
  ],
  redirect: (context, state) {
    final storage = StorageService();
    final loggedIn = storage.isLoggedIn;
    final onAuth = state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.intro ||
        state.matchedLocation == AppRoutes.splash ||
        state.matchedLocation == AppRoutes.forgotPassword ||
        state.matchedLocation == AppRoutes.verifyOtp ||
        state.matchedLocation == AppRoutes.createPassword;

    if (!loggedIn && !onAuth) return AppRoutes.login;
    return null;
  },
);
