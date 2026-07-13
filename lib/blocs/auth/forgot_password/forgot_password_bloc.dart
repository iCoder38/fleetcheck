import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../repositories/auth_repository.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final AuthRepository _repo;

  ForgotPasswordBloc(this._repo) : super(ForgotPasswordInitial()) {
    on<ForgotPasswordSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
      ForgotPasswordSubmitted event, Emitter<ForgotPasswordState> emit) async {
    emit(ForgotPasswordLoading());
    final result = await _repo.forgotPassword(event.identifier);
    if (result.success) {
      emit(ForgotPasswordSuccess(event.identifier));
    } else {
      emit(ForgotPasswordFailure(result.error ?? AppStrings.invalidIdentifier));
    }
  }
}
