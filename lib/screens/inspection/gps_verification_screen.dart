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
  double? _lat;
  double? _lng;
  String _address = '';
  DateTime _capturedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _captureLocation();
  }

  Future<void> _captureLocation() async {
    setState(() { _isCapturing = true; _error = null; });

    try {
      // Check if location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isCapturing = false;
          _error = 'GPS is disabled on this device. Please enable GPS and try again.';
        });
        return;
      }

      // Check/request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isCapturing = false;
            _error = 'Location permission was denied. Please allow location access.';
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isCapturing = false;
          _error = 'Location permission is permanently denied. Please enable it in device settings.';
        });
        return;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // Reverse geocode
      String address = 'Location captured';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [
            p.street,
            p.locality,
            p.administrativeArea,
            p.country,
          ].where((s) => s != null && s.isNotEmpty).toList();
          address = parts.join(', ');
        }
      } catch (_) {
        address = '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      }

      setState(() {
        _lat         = position.latitude;
        _lng         = position.longitude;
        _address     = address;
        _capturedAt  = DateTime.now();
        _isCapturing = false;
      });
    } catch (e) {
      setState(() {
        _isCapturing = false;
        _error = 'Failed to capture location. Please try again.';
      });
    }
  }

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

    // Build final submission with GPS
    final finalSubmission = InspectionSubmission(
      qrCodeString:    widget.submission.qrCodeString,
      inspectionType:  widget.submission.inspectionType,
      responses:       widget.submission.responses,
      defects:         widget.submission.defects,
      additionalNotes: widget.submission.additionalNotes,
      gpsLocation:     gps,
      startedAt:       widget.submission.startedAt,
    );

    context.push(AppRoutes.inspectionReview, extra: {'submission': finalSubmission});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.gpsVerification)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Your Current Location',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'We automatically capture your current GPS location for this inspection.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 24),

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
                            const Text('GPS Error', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger)),
                          ]),
                          const SizedBox(height: 6),
                          Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.danger, height: 1.4)),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _captureLocation,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Try Again'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: const BorderSide(color: AppColors.danger),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Map placeholder + location card
                  if (_isCapturing)
                    _CaptureLoader()
                  else if (_lat != null) ...[
                    // Mini map placeholder (Google Maps widget would be here)
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Map background (grid pattern as placeholder)
                            CustomPaint(
                              size: const Size(double.infinity, 180),
                              painter: _MapPlaceholderPainter(),
                            ),
                            // Pin
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: AppColors.danger.withOpacity(0.4), blurRadius: 12),
                                    ],
                                  ),
                                  child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 22),
                                ),
                                Container(
                                  width: 2, height: 10,
                                  color: AppColors.danger,
                                ),
                              ],
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
                    ),
                    const SizedBox(height: 12),

                    // Refresh button
                    Center(
                      child: TextButton.icon(
                        onPressed: _captureLocation,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Refresh Location'),
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
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
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
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: AppColors.secondary),
          SizedBox(height: 16),
          Text(
            'Capturing your location...',
            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          SizedBox(height: 4),
          Text(
            'Please ensure GPS is enabled.',
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

  const _LocationCard({
    required this.lat,
    required this.lng,
    required this.address,
    required this.capturedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // GPS icon + Captured label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.gps_fixed_rounded, color: AppColors.secondary, size: 20),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GPS Captured', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.secondary)),
                  Text('Location verified successfully', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const Divider(height: 20),
          _Row('Latitude',  lat.toStringAsFixed(6)),
          _Row('Longitude', lng.toStringAsFixed(6)),
          _Row('Address',   address, multiLine: true),
          _Row('Date',      DateFormat('MM/dd/yyyy').format(capturedAt)),
          _Row('Time',      DateFormat('hh:mm a').format(capturedAt)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool multiLine;

  const _Row(this.label, this.value, {this.multiLine = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: multiLine
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                Expanded(
                  flex: 3,
                  child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), textAlign: TextAlign.right),
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
