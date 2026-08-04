import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../repositories/inspection_repository.dart';
import '../../routes/app_router.dart';

/// QR Scanner Screen
///
/// Opens the camera, scans a FleetCheck vehicle QR code, calls the API to
/// validate it, and navigates to InspectionTypeScreen on success.
///
/// Validation flow (enforced on both server and client):
///   1. QR code must exist in the system.
///   2. QR code must not be deactivated.
///   3. QR code must belong to the driver's company.
///   4. QR code (or its pending job) must be assigned to this driver.
///
/// On any validation failure the camera is paused and a full-screen
/// error overlay is shown with the exact error message from the server.
/// The exact spec message for assignment failure is:
///   "Access denied. This vehicle job is not assigned to your account."
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {

  final _repo        = InspectionRepository();
  final _controller  = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing:         CameraFacing.back,
    torchEnabled:   false,
  );

  // ── State machine ─────────────────────────────────────────────────────────
  _ScanState _state      = _ScanState.scanning;
  bool       _torchOn    = false;
  String     _errorTitle = '';
  String     _errorMsg   = '';
  bool       _isAccessDenied = false; // drives the icon & colour

  // Scan line animation
  late AnimationController _lineAnim;
  late Animation<double>   _linePos;

  @override
  void initState() {
    super.initState();
    _lineAnim = AnimationController(
      vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _linePos  = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _lineAnim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    _lineAnim.dispose();
    super.dispose();
  }

  // ── Scan handler ──────────────────────────────────────────────────────────
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_state != _ScanState.scanning) return;

    final raw = capture.barcodes
        .where((b) => b.rawValue != null && b.rawValue!.isNotEmpty)
        .map((b) => b.rawValue!)
        .firstOrNull;

    if (raw == null) return;

    setState(() => _state = _ScanState.validating);
    await _controller.stop();

    // ── Detect Zone QR before calling any API ─────────────────
    // Zone QRs always start with ZQR- and must go to zone flow
    if (raw.startsWith('ZQR-')) {
      await context.push(AppRoutes.zoneWalkAround, extra: {
        'qr_code': raw,
        'qr_data': <String, dynamic>{},
      });
      if (mounted) _reset();
      return;
    }

    // Regular vehicle QR — existing flow
    final res = await _repo.scanQr(raw);

    if (!mounted) return;

    if (res.success && res.data != null) {
      await context.push(AppRoutes.inspectionType, extra: res.data!);
      if (mounted) _reset();
    } else {
      // ── Validation failed — show error overlay ─────────────────────────
      final msg = res.error ?? 'Unknown error occurred.';

      // Detect the exact "access denied" spec message from the server
      final isAccessDenied =
          msg.toLowerCase().contains('access denied') ||
          msg.toLowerCase().contains('not assigned to your account') ||
          msg.toLowerCase().contains('assigned to a different');

      // Detect deactivated / invalid codes
      final isInvalid =
          msg.toLowerCase().contains('not registered') ||
          msg.toLowerCase().contains('deactivated') ||
          msg.toLowerCase().contains('invalid');

      setState(() {
        _state          = _ScanState.error;
        _isAccessDenied = isAccessDenied;
        _errorTitle     = isAccessDenied
            ? 'Access Denied'
            : isInvalid
                ? 'Invalid QR Code'
                : 'Scan Failed';
        // Use exact spec message for access-denied case; otherwise show
        // the server message directly so it's informative.
        _errorMsg = isAccessDenied
            ? 'Access denied. This vehicle job is not assigned to your account.'
            : msg;
      });
    }
  }

  // ── Reset to scanning state ───────────────────────────────────────────────
  Future<void> _reset() async {
    setState(() {
      _state          = _ScanState.scanning;
      _isAccessDenied = false;
      _errorTitle     = '';
      _errorMsg       = '';
    });
    await _controller.start();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [

        // ── Camera view (always rendered, paused when not scanning) ─────
        MobileScanner(
          controller: _controller,
          onDetect:   _onDetect,
        ),

        // ── Dark overlay with cutout ────────────────────────────────────
        _ScanOverlay(linePos: _linePos, active: _state == _ScanState.scanning),

        // ── Top bar ─────────────────────────────────────────────────────
        _buildTopBar(),

        // ── State overlays ──────────────────────────────────────────────
        if (_state == _ScanState.validating) _buildValidatingOverlay(),
        if (_state == _ScanState.error)      _buildErrorOverlay(),

        // ── Bottom label (scanning state only) ──────────────────────────
        if (_state == _ScanState.scanning) _buildBottomLabel(),
      ]),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    final top = MediaQuery.of(context).padding.top;
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, top + 8, 16, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
          ),
        ),
        child: Row(children: [
          // Back
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const Expanded(
            child: Text('Scan QR Code',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w800)),
          ),
          // Torch toggle
          GestureDetector(
            onTap: () async {
              await _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: _torchOn
                    ? AppColors.secondary.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _torchOn ? Icons.flashlight_on_rounded
                         : Icons.flashlight_off_rounded,
                color: Colors.white, size: 20,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Bottom scanning hint ──────────────────────────────────────────────────
  Widget _buildBottomLabel() {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter, end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.qr_code_scanner_rounded,
              color: Colors.white, size: 28),
          const SizedBox(height: 8),
          const Text(
            'Position the QR code within the frame to scan',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            'Only QR codes assigned to your account will be accepted',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
          ),
        ]),
      ),
    );
  }

  // ── Validating spinner overlay ────────────────────────────────────────────
  Widget _buildValidatingOverlay() => Container(
    color: Colors.black.withValues(alpha: 0.75),
    child: Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2A4A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(
              color: AppColors.secondary, strokeWidth: 3),
          const SizedBox(height: 20),
          const Text('Validating QR Code…',
              style: TextStyle(color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Checking job assignment',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13)),
        ]),
      ),
    ),
  );

  // ── Error overlay ─────────────────────────────────────────────────────────
  Widget _buildErrorOverlay() {
    final bottom = MediaQuery.of(context).padding.bottom;
    final isAccess = _isAccessDenied;

    // Colours: red for access denied / invalid, amber for generic errors
    final color = isAccess ? AppColors.danger : AppColors.amber;
    final icon  = isAccess
        ? Icons.lock_rounded
        : Icons.qr_code_2_rounded;

    return Container(
      color: Colors.black.withValues(alpha: 0.92),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon circle
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape:  BoxShape.circle,
                  color:  color.withValues(alpha: 0.12),
                  border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
                ),
                child: Icon(icon, size: 44, color: color),
              ),
              const SizedBox(height: 24),

              // Error title
              Text(_errorTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: color, fontSize: 22,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),

              // Error message box
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color:        color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border:       Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _errorMsg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white,
                      fontSize: 15, height: 1.55, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 10),

              // Extra hint for access-denied
              if (isAccess)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Text(
                    'Please check with your company administrator that this '
                    'inspection job has been assigned to your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13, height: 1.5),
                  ),
                ),

              const SizedBox(height: 32),

              // Scan Again button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                  label: const Text('Scan Again',
                      style: TextStyle(fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Go back button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Go Back',
                      style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              SizedBox(height: bottom > 0 ? 0 : 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Scan frame overlay ────────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  final Animation<double> linePos;
  final bool active;
  const _ScanOverlay({required this.linePos, required this.active});

  @override
  Widget build(BuildContext context) {
    final size   = MediaQuery.of(context).size;
    final frame  = size.width * 0.68;
    final top    = (size.height - frame) / 2 - 40;

    return Stack(children: [
      // Dimmed surrounds
      Positioned(top: 0, left: 0, right: 0, height: top,
          child: _dim()),
      Positioned(top: top + frame, left: 0, right: 0, bottom: 0,
          child: _dim()),
      Positioned(top: top, left: 0, width: (size.width - frame) / 2, height: frame,
          child: _dim()),
      Positioned(top: top, right: 0, width: (size.width - frame) / 2, height: frame,
          child: _dim()),

      // Frame corners
      Positioned(
        top: top, left: (size.width - frame) / 2,
        child: _ScanFrame(size: frame, active: active),
      ),

      // Animated scan line (only while scanning)
      if (active)
        Positioned(
          left: (size.width - frame) / 2 + 4,
          top:  top,
          width: frame - 8,
          height: frame,
          child: AnimatedBuilder(
            animation: linePos,
            builder: (_, __) => Align(
              alignment: Alignment(0, linePos.value * 2 - 1),
              child: Container(
                height: 2.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent,
                    AppColors.secondary.withValues(alpha: 0.9),
                    Colors.transparent,
                  ]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
    ]);
  }

  Widget _dim() => Container(color: Colors.black.withValues(alpha: 0.62));
}

class _ScanFrame extends StatelessWidget {
  final double size;
  final bool   active;
  const _ScanFrame({required this.size, required this.active});

  @override
  Widget build(BuildContext context) {
    const r   = 14.0;
    const len = 28.0;
    const w   = 3.5;
    final col = active ? AppColors.secondary : Colors.white.withValues(alpha: 0.5);

    return SizedBox(width: size, height: size, child: CustomPaint(
      painter: _CornerPainter(color: col, radius: r, armLen: len, strokeW: w),
    ));
  }
}

class _CornerPainter extends CustomPainter {
  final Color  color;
  final double radius, armLen, strokeW;
  const _CornerPainter(
      {required this.color, required this.radius,
       required this.armLen, required this.strokeW});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = color
      ..strokeWidth = strokeW
      ..strokeCap   = StrokeCap.round
      ..style       = PaintingStyle.stroke;

    final corners = [
      // top-left
      [Offset(0, armLen + radius), Offset(0, radius),
       Offset(radius, 0), Offset(armLen + radius, 0)],
      // top-right
      [Offset(size.width, armLen + radius), Offset(size.width, radius),
       Offset(size.width - radius, 0), Offset(size.width - armLen - radius, 0)],
      // bottom-left
      [Offset(0, size.height - armLen - radius), Offset(0, size.height - radius),
       Offset(radius, size.height), Offset(armLen + radius, size.height)],
      // bottom-right
      [Offset(size.width, size.height - armLen - radius),
       Offset(size.width, size.height - radius),
       Offset(size.width - radius, size.height),
       Offset(size.width - armLen - radius, size.height)],
    ];

    for (final c in corners) {
      final path = Path()
        ..moveTo(c[0].dx, c[0].dy)
        ..arcToPoint(c[1], radius: Radius.circular(radius), clockwise: false)
        ..lineTo(c[2].dx, c[2].dy)
        ..arcToPoint(c[3], radius: Radius.circular(radius), clockwise: false);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}

// ── State enum ────────────────────────────────────────────────────────────────
enum _ScanState { scanning, validating, error }
