import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/inspection_model.dart';
import '../../routes/app_router.dart';

class GpsVerificationScreen extends StatefulWidget {
  final InspectionSubmission submission;

  const GpsVerificationScreen({super.key, required this.submission});

  @override
  State<GpsVerificationScreen> createState() => _GpsVerificationScreenState();
}

class _GpsVerificationScreenState extends State<GpsVerificationScreen> {
  bool _isCapturing = true;
  String? _error;
  String _errorTitle = AppStrings.gpsError;
  String _statusText = AppStrings.requestingLocationPermission;
  double? _lat;
  double? _lng;
  double? _accuracy;
  String _address = '';
  DateTime _capturedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _captureLocation();
  }

  Future<void> _captureLocation() async {
    setState(() {
      _isCapturing = true;
      _error = null;
      _statusText = AppStrings.requestingLocationPermission;
    });

    try {
      // Check if location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _fail(AppStrings.gpsServicesOffTitle, AppStrings.gpsDisabled,
            openLocationSettings: true);
        return;
      }

      // Check/request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _fail(AppStrings.permissionDeniedTitle, AppStrings.locationPermissionDenied);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _fail(AppStrings.permissionDeniedForeverTitle,
            AppStrings.locationPermissionPermanentlyDenied,
            openAppSettings: true);
        return;
      }

      // Get position — tiered fallback so a slow/blocked GPS fix (common
      // indoors) doesn't dead-end the driver. LocationAccuracy.high forces
      // GPS-only and can fail entirely indoors; medium/low use network
      // positioning too, and lastKnownPosition is a last resort so the
      // driver isn't stuck if no fresh fix is available at all.
      setState(() => _statusText = AppStrings.gettingYourLocation);

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 30),
        );
      } catch (_) {
        setState(() => _statusText = AppStrings.tryingBackupLocationMethod);
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 20),
          );
        } catch (_) {
          setState(() => _statusText = AppStrings.usingLastKnownLocation);
          position = await Geolocator.getLastKnownPosition();
        }
      }

      if (position == null) {
        _fail(AppStrings.locationNotAvailableTitle, AppStrings.couldNotDetermineLocation);
        return;
      }

      // Reverse geocode
      setState(() => _statusText = AppStrings.fetchingAddress);
      String address = AppStrings.locationCapturedFallback;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 10));
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [
            p.street,
            p.subLocality,
            p.locality,
            p.administrativeArea,
            p.country,
          ].where((s) => s != null && s.isNotEmpty).toList();
          if (parts.isNotEmpty) address = parts.join(', ');
        }
      } catch (_) {
        address = '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      }

      if (!mounted) return;
      setState(() {
        _lat         = position!.latitude;
        _lng         = position.longitude;
        _accuracy    = position.accuracy;
        _address     = address;
        _capturedAt  = DateTime.now();
        _isCapturing = false;
      });
    } catch (e) {
      _fail(AppStrings.gpsError, AppStrings.locationCaptureFailed);
    }
  }

  /// Sets the error card's title/detail and stops the loading state. When
  /// [openLocationSettings] or [openAppSettings] is set, nudges the driver
  /// straight to the relevant OS settings screen after a short delay so
  /// they don't have to hunt for it themselves.
  void _fail(String title, String detail,
      {bool openLocationSettings = false, bool openAppSettings = false}) {
    if (!mounted) return;
    setState(() {
      _isCapturing = false;
      _errorTitle = title;
      _error = detail;
    });
    if (openLocationSettings) {
      Future.delayed(const Duration(milliseconds: 800), Geolocator.openLocationSettings);
    } else if (openAppSettings) {
      Future.delayed(const Duration(milliseconds: 800), Geolocator.openAppSettings);
    }
  }

  InspectionSubmission _submissionWithGps(GpsLocation gps) => InspectionSubmission(
    qrCodeString:    widget.submission.qrCodeString,
    vehicleNumber:   widget.submission.vehicleNumber,
    trailerNumber:   widget.submission.trailerNumber,
    inspectionType:  widget.submission.inspectionType,
    responses:       widget.submission.responses,
    defects:         widget.submission.defects,
    additionalNotes: widget.submission.additionalNotes,
    gpsLocation:     gps,
    startedAt:       widget.submission.startedAt,
  );

  void _confirmAndContinue() {
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.gpsRequired),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final gps = GpsLocation(
      latitude:   _lat!,
      longitude:  _lng!,
      address:    _address,
      capturedAt: _capturedAt,
    );

    context.push(AppRoutes.inspectionReview, extra: {'submission': _submissionWithGps(gps)});
  }

  /// Skip GPS — proceed without location (used only after a capture error
  /// so the driver isn't permanently blocked by a broken/unavailable GPS).
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
              final gps = GpsLocation(
                latitude: 0,
                longitude: 0,
                address: AppStrings.gpsNotAvailable,
                capturedAt: DateTime.now(),
              );
              context.push(AppRoutes.inspectionReview, extra: {'submission': _submissionWithGps(gps)});
            },
            child: const Text(AppStrings.continueWithoutGps,
                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

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
                  if (_error != null)
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
                          Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.danger, height: 1.4)),
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
                  if (_isCapturing)
                    _CaptureLoader(statusText: _statusText)
                  else if (_lat != null) ...[
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
                      lat:       _lat!,
                      lng:       _lng!,
                      address:   _address,
                      capturedAt: _capturedAt,
                      accuracy:  _accuracy,
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
                onPressed: (_isCapturing || _lat == null) ? null : _confirmAndContinue,
                child: _isCapturing
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
