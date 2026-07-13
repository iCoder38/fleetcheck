import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../repositories/auth_repository.dart';

part 'create_password_event.dart';
part 'create_password_state.dart';

class CreatePasswordBloc extends Bloc<CreatePasswordEvent, CreatePasswordState> {
  final AuthRepository _repo;

  CreatePasswordBloc(this._repo) : super(CreatePasswordInitial()) {
    on<ResetPasswordSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
      ResetPasswordSubmitted event, Emitter<CreatePasswordState> emit) async {
    emit(CreatePasswordLoading());
    final result = await _repo.resetPassword(
      resetToken: event.resetToken,
      password: event.password,
      confirmPassword: event.confirmPassword,
    );
    if (result.success) {
      emit(CreatePasswordSuccess());
    } else {
      emit(CreatePasswordFailure(
          result.error ?? 'Failed to reset password. Please try again.'));
    }
  }
}
