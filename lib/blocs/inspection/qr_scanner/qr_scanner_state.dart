part of 'qr_scanner_bloc.dart';

sealed class QrScannerState {}

final class QrScannerIdle extends QrScannerState {}

final class QrScannerProcessing extends QrScannerState {}

final class QrScannerScanned extends QrScannerState {
  final QrData qrData;
  QrScannerScanned(this.qrData);
}

final class QrScannerScanFailure extends QrScannerState {
  final String message;
  QrScannerScanFailure(this.message);
}
