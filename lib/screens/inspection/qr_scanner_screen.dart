// lib/screens/inspection/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/inspection_model.dart';
import '../../repositories/inspection_repository.dart';
import '../../routes/app_router.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});
  @override State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed:  DetectionSpeed.noDuplicates,
    returnImage:     false,
    facing:          CameraFacing.back,
  );
  bool _flashOn   = false;
  bool _processing = false;
  String? _error;

  late final InspectionRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = InspectionRepository();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _onQrDetected(String qrString) async {
    if (_processing) return;
    setState(() { _processing = true; _error = null; });
    _controller.stop();

    final result = await _repo.scanQr(qrString);
    if (!mounted) return;

    if (result.success && result.data != null) {
      context.push(AppRoutes.inspectionType, extra: result.data);
    } else {
      setState(() {
        _error = (result.error?.isNotEmpty ?? false) ? result.error! : AppStrings.invalidQrCode;
        _processing = false;
      });
      _controller.start();
    }
  }

  void _toggleFlash() {
    setState(() => _flashOn = !_flashOn);
    _controller.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                _onQrDetected(barcode!.rawValue!);
              }
            },
          ),

          // Dark overlay with scan frame
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ScanOverlayPainter(),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                  ),
                  const Expanded(
                    child: Text('Scan QR Code', textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                  GestureDetector(
                    onTap: _toggleFlash,
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: _flashOn ? AppColors.amber.withOpacity(0.3) : Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          color: _flashOn ? AppColors.amber : Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.red.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 13))),
                        ]),
                      ),
                    if (_processing && _error == null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.greenLight)),
                          SizedBox(width: 12),
                          Text('Verifying QR Code...', style: TextStyle(color: Colors.white, fontSize: 14)),
                        ]),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          'Position the QR code within the frame to scan',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.55);
    final frameSize = size.width * 0.72;
    final left   = (size.width  - frameSize) / 2;
    final top    = (size.height - frameSize) / 2 - 40;
    final frame  = Rect.fromLTWH(left, top, frameSize, frameSize);
    final full   = Rect.fromLTWH(0, 0, size.width, size.height);

    // Dark overlay with hole
    final path = Path()
      ..addRect(full)
      ..addRRect(RRect.fromRectAndRadius(frame, const Radius.circular(16)));
    canvas.drawPath(path..fillType = PathFillType.evenOdd, paint);

    // Corner brackets
    final cornerPaint = Paint()
      ..color        = AppColors.greenLight
      ..strokeWidth  = 3
      ..style        = PaintingStyle.stroke
      ..strokeCap    = StrokeCap.round;

    const c = 24.0; // corner length
    final r = 16.0;

    // Top-left
    canvas.drawLine(Offset(left + r, top), Offset(left + r + c, top), cornerPaint);
    canvas.drawLine(Offset(left, top + r), Offset(left, top + r + c), cornerPaint);
    // Top-right
    canvas.drawLine(Offset(left + frameSize - r - c, top), Offset(left + frameSize - r, top), cornerPaint);
    canvas.drawLine(Offset(left + frameSize, top + r), Offset(left + frameSize, top + r + c), cornerPaint);
    // Bottom-left
    canvas.drawLine(Offset(left + r, top + frameSize), Offset(left + r + c, top + frameSize), cornerPaint);
    canvas.drawLine(Offset(left, top + frameSize - r - c), Offset(left, top + frameSize - r), cornerPaint);
    // Bottom-right
    canvas.drawLine(Offset(left + frameSize - r - c, top + frameSize), Offset(left + frameSize - r, top + frameSize), cornerPaint);
    canvas.drawLine(Offset(left + frameSize, top + frameSize - r - c), Offset(left + frameSize, top + frameSize - r), cornerPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}
