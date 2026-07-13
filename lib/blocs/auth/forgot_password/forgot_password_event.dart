part of 'forgot_password_bloc.dart';

sealed class ForgotPasswordEvent {}

final class ForgotPasswordSubmitted extends ForgotPasswordEvent {
  final String identifier;
  ForgotPasswordSubmitted(this.identifier);
}
