import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/driver_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/inspection_repository.dart';

part 'driver_profile_event.dart';
part 'driver_profile_state.dart';

class DriverProfileBloc extends Bloc<DriverProfileEvent, DriverProfileState> {
  final AuthRepository _authRepo;
  final InspectionRepository _inspRepo;

  DriverProfileBloc(this._authRepo, this._inspRepo)
      : super(const DriverProfileState()) {
    on<ProfileLoadRequested>(_onLoadRequested);
    on<ProfileUpdateRequested>(_onUpdateRequested);
    on<PasswordChangeRequested>(_onPasswordChangeRequested);
  }

  void _onLoadRequested(
      ProfileLoadRequested event, Emitter<DriverProfileState> emit) {
    final cached = _authRepo.getCachedDriver();
    if (cached != null) {
      emit(DriverProfileState(
        driver: cached,
        isChangingPassword: state.isChangingPassword,
      ));
    }
  }

  Future<void> _onUpdateRequested(
      ProfileUpdateRequested event, Emitter<DriverProfileState> emit) async {
    emit(DriverProfileState(
      driver: state.driver,
      isUpdatingProfile: true,
      isChangingPassword: state.isChangingPassword,
    ));
    final result = await _inspRepo.updateProfile(
      phone: event.phone,
      email: event.email,
    );
    if (result.success && result.data != null) {
      emit(DriverProfileState(
        driver: result.data,
        profileUpdateSucceeded: true,
        isChangingPassword: state.isChangingPassword,
      ));
    } else {
      emit(DriverProfileState(
        driver: state.driver,
        updateError: result.error ?? 'Update failed.',
        isChangingPassword: state.isChangingPassword,
      ));
    }
  }

  Future<void> _onPasswordChangeRequested(
      PasswordChangeRequested event, Emitter<DriverProfileState> emit) async {
    emit(DriverProfileState(
      driver: state.driver,
      isChangingPassword: true,
    ));
    final result = await _authRepo.changePassword(
      currentPassword: event.currentPassword,
      newPassword: event.newPassword,
      confirmPassword: event.confirmPassword,
    );
    if (result.success) {
      emit(DriverProfileState(
        driver: state.driver,
        passwordChangeSucceeded: true,
      ));
    } else {
      emit(DriverProfileState(
        driver: state.driver,
        passwordError: result.error ?? 'Failed to change password.',
      ));
    }
  }
}
