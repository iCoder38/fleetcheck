part of 'verify_otp_bloc.dart';

sealed class VerifyOtpEvent {}

final class OtpSubmitted extends VerifyOtpEvent {
  final String identifier;
  final String otp;
  OtpSubmitted({required this.identifier, required this.otp});
}

final class OtpResendRequested extends VerifyOtpEvent {
  final String identifier;
  OtpResendRequested(this.identifier);
}
