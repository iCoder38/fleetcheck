import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_responsive.dart';
import '../repositories/inspection_repository.dart';
import '../routes/app_router.dart';

// ─────────────────────────────────────────────────────────────
// ZoneWalkAroundScreen
// Shown after driver scans a Zone QR code.
// Shows zone name, checklist for that zone, and overall
// walk-around progress (completed zones vs total).
// ─────────────────────────────────────────────────────────────
class ZoneWalkAroundScreen extends StatefulWidget {
  final String qrCode;
  final Map<String, dynamic> qrData;

  const ZoneWalkAroundScreen({
    super.key,
    required this.qrCode,
    required this.qrData,
  });

  @override
  State<ZoneWalkAroundScreen> createState() => _ZoneWalkAroundScreenState();
}

class _ZoneWalkAroundScreenState extends State<ZoneWalkAroundScreen> {
  final _repo = InspectionRepository();

  // Zone scan data from API
  Map<String, dynamic>? _zoneScan;
  Map<String, dynamic>? _progress;
  List<Map<String, dynamic>> _checklistItems = [];

  // session_ref persists across all zone scans for the same walk-around.
  // Passed in via widget.qrData if coming from a previous zone scan.
  String _sessionRef = '';

  // Checklist responses for this zone
  final Map<int, String> _responses = {};

  bool _loading  = true;
  bool _saving   = false;
  String _error  = '';

  // GPS for this zone scan
  double? _gpsLat;
  double? _gpsLng;
  String  _gpsAddress = '';

  @override
  void initState() {
    super.initState();
    // Restore session_ref from previous zone scan if available
    _sessionRef = widget.qrData['session_ref'] as String? ?? '';
    _fetchGpsAndLoad();
  }

  // ── Call zone-scan API ────────────────────────────────────
  Future<void> _fetchGpsAndLoad() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm != LocationPermission.deniedForever) {
          final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high)
              .timeout(const Duration(seconds: 8), onTimeout: () =>
                  Position(latitude: 0, longitude: 0, timestamp: DateTime.now(),
                      accuracy: 0, altitude: 0, heading: 0, speed: 0,
                      speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0));
          if (pos.latitude != 0) {
            _gpsLat = pos.latitude;
            _gpsLng = pos.longitude;
          }
        }
      }
    } catch (_) {}
    _loadZoneScan();
  }

  Future<void> _loadZoneScan() async {
    setState(() { _loading = true; _error = ''; });
    final result = await _repo.zoneScan(
      qrCode:         widget.qrCode,
      sessionRef:     _sessionRef,
      inspectionType: 'pre_trip',
      gpsLat:         _gpsLat,
      gpsLng:         _gpsLng,
      gpsAddress:     _gpsAddress,
    );
    if (!mounted) return;
    if (result.success && result.data != null) {
      final data = result.data!;
      setState(() {
        _zoneScan   = data['zone_scan'] as Map<String, dynamic>?;
        _progress   = data['progress']  as Map<String, dynamic>?;
        _sessionRef = (_zoneScan?['session_ref'] as String?) ?? _sessionRef;
        final items = data['checklist']?['items'] as List? ?? [];
        _checklistItems = items.map<Map<String,dynamic>>(
            (e) => Map<String,dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } else {
      setState(() {
        _error   = result.error ?? 'Zone scan failed.';
        _loading = false;
      });
    }
  }

  // ── Submit zone checklist responses ──────────────────────
  Future<void> _submitZone() async {
    // Validate all items answered
    if (_responses.length < _checklistItems.length) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please answer all checklist items before submitting.'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    setState(() => _saving = true);
    final responsesList = _responses.entries.map((e) => {
      'item_index': e.key,
      'item_label': _checklistItems[e.key]['label'],
      'response':   e.value,
    }).toList();

    final result = await _repo.submitZone(
      zoneScanId:  _zoneScan?['zone_scan_id'],
      sessionRef:  _sessionRef,
      responses:   responsesList,
    );

    if (!mounted) return;

    try {
      if (result.success && result.data != null) {
        final allComplete = result.data!['all_complete'] == true;
        if (allComplete) {
          // All zones done — show completion screen
          _showAllCompleteDialog();
        } else {
          // Go back to scanner for next zone
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              'Zone "${_zoneScan?['zone_name']}" complete! '
              'Scan the next zone QR code.',
            ),
            backgroundColor: AppColors.secondary,
          ));
          // Pass session_ref back so next zone continues same walk-around session
          context.pop({'session_ref': _sessionRef});
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.error ?? 'Submit failed.'),
          backgroundColor: AppColors.danger,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppColors.danger,
      ));
    }
    setState(() => _saving = false);
  }

  // ── All zones complete → navigate to Zone Review Screen ──────
  void _showAllCompleteDialog() {
    context.push(AppRoutes.zoneReview, extra: {
      'session_ref': _sessionRef,
      'zone_scan':   _zoneScan,
      'progress':    _progress,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appbg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _zoneScan?['zone_name'] ?? 'Zone Inspection',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [
          if (_progress != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_progress!['completed_zones']}/${_progress!['total_zones']} zones',
                    style: const TextStyle(color: Colors.white, fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
          : _error.isNotEmpty
              ? _buildError()
              : _buildContent(),
      bottomNavigationBar: _loading || _error.isNotEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _saving ? null : _submitZone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Submit Zone & Continue',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                              color: Colors.white)),
                ),
              ),
            ),
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
          const SizedBox(height: 12),
          Text(_error, textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadZoneScan,
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );

  Widget _buildContent() {
    final comp  = _progress?['completed_zones'] as int? ?? 0;
    final total = _progress?['total_zones']     as int? ?? 0;
    final pct   = total > 0 ? comp / total : 0.0;
    final remaining = (_progress?['remaining_zones'] as List?)?.cast<Map<String,dynamic>>() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Progress card ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                  blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Walk-Around Progress',
                        style: TextStyle(fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            fontSize: AppResponsive.text(context, 14))),
                    Text('$comp / $total',
                        style: TextStyle(fontWeight: FontWeight.w800,
                            color: AppColors.secondary,
                            fontSize: AppResponsive.text(context, 14))),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                  ),
                ),
                const SizedBox(height: 6),
                Text('${(pct * 100).round()}% complete',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Zone info ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF2E7D32)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_zoneScan?['zone_name'] ?? '',
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w800, fontSize: 15)),
                      if (_zoneScan?['zone_group'] != null)
                        Text(_zoneScan!['zone_group'],
                            style: TextStyle(color: Colors.white.withOpacity(0.7),
                                fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (_zoneScan?['zone_type'] as String? ?? 'truck').toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Checklist items ──────────────────────────────
          if (_checklistItems.isNotEmpty) ...[
            Text('Inspection Checklist',
                style: TextStyle(fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: AppResponsive.text(context, 14))),
            const SizedBox(height: 10),
            ..._checklistItems.asMap().entries.map((entry) {
              final idx  = entry.key;
              final item = entry.value;
              final resp = _responses[idx];
              return _buildChecklistItem(idx, item, resp);
            }),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('No checklist items for this zone.',
                  style: TextStyle(color: Colors.grey)),
            ),
          ],

          const SizedBox(height: 16),

          // ── Remaining zones ──────────────────────────────
          if (remaining.isNotEmpty) ...[
            Text('Remaining Zones (${remaining.length})',
                style: TextStyle(fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: AppResponsive.text(context, 13))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 6,
              children: remaining.map((z) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(z['zone_name'] ?? '',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              )).toList(),
            ),
          ],

          const SizedBox(height: 80), // bottom button space
        ],
      ),
    );
  }

  Widget _buildChecklistItem(int idx, Map<String, dynamic> item, String? response) {
    final label   = item['label'] as String? ?? '';
    final options = (item['options'] as List?)?.cast<String>() ?? ['Good', 'Defective'];
    final answered = response != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: answered
              ? (response == 'Good' || response == 'Available' || response == 'Pass'
                  ? AppColors.secondary
                  : AppColors.danger)
              : Colors.grey.shade200,
          width: answered ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w700,
                        color: AppColors.primary, fontSize: 13)),
              ),
              if (answered)
                Icon(
                  response == 'Good' || response == 'Available' || response == 'Pass'
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: response == 'Good' || response == 'Available' || response == 'Pass'
                      ? AppColors.secondary
                      : AppColors.danger,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: options.map((opt) {
              final isSelected = response == opt;
              final isGood     = opt == 'Good' || opt == 'Available' || opt == 'Pass';
              final col        = isGood ? AppColors.secondary : AppColors.danger;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => setState(() => _responses[idx] = opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? col.withOpacity(0.12) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? col : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(opt,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected ? col : Colors.black54,
                          )),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
