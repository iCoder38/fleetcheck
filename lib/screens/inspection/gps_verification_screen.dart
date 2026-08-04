import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_responsive.dart';
import '../../models/inspection_model.dart';
import '../../routes/app_router.dart';

class GpsVerificationScreen extends StatefulWidget {
  final QrData qrData;
  final String inspectionType;
  final List<ChecklistResponse> responses;
  final List<DefectReport> defects;
  final String? additionalNotes;

  const GpsVerificationScreen({
    super.key,
    required this.qrData,
    required this.inspectionType,
    required this.responses,
    required this.defects,
    this.additionalNotes,
  });

  @override
  State<GpsVerificationScreen> createState() => _GpsVerificationScreenState();
}

class _GpsVerificationScreenState extends State<GpsVerificationScreen> {
  _GpsState _state      = _GpsState.loading;
  String    _statusText = 'Checking location services…';
  String    _errorTitle = 'GPS Error';
  String    _errorDetail = '';

  Position? _position;
  String    _address     = '';
  DateTime  _capturedAt  = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Small delay so the loading UI renders before async work starts
    Future.delayed(const Duration(milliseconds: 300), _captureLocation);
  }

  Future<void> _captureLocation() async {
    if (!mounted) return;
    setState(() {
      _state       = _GpsState.loading;
      _statusText  = 'Checking location services…';
      _errorDetail = '';
      _position    = null;
      _address     = '';
    });

    try {
      // ── Step 1: Location service enabled? ────────────────────────────
      bool serviceEnabled;
      try {
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      } catch (e) {
        serviceEnabled = false;
      }

      if (!serviceEnabled) {
        _fail('Location Services Off',
            'GPS is turned off on this device.\n\n'
            'Go to: Settings → Location → Turn On GPS\n\n'
            'Then tap Try Again.',
            openSettings: true);
        return;
      }

      // ── Step 2: Runtime permission ────────────────────────────────────
      if (!mounted) return;
      setState(() => _statusText = 'Requesting location permission…');

      LocationPermission perm;
      try {
        perm = await Geolocator.checkPermission();
      } catch (e) {
        _fail('Permission Check Failed',
            'Could not check location permission.\n'
            'Error: ${e.toString()}\n\n'
            'Please restart the app and try again.');
        return;
      }

      if (perm == LocationPermission.denied) {
        try {
          perm = await Geolocator.requestPermission();
        } catch (e) {
          _fail('Permission Request Failed',
              'Could not request location permission.\n'
              'Error: ${e.toString()}\n\n'
              'Go to: Settings → Apps → Y-CheckPro → Permissions → Location → Allow');
          return;
        }
      }

      if (perm == LocationPermission.denied) {
        _fail('Permission Denied',
            'Location permission was denied.\n\n'
            'Tap "Try Again" and select "Allow" when prompted.');
        return;
      }

      if (perm == LocationPermission.deniedForever) {
        _fail('Permission Permanently Denied',
            'Location permission is permanently blocked.\n\n'
            'Go to:\nSettings → Apps → Y-CheckPro → Permissions → Location → Allow\n\n'
            'Then return to the app.',
            openSettings: true);
        return;
      }

      // ── Step 3: Get position — 3 accuracy levels with fallback ────────
      if (!mounted) return;
      setState(() => _statusText = 'Getting your GPS location…');

      Position? position;
      String method = 'unknown';

      // Try 1: Medium accuracy — uses Network + GPS (works indoors, fast)
      try {
        setState(() => _statusText = 'Locating via GPS + Network…');
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 25),
        );
        method = 'medium accuracy';
      } catch (e1) {
        debugPrint('[GPS] Medium accuracy failed: $e1');

        // Try 2: Low accuracy — cell towers only (always available)
        try {
          setState(() => _statusText = 'Trying network-only location…');
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.lowest,
            timeLimit: const Duration(seconds: 15),
          );
          method = 'low accuracy (network)';
        } catch (e2) {
          debugPrint('[GPS] Low accuracy failed: $e2');

          // Try 3: Last known position — no timeout, immediate
          try {
            setState(() => _statusText = 'Using last known location…');
            position = await Geolocator.getLastKnownPosition();
            if (position != null) method = 'last known position';
          } catch (e3) {
            debugPrint('[GPS] Last known failed: $e3');
          }
        }
      }

      if (!mounted) return;

      if (position == null) {
        _fail('Location Not Available',
            'Unable to determine your location after multiple attempts.\n\n'
            'Please:\n'
            '• Move outdoors or near a window\n'
            '• Make sure GPS is enabled\n'
            '• Check that location permission is set to "Allow"\n\n'
            'You can also tap "Skip GPS" to continue without location.');
        return;
      }

      // ── Step 4: Reverse geocode ───────────────────────────────────────
      if (!mounted) return;
      setState(() => _statusText = 'Getting address…');

      // Coordinate string as safe fallback
      String address =
          '${position.latitude.toStringAsFixed(5)}° N, '
          '${position.longitude.toStringAsFixed(5)}° E';

      try {
        final marks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 8));

        if (marks.isNotEmpty) {
          final p = marks.first;
          final parts = [
            p.street, p.subLocality, p.locality,
            p.administrativeArea, p.country,
          ].where((s) => s != null && s.isNotEmpty).toList();
          if (parts.isNotEmpty) address = parts.join(', ');
        }
      } catch (_) {
        // Geocoding failed — use coordinates, non-fatal
      }

      if (!mounted) return;
      setState(() {
        _state       = _GpsState.success;
        _position    = position;
        _address     = address;
        _capturedAt  = DateTime.now();
        _statusText  = 'Location captured ($method)';
      });

    } catch (e) {
      if (!mounted) return;
      _fail('GPS Error',
          'An unexpected error occurred:\n${e.toString()}\n\n'
          'Please try again or use Skip GPS.');
    }
  }

  void _fail(String title, String detail, {bool openSettings = false}) {
    if (!mounted) return;
    setState(() {
      _state       = _GpsState.error;
      _errorTitle  = title;
      _errorDetail = detail;
    });
    if (openSettings) {
      Future.delayed(const Duration(milliseconds: 800),
          Geolocator.openLocationSettings);
    }
  }

  void _skipGps() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(AppStrings.skipGpsTitle,
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
        content: const Text(AppStrings.skipGpsBody,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel, style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _navigateToReview(GpsLocation(
                latitude:   0,
                longitude:  0,
                address:    AppStrings.gpsNotAvailable,
                capturedAt: DateTime.now(),
              ));
            },
            child: const Text(AppStrings.continueWithoutGps,
                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _navigateToReview(GpsLocation gps) {
    context.push(AppRoutes.inspectionReview, extra: {
      'qrData':          widget.qrData,
      'inspectionType':  widget.inspectionType,
      'responses':       widget.responses,
      'defects':         widget.defects,
      'additionalNotes': widget.additionalNotes ?? '',
      'gpsLocation':     gps,
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appbg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                    const Text(AppStrings.gpsVerification,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Error
                  if (_state == _GpsState.error)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.gps_off_rounded, color: AppColors.danger, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_errorTitle,
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger)),
                            ),
                          ]),
                          const SizedBox(height: 6),
                          Text(_errorDetail, style: const TextStyle(fontSize: 13, color: AppColors.danger, height: 1.4)),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _captureLocation,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text(AppStrings.tryAgain),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: const BorderSide(color: AppColors.danger),
                              ),
                            ),
                          ),
                          Center(
                            child: TextButton(
                              onPressed: _skipGps,
                              child: const Text(AppStrings.skipGpsVerification,
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Map placeholder + location card
                  if (_state == _GpsState.loading)
                    _CaptureLoader(statusText: _statusText)
                  else if (_state == _GpsState.success && _position != null) ...[
                    // Mini map placeholder (Google Maps widget would be here)
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            // Deep-green map background with grid pattern
                            Container(
                              width: double.infinity,
                              height: 220,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF2E7D5B), Color(0xFF1F5C43)],
                                ),
                              ),
                            ),
                            CustomPaint(
                              size: const Size(double.infinity, 220),
                              painter: _MapPlaceholderPainter(),
                            ),
                            // GPS ENABLED pill
                            Positioned(
                              top: 14,
                              left: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8, height: 8,
                                      decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(AppStrings.gpsEnabledLabel,
                                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ),
                            ),
                            // Pin
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.danger,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(color: AppColors.danger.withValues(alpha: 0.4), blurRadius: 12),
                                      ],
                                    ),
                                    child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 22),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location Details card
                    _LocationCard(
                      lat:        _position!.latitude,
                      lng:        _position!.longitude,
                      address:    _address,
                      capturedAt: _capturedAt,
                      accuracy:   _position!.accuracy,
                    ),
                    const SizedBox(height: 12),

                    // Refresh button
                    Center(
                      child: TextButton.icon(
                        onPressed: _captureLocation,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text(AppStrings.refreshLocation),
                        style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom: Confirm button
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
            decoration: const BoxDecoration(
              color: AppColors.appbg,
              border: Border(top: BorderSide(color: AppColors.appbg)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  AppColors.green,
                  foregroundColor: AppColors.textOnPrimary,
                  disabledBackgroundColor: AppColors.border,
                  disabledForegroundColor: AppColors.textSecondary,
                  padding: EdgeInsets.symmetric(
                      vertical: AppResponsive.padding(context, 14)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: (_state != _GpsState.success || _position == null)
                    ? null
                    : () => _navigateToReview(GpsLocation(
                          latitude:   _position!.latitude,
                          longitude:  _position!.longitude,
                          address:    _address,
                          capturedAt: _capturedAt,
                        )),
                child: _state == _GpsState.loading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(AppStrings.confirmContinue, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Support widgets ───────────────────────────────────────────────────────────

enum _GpsState { loading, error, success }

class _CaptureLoader extends StatelessWidget {
  final String statusText;
  const _CaptureLoader({required this.statusText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppColors.secondary),
          const SizedBox(height: 16),
          Text(
            statusText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          const Text(
            AppStrings.ensureGpsEnabled,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          const Text(
            AppStrings.gpsCaptureHint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final double lat;
  final double lng;
  final String address;
  final DateTime capturedAt;
  final double? accuracy;

  const _LocationCard({
    required this.lat,
    required this.lng,
    required this.address,
    required this.capturedAt,
    this.accuracy,
  });

  Color get _accuracyColor {
    final a = accuracy ?? 0;
    if (a <= 20) return AppColors.green;
    if (a <= 50) return AppColors.amber;
    return AppColors.danger;
  }

  String get _accuracyTier {
    final a = accuracy ?? 0;
    if (a <= 20) return AppStrings.accuracyHigh;
    if (a <= 50) return AppStrings.accuracyMedium;
    return AppStrings.accuracyLow;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _Row(AppStrings.labelGpsStatus, AppStrings.gpsStatusEnabled, valueColor: AppColors.green),
              _Row(AppStrings.labelLatitude,  '${lat.abs().toStringAsFixed(4)}° ${lat >= 0 ? 'N' : 'S'}'),
              _Row(AppStrings.labelLongitude, '${lng.abs().toStringAsFixed(4)}° ${lng >= 0 ? 'E' : 'W'}'),
              _Row(AppStrings.labelAddress,   address, multiLine: true),
              _Row(AppStrings.labelDate,      DateFormat('MMM d, yyyy').format(capturedAt)),
              _Row(AppStrings.labelTime,      DateFormat('hh:mm a').format(capturedAt), isLast: true),
            ],
          ),
        ),
        if (accuracy != null && accuracy! > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _accuracyColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: _accuracyColor.withValues(alpha: 0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.radar_rounded, size: 12, color: _accuracyColor),
              const SizedBox(width: 4),
              Text(AppStrings.accuracyLabel(accuracy!.round(), _accuracyTier),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _accuracyColor)),
            ]),
          ),
        ],
        if (accuracy != null && accuracy! > 50) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.amber),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(AppStrings.lowAccuracyWarning,
                    style: TextStyle(fontSize: 12, color: AppColors.amber, height: 1.4)),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.danger, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(AppStrings.gpsActiveBanner,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green, height: 1.4)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool multiLine;
  final bool isLast;
  final Color? valueColor;

  const _Row(this.label, this.value, {this.multiLine = false, this.isLast = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: multiLine
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                Expanded(
                  flex: 3,
                  child: Text(value,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.primary, height: 1.4)),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                Expanded(
                  flex: 3,
                  child: Text(value,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.primary),
                      textAlign: TextAlign.right),
                ),
              ],
            ),
    );
  }
}

class _MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8F0E0)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final linePaint = Paint()
      ..color = const Color(0xFFCDD8C4)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
