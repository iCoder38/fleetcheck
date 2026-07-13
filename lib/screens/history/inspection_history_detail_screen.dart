import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../blocs/history/inspection_history_detail/inspection_history_detail_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/api_constants.dart';

class InspectionHistoryDetailScreen extends StatefulWidget {
  final int inspectionId;
  const InspectionHistoryDetailScreen({super.key, required this.inspectionId});

  @override
  State<InspectionHistoryDetailScreen> createState() => _InspectionHistoryDetailScreenState();
}

class _InspectionHistoryDetailScreenState extends State<InspectionHistoryDetailScreen> {
  void _load() {
    context
        .read<InspectionHistoryDetailBloc>()
        .add(DetailRequested(widget.inspectionId));
  }

  Future<void> _downloadPdf() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.generatingPdf), backgroundColor: AppColors.secondary),
    );
  }

  Future<void> _shareReport(Map<String, dynamic> d) async {
    final reportUrl =
        '${ApiConstants.baseUrl}${ApiConstants.downloadReport(widget.inspectionId)}';
    await Share.share(
      'FleetCheck Inspection Report\nID: ${d['inspection_id']}\nVehicle: ${d['vehicle_number']}\n$reportUrl',
      subject: 'FleetCheck Inspection Report',
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InspectionHistoryDetailBloc, InspectionHistoryDetailState>(
      builder: (context, state) {
        final title = state is InspectionHistoryDetailLoaded
            ? state.detail['inspection_id'] ?? AppStrings.detailFallback
            : AppStrings.inspectionDetailAppBarTitle;
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
                        Expanded(
                          child: Text(title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: switch (state) {
                  InspectionHistoryDetailLoading() =>
                    const Center(child: CircularProgressIndicator(color: AppColors.secondary)),
                  InspectionHistoryDetailFailure() =>
                    _ErrorView(message: state.message, onRetry: _load),
                  InspectionHistoryDetailLoaded() => _buildDetail(state.detail),
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetail(Map<String, dynamic> d) {
    final isPreTrip = (d['inspection_type'] ?? '') == 'pre_trip';
    final responses = (d['responses'] as List<dynamic>?) ?? [];
    final defects   = (d['defects']   as List<dynamic>?) ?? [];
    final gps       = d['gps_location'] as Map<String, dynamic>?;

    final total  = responses.length;
    final passed = responses.where((r) {
      final resp = (r as Map<String, dynamic>)['selected_option'] as String?;
      return resp == 'Good' || resp == 'Available' || resp == 'No';
    }).length;
    final defectCount = total - passed;

    final vehicleLabel = (d['trailer_number'] as String?)?.isNotEmpty == true
        ? '${d['vehicle_number'] ?? '—'} / ${d['trailer_number']}'
        : (d['vehicle_number'] ?? '—').toString();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Truck Details
                const _PlainSectionLabel(AppStrings.truckDetailsTitle),
                _PlainCard(children: [
                  _PlainRow(AppStrings.labelVehicleNumber, vehicleLabel),
                  _PlainRow(AppStrings.labelDriverName, (d['driver_name'] ?? '—').toString()),
                  _PlainRow(AppStrings.labelVin, (d['vin'] ?? '—').toString()),
                  _PlainRow(AppStrings.labelFleetNumber, (d['fleet_number'] ?? '—').toString()),
                  _PlainRow(AppStrings.labelCompany, (d['company_name'] ?? '—').toString(), isLast: true),
                ]),
                const SizedBox(height: 18),

                // Inspection Type / Status
                const _PlainSectionLabel(AppStrings.labelInspectionType),
                _PlainCard(children: [
                  _PlainRow(AppStrings.labelType, isPreTrip ? AppStrings.preTrip : AppStrings.postTrip),
                  _PlainRow(AppStrings.labelStatus, _capitalize((d['status'] ?? '').toString()),
                      valueColor: _statusColor((d['status'] ?? '').toString())),
                  _PlainRow(AppStrings.labelDateTime,
                      d['submitted_at'] != null
                          ? DateFormat('MMM d, yyyy hh:mm a').format(DateTime.parse(d['submitted_at'] as String))
                          : '—',
                      isLast: true),
                ]),
                const SizedBox(height: 18),

                // Checklist Results
                if (total > 0) ...[
                  const _PlainSectionLabel(AppStrings.checklistResultsTitle),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(children: [
                          Expanded(child: _StatBox(value: '$total', label: AppStrings.statTotal, color: AppColors.info)),
                          const SizedBox(width: 10),
                          Expanded(child: _StatBox(value: '$passed', label: AppStrings.statPassed, color: AppColors.green)),
                          const SizedBox(width: 10),
                          Expanded(child: _StatBox(
                              value: '$defectCount',
                              label: AppStrings.statDefects,
                              color: defectCount > 0 ? AppColors.danger : AppColors.textSecondary)),
                        ]),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(AppStrings.itemsPassedCaption(passed, total),
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: total > 0 ? passed / total : 0,
                            minHeight: 8,
                            backgroundColor: AppColors.border.withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                passed / total >= 0.8 ? AppColors.green : AppColors.amber),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Checklist Answers (itemized)
                  _PlainSectionLabel(AppStrings.checklistAnswersTitle(total)),
                  _PlainCard(children: responses.asMap().entries.map((e) {
                    final res  = e.value as Map<String, dynamic>;
                    final resp = res['selected_option'] as String? ?? '—';
                    final isOk = resp == 'Good' || resp == 'Available' || resp == 'No';
                    return _ChecklistRow(
                      item:     res['item_label'] as String? ?? '',
                      response: resp,
                      isOk:     isOk,
                      isLast:   e.key == responses.length - 1,
                    );
                  }).toList()),
                  const SizedBox(height: 18),
                ],

                // Defects
                if (defects.isNotEmpty) ...[
                  const _PlainSectionLabel(AppStrings.defectsFoundTitle),
                  _PlainCard(children: defects.map((def) {
                    final dd  = def as Map<String, dynamic>;
                    return _DefectRow(
                      category:    dd['category'] as String? ?? '',
                      severity:    dd['severity'] as String? ?? '',
                      description: dd['description'] as String? ?? '',
                    );
                  }).toList()),
                  const SizedBox(height: 18),
                ],

                // GPS Location
                if (gps != null) ...[
                  const _PlainSectionLabel(AppStrings.labelGpsLocation),
                  _PlainCard(children: [
                    _PlainRow(AppStrings.labelAddress, (gps['address'] ?? '—').toString(), multiLine: true),
                    _PlainRow(AppStrings.labelCoordinates,
                        '${(gps['latitude'] as num?)?.toStringAsFixed(5) ?? '—'}, '
                        '${(gps['longitude'] as num?)?.toStringAsFixed(5) ?? '—'}',
                        isLast: true),
                  ]),
                  const SizedBox(height: 18),
                ],

                // Additional notes
                if ((d['additional_notes'] as String?)?.isNotEmpty == true) ...[
                  const _PlainSectionLabel(AppStrings.additionalNotes),
                  _PlainCard(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(d['additional_notes'] as String,
                          style: const TextStyle(fontSize: 13, color: AppColors.primary, height: 1.5)),
                    ),
                  ]),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // Action buttons
        Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _downloadPdf,
                    icon:  const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text(AppStrings.downloadPdf, style: TextStyle(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.green,
                        side: const BorderSide(color: AppColors.green, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _shareReport(d),
                    icon:  const Icon(Icons.share_outlined, size: 18),
                    label: const Text(AppStrings.shareLabel, style: TextStyle(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
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

class _PlainSectionLabel extends StatelessWidget {
  final String label;
  const _PlainSectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.6)),
  );
}

class _PlainCard extends StatelessWidget {
  final List<Widget> children;
  const _PlainCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
      ],
    ),
    child: Column(children: children),
  );
}

class _PlainRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool multiLine;
  final bool isLast;

  const _PlainRow(this.label, this.value, {this.valueColor, this.multiLine = false, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: multiLine
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
              Expanded(
                flex: 3,
                child: Text(value, textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.primary, height: 1.4)),
              ),
            ])
          : Row(children: [
              Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
              Expanded(
                flex: 3,
                child: Text(value, textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.primary)),
              ),
            ]),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatBox({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.appbg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    ),
  );
}

class _ChecklistRow extends StatelessWidget {
  final String item, response;
  final bool isOk;
  final bool isLast;
  const _ChecklistRow({required this.item, required this.response, required this.isOk, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(children: [
        Icon(isOk ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isOk ? AppColors.green : AppColors.danger, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(item, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary))),
        Text(response, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isOk ? AppColors.green : AppColors.danger)),
      ]),
    );
  }
}

class _DefectRow extends StatelessWidget {
  final String category, severity, description;
  const _DefectRow({required this.category, required this.severity, required this.description});

  Color get _color => switch (severity.toLowerCase()) {
    'critical' => AppColors.danger,
    'high'     => const Color(0xFFEA580C),
    'medium'   => AppColors.amber,
    _          => AppColors.green,
  };

  @override
  Widget build(BuildContext context) {
    final severityLabel = severity.isEmpty ? '' : '${severity[0].toUpperCase()}${severity.substring(1)}';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: _color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(Icons.circle, color: _color, size: 12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primary)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: _color)),
            child: Text(severityLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _color)),
          ),
        ],
      ),
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
      ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text(AppStrings.retryLabel)),
    ])),
  );
}
