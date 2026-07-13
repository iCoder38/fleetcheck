part of 'login_bloc.dart';

sealed class LoginState {}

final class LoginInitial extends LoginState {}

final class LoginLoading extends LoginState {}

final class LoginSuccess extends LoginState {
  final DriverModel driver;
  LoginSuccess(this.driver);
}

final class LoginFailure extends LoginState {
  final String message;
  LoginFailure(this.message);
}
