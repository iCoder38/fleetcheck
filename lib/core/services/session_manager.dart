import 'package:flutter/material.dart';
import '../constants/app_strings.dart';
import 'storage_service.dart';

/// Central place to react to an expired/invalid session from anywhere in
/// the app (API interceptors, repositories) without needing a BuildContext.
///
/// main.dart wires [onSessionExpired] to the router at startup and passes
/// [messengerKey] to MaterialApp so a "session expired" notice can be shown
/// from code that has no widget tree access. ApiService calls
/// [handleSessionExpired] whenever an authenticated request comes back
/// with a 401.
class SessionManager {
  SessionManager._();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Set once at app startup to redirect to the login route. Kept as a
  /// callback (rather than importing app_router.dart here) to avoid a
  /// circular import — app_router already depends on repositories that
  /// depend on ApiService, which depends on this file.
  static VoidCallback? onSessionExpired;

  static bool _handled = false;

  // Auth endpoints that legitimately return 401 for reasons other than an
  // expired session (bad credentials/OTP) — must never trigger a forced
  // logout, or a wrong-password login attempt would log the user "out"
  // and bounce them straight back to the login screen they're already on.
  static const _publicPaths = <String>[
    '/auth/login',
    '/auth/forgot-password',
    '/auth/verify-otp',
    '/auth/resend-otp',
    '/auth/reset-password',
  ];

  static bool isPublicPath(String path) =>
      _publicPaths.any((p) => path.contains(p));

  /// Clears the stored session and bounces the user to login with a
  /// "session expired" notice. Safe to call repeatedly — only the first
  /// call (until [reset]) acts, so a burst of parallel 401s from
  /// in-flight requests doesn't fire multiple redirects/snackbars.
  ///
  /// ApiService only reaches this after a silent relogin attempt (via the
  /// saved credentials) has already failed, so the saved credentials are
  /// stale/invalid too — clear them along with the token so the app
  /// doesn't keep retrying a login that will never succeed.
  static Future<void> handleSessionExpired() async {
    if (_handled) return;
    _handled = true;

    final storage = StorageService();
    await storage.deleteToken();
    await storage.deleteDriverData();
    await storage.deleteCredentials();
    await storage.setLoggedIn(false);

    onSessionExpired?.call();
    messengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text(AppStrings.sessionExpiredMessage)),
    );
  }

  /// Call after a fresh successful login so a later 401 can trigger the
  /// flow again.
  static void reset() => _handled = false;
}
