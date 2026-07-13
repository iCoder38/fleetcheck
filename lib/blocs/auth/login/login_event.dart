part of 'login_bloc.dart';

sealed class LoginEvent {}

final class LoginSubmitted extends LoginEvent {
  final String identifier;
  final String password;
  LoginSubmitted({required this.identifier, required this.password});
}
