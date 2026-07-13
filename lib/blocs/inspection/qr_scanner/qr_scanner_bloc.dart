import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../models/inspection_model.dart';
import '../../../repositories/inspection_repository.dart';

part 'qr_scanner_event.dart';
part 'qr_scanner_state.dart';

class QrScannerBloc extends Bloc<QrScannerEvent, QrScannerState> {
  final InspectionRepository _repo;

  QrScannerBloc(this._repo) : super(QrScannerIdle()) {
    on<QrCodeDetected>(_onQrCodeDetected);
  }

  Future<void> _onQrCodeDetected(
      QrCodeDetected event, Emitter<QrScannerState> emit) async {
    emit(QrScannerProcessing());
    final result = await _repo.scanQr(event.raw);
    if (result.success && result.data != null) {
      emit(QrScannerScanned(result.data!));
    } else {
      emit(QrScannerScanFailure(
          (result.error?.isNotEmpty ?? false)
              ? result.error!
              : AppStrings.invalidQrCode));
    }
  }
}
