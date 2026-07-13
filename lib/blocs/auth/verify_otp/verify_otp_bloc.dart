import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../repositories/auth_repository.dart';

part 'verify_otp_event.dart';
part 'verify_otp_state.dart';

class VerifyOtpBloc extends Bloc<VerifyOtpEvent, VerifyOtpState> {
  final AuthRepository _repo;

  VerifyOtpBloc(this._repo) : super(const VerifyOtpState()) {
    on<OtpSubmitted>(_onSubmitted);
    on<OtpResendRequested>(_onResendRequested);
  }

  Future<void> _onSubmitted(
      OtpSubmitted event, Emitter<VerifyOtpState> emit) async {
    emit(VerifyOtpState(isVerifying: true, isResending: state.isResending));
    final result =
        await _repo.verifyOtp(identifier: event.identifier, otp: event.otp);
    if (result.success) {
      emit(VerifyOtpState(
        isResending: state.isResending,
        verifiedResetToken: result.data ?? '',
      ));
    } else {
      emit(VerifyOtpState(
        isResending: state.isResending,
        verifyError: result.error ?? AppStrings.otpInvalid,
      ));
    }
  }

  Future<void> _onResendRequested(
      OtpResendRequested event, Emitter<VerifyOtpState> emit) async {
    emit(VerifyOtpState(isVerifying: state.isVerifying, isResending: true));
    final result = await _repo.resendOtp(event.identifier);
    if (result.success) {
      emit(VerifyOtpState(
        isVerifying: state.isVerifying,
        resendSucceeded: true,
      ));
    } else {
      emit(VerifyOtpState(
        isVerifying: state.isVerifying,
        resendError: result.error ?? AppStrings.otpMaxAttempts,
      ));
    }
  }
}
