import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_responsive.dart';
import '../../repositories/inspection_repository.dart';
import '../../routes/app_router.dart';

// ─────────────────────────────────────────────────────────────
// ZoneReviewScreen — shown after all zone QRs are scanned
// Fetches full session detail from /inspection/zone-status
// Shows driver info, vehicle info, all zones with checklist
// responses, timestamps and GPS per zone
// ─────────────────────────────────────────────────────────────
class ZoneReviewScreen extends StatefulWidget {
  final String sessionRef;
  final Map<String, dynamic>? zoneScan;
  final Map<String, dynamic>? progress;

  const ZoneReviewScreen({
    super.key,
    required this.sessionRef,
    this.zoneScan,
    this.progress,
  });

  @override
  State<ZoneReviewScreen> createState() => _ZoneReviewScreenState();
}

class _ZoneReviewScreenState extends State<ZoneReviewScreen> {
  final _repo = InspectionRepository();

  Map<String, dynamic>? _session;
  List<Map<String, dynamic>> _scannedZones = [];
  bool _loading = true;
  String _error = '';

  // Totals
  int _totalItems  = 0;
  int _passedItems = 0;
  int _defects     = 0;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final result = await _repo.getZoneStatus(sessionRef: widget.sessionRef);
    if (!mounted) return;
    if (result.success && result.data != null) {
      final data         = result.data!;
      final zones        = (data['scanned_zones'] as List? ?? [])
          .map<Map<String,dynamic>>((e) => Map<String,dynamic>.from(e as Map))
          .toList();

      // Tally checklist totals across all zones
      int total = 0, passed = 0, defects = 0;
      for (final z in zones) {
        final responses = z['responses'] as List? ?? [];
        for (final r in responses) {
          total++;
          final rv = (r['response'] as String? ?? '').toLowerCase();
          if (rv == 'defective' || rv == 'fail') { defects++; }
          else { passed++; }
        }
      }

      setState(() {
        _session      = data['session'] as Map<String, dynamic>?;
        _scannedZones = zones;
        _totalItems   = total;
        _passedItems  = passed;
        _defects      = defects;
        _loading      = false;
      });
    } else {
      setState(() {
        _error   = result.error ?? 'Could not load zone review.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appbg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Zone Inspection Review',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: const TextStyle(color: AppColors.danger)))
              : _buildContent(),
      bottomNavigationBar: _loading || _error.isNotEmpty ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.history),
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text('View History'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.dashboard),
                icon: const Icon(Icons.home_rounded, size: 18, color: Colors.white),
                label: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final comp  = _session?['completed_zones'] as int? ?? 0;
    final total = _session?['total_zones']     as int? ?? 0;
    final pct   = total > 0 ? comp / total : 0.0;
    final status= _session?['overall_status']  as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Complete banner ──────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF2E7D32)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            const Icon(Icons.verified_rounded, color: Colors.white, size: 36),
            const SizedBox(height: 8),
            const Text('Walk-Around Complete!',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('All zones inspected — $comp/$total zones',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // ── Checklist summary ────────────────────────────────
        _sectionTitle('Checklist Results'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDeco(),
          child: Column(children: [
            Row(children: [
              _statBox('$_totalItems',  'Total',    AppColors.primary),
              _statBox('$_passedItems', 'Passed',   AppColors.secondary),
              _statBox('$_defects',     'Defects',  _defects > 0 ? AppColors.danger : AppColors.textSecondary),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: _totalItems > 0 ? _passedItems / _totalItems : 0,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(
                    _defects > 0 ? AppColors.danger : AppColors.secondary),
              ),
            ),
            const SizedBox(height: 6),
            Text('$_passedItems / $_totalItems items passed',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),

        const SizedBox(height: 16),

        // ── Zone details ─────────────────────────────────────
        _sectionTitle('Zone-by-Zone Details'),
        ..._scannedZones.map((zone) => _buildZoneCard(zone)),

        const SizedBox(height: 80),
      ]),
    );
  }

  Widget _buildZoneCard(Map<String, dynamic> zone) {
    final responses = zone['responses'] as List? ?? [];
    final zoneDefects = responses.where((r) {
      final rv = (r['response'] as String? ?? '').toLowerCase();
      return rv == 'defective' || rv == 'fail';
    }).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Zone header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            border: const Border(bottom: BorderSide(color: Color(0xFFE2ECF4))),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(children: [
            const Icon(Icons.location_on_rounded, color: AppColors.secondary, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(zone['zone_name'] as String? ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w800,
                      color: AppColors.primary, fontSize: 13)),
            ),
            if (zoneDefects > 0)
              _chip('$zoneDefects Defect${zoneDefects>1?'s':''}', AppColors.danger)
            else
              _chip('All Good', AppColors.secondary),
          ]),
        ),

        // Timestamp + GPS
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(children: [
            const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(zone['scanned_at'] as String? ?? '—',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            if (zone['gps_address'] != null) ...[
              const SizedBox(width: 10),
              const Icon(Icons.gps_fixed_rounded, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(zone['gps_address'] as String? ?? '',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ]),
        ),

        // Checklist responses
        if (responses.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Column(
              children: responses.map<Widget>((r) {
                final label = r['item_label'] as String? ?? '';
                final resp  = (r['response'] as String? ?? '').toLowerCase();
                final bad   = resp == 'defective' || resp == 'fail';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    Expanded(child: Text(label,
                        style: const TextStyle(fontSize: 12, color: AppColors.primary))),
                    _chip(resp.toUpperCase(), bad ? AppColors.danger : AppColors.secondary),
                  ]),
                );
              }).toList(),
            ),
          ),
      ]),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
        color: AppColors.primary)),
  );

  Widget _statBox(String val, String label, Color color) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: [
        Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    ),
  );

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
  );

  BoxDecoration _cardDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
        blurRadius: 8, offset: const Offset(0, 2))],
  );
}
