part of 'qr_scanner_bloc.dart';

sealed class QrScannerEvent {}

final class QrCodeDetected extends QrScannerEvent {
  final String raw;
  QrCodeDetected(this.raw);
}
