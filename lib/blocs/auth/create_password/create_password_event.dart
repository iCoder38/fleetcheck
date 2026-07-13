part of 'create_password_bloc.dart';

sealed class CreatePasswordEvent {}

final class ResetPasswordSubmitted extends CreatePasswordEvent {
  final String resetToken;
  final String password;
  final String confirmPassword;
  ResetPasswordSubmitted({
    required this.resetToken,
    required this.password,
    required this.confirmPassword,
  });
}
