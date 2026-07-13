part of 'verify_otp_bloc.dart';

/// Verify and resend are two independent async flows on the same screen,
/// so this state holds both sets of flags rather than a single sealed
/// hierarchy (mirrors the original dual bool-flag setState implementation).
class VerifyOtpState {
  final bool isVerifying;
  final bool isResending;
  final String? verifyError;
  final String? resendError;
  final String? verifiedResetToken;
  final bool resendSucceeded;

  const VerifyOtpState({
    this.isVerifying = false,
    this.isResending = false,
    this.verifyError,
    this.resendError,
    this.verifiedResetToken,
    this.resendSucceeded = false,
  });
}
