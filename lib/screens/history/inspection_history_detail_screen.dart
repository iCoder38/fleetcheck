import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../repositories/inspection_repository.dart';

class InspectionHistoryDetailScreen extends StatefulWidget {
  final int inspectionId;
  const InspectionHistoryDetailScreen({super.key, required this.inspectionId});

  @override
  State<InspectionHistoryDetailScreen> createState() => _InspectionHistoryDetailScreenState();
}

class _InspectionHistoryDetailScreenState extends State<InspectionHistoryDetailScreen> {
  final _repo = InspectionRepository();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    final result = await _repo.getInspectionDetail(widget.inspectionId);
    if (!mounted) return;
    if (result.success) {
      setState(() { _detail = result.data; _isLoading = false; });
    } else {
      setState(() { _error = result.error; _isLoading = false; });
    }
  }

  Future<void> _downloadPdf() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating PDF...'), backgroundColor: AppColors.secondary),
    );
  }

  Future<void> _shareReport() async {
    final d = _detail;
    if (d == null) return;
    await Share.share(
      'FleetCheck Inspection Report\nID: ${d['inspection_id']}\nVehicle: ${d['vehicle_number']}\n${_repo.getReportUrl(widget.inspectionId)}',
      subject: 'FleetCheck Inspection Report',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_detail != null ? _detail!['inspection_id'] ?? 'Detail' : 'Inspection Detail'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _detail == null
                  ? const Center(child: Text('Inspection not found.'))
                  : _buildDetail(),
    );
  }

  Widget _buildDetail() {
    final d         = _detail!;
    final isPreTrip = (d['inspection_type'] ?? '') == 'pre_trip';
    final responses = (d['responses'] as List<dynamic>?) ?? [];
    final defects   = (d['defects']   as List<dynamic>?) ?? [];
    final gps       = d['gps_location'] as Map<String, dynamic>?;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary card
                _Section(
                  icon:  Icons.info_outline_rounded,
                  title: 'Inspection Summary',
                  color: AppColors.primary,
                  children: [
                    _Row('Inspection ID',   d['inspection_id'] ?? '—'),
                    _Row('Driver Name',     d['driver_name']   ?? '—'),
                    _Row('Vehicle Number',  d['vehicle_number'] ?? '—'),
                    _Row('VIN',             d['vin'] ?? '—'),
                    _Row('Fleet Number',    d['fleet_number'] ?? '—'),
                    _Row('Company',         d['company_name'] ?? '—'),
                    _Row('Type', isPreTrip ? 'Pre-Trip Inspection' : 'Post-Trip Inspection',
                        valueColor: isPreTrip ? AppColors.secondary : AppColors.primary),
                    _Row('Status', _capitalize(d['status'] ?? ''),
                        valueColor: _statusColor(d['status'] ?? '')),
                    _Row('Date & Time',
                        d['submitted_at'] != null
                            ? DateFormat('MM/dd/yyyy hh:mm a').format(DateTime.parse(d['submitted_at'] as String))
                            : '—'),
                  ],
                ),

                // GPS Location
                if (gps != null) ...[
                  const SizedBox(height: 14),
                  _Section(
                    icon:  Icons.location_on_rounded,
                    title: 'GPS Location',
                    color: AppColors.danger,
                    children: [
                      _Row('Address',    gps['address'] ?? '—', multiLine: true),
                      _Row('Latitude',   (gps['latitude'] as num?)?.toStringAsFixed(6) ?? '—'),
                      _Row('Longitude',  (gps['longitude'] as num?)?.toStringAsFixed(6) ?? '—'),
                    ],
                  ),
                ],

                // Checklist Answers
                if (responses.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _Section(
                    icon:  Icons.checklist_rounded,
                    title: 'Checklist Answers (${responses.length})',
                    color: AppColors.secondary,
                    children: responses.map((r) {
                      final res  = r as Map<String, dynamic>;
                      final resp = res['selected_option'] as String? ?? '—';
                      final isOk = resp == 'Good' || resp == 'Available' || resp == 'No';
                      return _ChecklistRow(
                        item:     res['item_label'] as String? ?? '',
                        response: resp,
                        isOk:     isOk,
                      );
                    }).toList(),
                  ),
                ],

                // Defects
                if (defects.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _Section(
                    icon:  Icons.warning_amber_rounded,
                    title: 'Defects Reported (${defects.length})',
                    color: AppColors.danger,
                    children: defects.map((def) {
                      final d   = def as Map<String, dynamic>;
                      final sev = d['severity'] as String? ?? '';
                      return _DefectItem(
                        category:    d['category'] as String? ?? '',
                        severity:    sev,
                        description: d['description'] as String? ?? '',
                      );
                    }).toList(),
                  ),
                ],

                // Additional notes
                if ((d['additional_notes'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 14),
                  _Section(
                    icon:  Icons.notes_rounded,
                    title: 'Additional Notes',
                    color: AppColors.amber,
                    children: [
                      Text(d['additional_notes'] as String, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5)),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // Action buttons
        Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
          decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _downloadPdf,
                    icon:  const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text('Download PDF', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _shareReport,
                    icon:  const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Share', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _statusColor(String s) => switch (s) {
    'completed'    => AppColors.secondary,
    'pending'      => AppColors.amber,
    'rejected'     => AppColors.danger,
    _              => AppColors.primary,
  };

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).replaceAll('_', ' ')}';
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<Widget> children;

  const _Section({required this.icon, required this.title, required this.color, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
            ]),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool multiLine;
  const _Row(this.label, this.value, {this.valueColor, this.multiLine = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: multiLine
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textPrimary, height: 1.4)),
            ])
          : Row(children: [
              Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
              Expanded(flex: 3, child: Text(value, textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.textPrimary))),
            ]),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final String item, response;
  final bool isOk;
  const _ChecklistRow({required this.item, required this.response, required this.isOk});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isOk ? AppColors.secondary.withOpacity(0.05) : AppColors.danger.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (isOk ? AppColors.secondary : AppColors.danger).withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(isOk ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isOk ? AppColors.secondary : AppColors.danger, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(item, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        Text(response, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isOk ? AppColors.secondary : AppColors.danger)),
      ]),
    );
  }
}

class _DefectItem extends StatelessWidget {
  final String category, severity, description;
  const _DefectItem({required this.category, required this.severity, required this.description});

  Color get _color => switch (severity.toLowerCase()) {
    'critical' => AppColors.danger,
    'high'     => const Color(0xFFEA580C),
    'medium'   => AppColors.amber,
    _          => AppColors.secondary,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.warning_amber_rounded, color: _color, size: 16),
          const SizedBox(width: 6),
          Text(category, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: _color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(severity, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _color))),
        ]),
        const SizedBox(height: 4),
        Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
      ]),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textSecondary),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
      const SizedBox(height: 16),
      ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Retry')),
    ])),
  );
}
