import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../models/driver_model.dart';
import '../../../repositories/auth_repository.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _repo;

  LoginBloc(this._repo) : super(LoginInitial()) {
    on<LoginSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
      LoginSubmitted event, Emitter<LoginState> emit) async {
    emit(LoginLoading());
    final result = await _repo.login(
      identifier: event.identifier,
      password: event.password,
    );
    if (result.success && result.data != null) {
      emit(LoginSuccess(result.data!));
    } else {
      emit(LoginFailure(result.error ?? AppStrings.invalidCreds));
    }
  }
}
