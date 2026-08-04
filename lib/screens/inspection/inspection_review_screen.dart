import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/inspection_model.dart';
import '../../repositories/inspection_repository.dart';
import '../../routes/app_router.dart';

class InspectionReviewScreen extends StatefulWidget {
  final QrData                  qrData;
  final String                  inspectionType;
  final List<ChecklistResponse> responses;
  final List<DefectReport>      defects;
  final String                  additionalNotes;
  final GpsLocation             gpsLocation;

  const InspectionReviewScreen({
    super.key,
    required this.qrData,
    required this.inspectionType,
    required this.responses,
    required this.defects,
    required this.additionalNotes,
    required this.gpsLocation,
  });

  @override
  State<InspectionReviewScreen> createState() => _InspectionReviewScreenState();
}

class _InspectionReviewScreenState extends State<InspectionReviewScreen> {
  final _repo       = InspectionRepository();
  bool  _submitting = false;

  /// Build the InspectionSubmission from the screen's inputs.
  /// vehicleNumber and trailerNumber come from qrData.
  InspectionSubmission get _submission => InspectionSubmission(
    qrCodeString:        widget.qrData.qrCodeString,
    inspectionType:      widget.inspectionType,
    pendingInspectionId: widget.qrData.pendingInspectionId,
    templateId:          widget.qrData.templateId,
    responses:           widget.responses,
    defects:             widget.defects,
    additionalNotes:     widget.additionalNotes,
    gpsLocation:         widget.gpsLocation,
    startedAt:           DateTime.now(),
    vehicleNumber:       widget.qrData.vehicleNumber,
    trailerNumber:       widget.qrData.trailerNumber,
  );

  Future<void> _submit() async {
    setState(() => _submitting = true);

    final submission = _submission;
    final res = await _repo.submitInspection(submission);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res.success && res.data != null) {
      // Navigate to success screen, replacing the entire inspection stack.
      // Some submit responses only echo back {id, inspection_id, status},
      // so fill any missing display fields from what we already know.
      final result = res.data!.fillMissingFrom(submission);
      context.pushReplacement(AppRoutes.submissionSuccess, extra: result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.error ?? 'Submission failed. Please try again.'),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s         = _submission;
    final isPreTrip = s.inspectionType == 'pre_trip';

    // Separate yes_no responses (Vehicle Damage items) from regular checklist items.
    // "Yes" on a yes_no item means damage EXISTS — handled via defect reports.
    // "No" on a yes_no item means no damage — counts as passed.
    final regularResponses = s.responses.where((r) => r.response != 'yes' && r.response != 'no').toList();
    final yesNoNo          = s.responses.where((r) => r.response == 'no').length;  // "No damage" = passed
    final yesNoYes         = s.responses.where((r) => r.response == 'yes').length; // "Yes damage" = defect

    // Total = regular items + yes_no items
    final total        = s.responses.length;

    // Passed = regular items that passed + "No damage" yes_no answers
    final regularPassed = regularResponses.where((r) =>
        r.response == 'good' || r.response == 'available' || r.response == 'pass').length;
    final passed        = regularPassed + yesNoNo;

    // Defects = explicit defect reports filed (from popup dialog)
    final totalDefects  = s.defects.length;
    final vehicleLabel = s.trailerNumber != null && s.trailerNumber!.isNotEmpty
        ? '${s.vehicleNumber} / ${s.trailerNumber}'
        : s.vehicleNumber;

    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
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
                        onTap: _submitting ? null : () => context.pop(),
                        child: const Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                      const Text(AppStrings.inspectionReview,
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
                    // Truck Details
                    const _PlainSectionLabel(AppStrings.truckDetailsTitle),
                    _PlainCard(children: [
                      _PlainRow(AppStrings.labelVehicleNumber, vehicleLabel, isLast: true),
                    ]),
                    const SizedBox(height: 18),

                    // Inspection Type
                    const _PlainSectionLabel(AppStrings.labelInspectionType),
                    _PlainCard(children: [
                      _PlainRow(AppStrings.labelInspectionType,
                          isPreTrip ? AppStrings.preTrip : AppStrings.postTrip, isLast: true),
                    ]),
                    const SizedBox(height: 18),

                    // Checklist Results
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
                                // Defect count = checklist failures + explicit defect reports
                                value: '$totalDefects',
                                label: AppStrings.statDefects,
                                color: totalDefects > 0
                                    ? AppColors.danger
                                    : AppColors.textSecondary)),
                          ]),
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              AppStrings.itemsPassedCaption(passed, total),
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _ChecklistProgressBar(passed: passed, total: total),
                        ],
                      ),
                    ),

                    // Defects (if any)
                    if (s.defects.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const _PlainSectionLabel(AppStrings.defectsFoundTitle),
                      _PlainCard(children: s.defects
                          .map((d) => _DefectRow(defect: d))
                          .toList()),
                    ],

                    const SizedBox(height: 18),

                    // GPS Location
                    const _PlainSectionLabel(AppStrings.labelGpsLocation),
                    _PlainCard(children: [
                      _PlainRow(AppStrings.labelAddress, s.gpsLocation.address, multiLine: true),
                      _PlainRow(AppStrings.labelDateTime,
                          DateFormat('MMM d, yyyy hh:mm a').format(s.gpsLocation.capturedAt), isLast: true),
                    ]),

                    // Notes (if any)
                    if (s.additionalNotes != null && s.additionalNotes!.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const _PlainSectionLabel(AppStrings.additionalNotes),
                      _PlainCard(children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(s.additionalNotes!,
                              style: const TextStyle(fontSize: 13, color: AppColors.primary, height: 1.5)),
                        ),
                      ]),
                    ],

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
              decoration: const BoxDecoration(
                color: AppColors.appbg,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  // Edit button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _submitting ? null : () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.green,
                          side: const BorderSide(color: AppColors.green, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(AppStrings.editBtn, style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Submit button
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _submitting
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                                  SizedBox(width: 10),
                                  Text(AppStrings.submittingLabel),
                                ],
                              )
                            : const Text(AppStrings.submitBtn, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Review UI Widgets ────────────────────────────────────

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
  final bool multiLine;
  final bool isLast;

  const _PlainRow(this.label, this.value, {this.multiLine = false, this.isLast = false});

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
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary, height: 1.4)),
              ),
            ])
          : Row(children: [
              Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
              Expanded(
                flex: 3,
                child: Text(value, textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
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

class _ChecklistProgressBar extends StatelessWidget {
  final int passed;
  final int total;

  const _ChecklistProgressBar({required this.passed, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? passed / total : 0.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: ratio,
        minHeight: 8,
        backgroundColor: AppColors.border.withValues(alpha: 0.3),
        valueColor: AlwaysStoppedAnimation<Color>(
          ratio >= 0.8 ? AppColors.green : AppColors.amber,
        ),
      ),
    );
  }
}

class _DefectRow extends StatelessWidget {
  final DefectReport defect;
  const _DefectRow({required this.defect});

  Color get _severityColor {
    switch (defect.severity.toLowerCase()) {
      case 'critical': return AppColors.danger;
      case 'high':     return const Color(0xFFEA580C);
      case 'medium':   return AppColors.amber;
      default:         return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityLabel = defect.severity[0].toUpperCase() + defect.severity.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: _severityColor.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(Icons.circle, color: _severityColor, size: 12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1 $severityLabel', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primary)),
                const SizedBox(height: 2),
                Text('${defect.category} — $severityLabel Severity',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: _severityColor),
            ),
            child: Text(severityLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _severityColor)),
          ),
        ],
      ),
    );
  }
}
