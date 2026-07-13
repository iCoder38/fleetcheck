part of 'create_password_bloc.dart';

sealed class CreatePasswordState {}

final class CreatePasswordInitial extends CreatePasswordState {}

final class CreatePasswordLoading extends CreatePasswordState {}

final class CreatePasswordSuccess extends CreatePasswordState {}

final class CreatePasswordFailure extends CreatePasswordState {
  final String message;
  CreatePasswordFailure(this.message);
}
