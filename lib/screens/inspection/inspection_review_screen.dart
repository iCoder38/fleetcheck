import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/inspection_model.dart';
import '../../repositories/inspection_repository.dart';
import '../../routes/app_router.dart';

class InspectionReviewScreen extends StatefulWidget {
  final InspectionSubmission submission;
  const InspectionReviewScreen({super.key, required this.submission});

  @override
  State<InspectionReviewScreen> createState() => _InspectionReviewScreenState();
}

class _InspectionReviewScreenState extends State<InspectionReviewScreen> {
  bool _isSubmitting = false;
  final _repo = InspectionRepository();

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final result = await _repo.submitInspection(widget.submission);

    if (!mounted) return;

    if (result.success && result.data != null) {
      // Navigate to success — replace so driver cannot go back
      context.go(AppRoutes.submissionSuccess, extra: result.data!);
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Submission failed. Please try again.'),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s           = widget.submission;
    final isPreTrip   = s.inspectionType == 'pre_trip';
    final total       = s.totalItems;
    final passed      = s.passedItems;
    final defectCount = s.defectCount;

    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text(AppStrings.inspectionReview)),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Page subtitle
                    const Text(
                      'Review your inspection before submitting. Once submitted you cannot edit it.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 20),

                    // Vehicle & Type
                    _ReviewCard(
                      icon: Icons.local_shipping_rounded,
                      title: 'Vehicle & Inspection',
                      color: AppColors.primary,
                      children: [
                        _ReviewRow('Vehicle Number', s.qrCodeString.contains('FC-') ? s.qrCodeString.split('-').take(3).join('-') : s.qrCodeString),
                        _ReviewRow('Inspection Type', isPreTrip ? AppStrings.preTrip : AppStrings.postTrip),
                        _ReviewRow('Started At', DateFormat('MM/dd/yyyy hh:mm a').format(s.startedAt)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Checklist Results
                    _ReviewCard(
                      icon: Icons.checklist_rounded,
                      title: 'Checklist Results',
                      color: AppColors.secondary,
                      children: [
                        _ReviewRow('Total Items Checked', '$total'),
                        _ReviewRow('Items Passed', '$passed',
                            valueColor: AppColors.secondary),
                        _ReviewRow('Defects / Issues', '$defectCount',
                            valueColor: defectCount > 0 ? AppColors.danger : AppColors.secondary),
                        // Progress bar
                        const SizedBox(height: 4),
                        _ChecklistProgressBar(passed: passed, total: total),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // GPS Location
                    _ReviewCard(
                      icon: Icons.location_on_rounded,
                      title: 'GPS Location',
                      color: AppColors.danger,
                      children: [
                        _ReviewRow('Address', s.gpsLocation.address, multiLine: true),
                        _ReviewRow('Coordinates',
                            '${s.gpsLocation.latitude.toStringAsFixed(5)}, ${s.gpsLocation.longitude.toStringAsFixed(5)}'),
                        _ReviewRow('Captured At', DateFormat('MM/dd/yyyy hh:mm a').format(s.gpsLocation.capturedAt)),
                      ],
                    ),

                    // Notes (if any)
                    if (s.additionalNotes != null && s.additionalNotes!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _ReviewCard(
                        icon: Icons.notes_rounded,
                        title: 'Additional Notes',
                        color: AppColors.amber,
                        children: [
                          Text(
                            s.additionalNotes!,
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5),
                          ),
                        ],
                      ),
                    ],

                    // Defects (if any)
                    if (s.defects.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _ReviewCard(
                        icon: Icons.warning_amber_rounded,
                        title: 'Reported Defects (${s.defects.length})',
                        color: AppColors.danger,
                        children: s.defects.map((d) => _DefectChip(defect: d)).toList(),
                      ),
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
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  // Edit button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : () => context.pop(),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text(AppStrings.editBtn, style: TextStyle(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
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
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                                  SizedBox(width: 10),
                                  Text('Submitting...'),
                                ],
                              )
                            : const Text(AppStrings.submitBtn, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

class _ReviewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<Widget> children;

  const _ReviewCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 17),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool multiLine;

  const _ReviewRow(this.label, this.value, {this.valueColor, this.multiLine = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: multiLine
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 3),
              Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textPrimary, height: 1.4)),
            ])
          : Row(children: [
              Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
              Expanded(
                flex: 3,
                child: Text(value, textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.textPrimary)),
              ),
            ]),
    );
  }
}

class _ChecklistProgressBar extends StatelessWidget {
  final int passed;
  final int total;

  const _ChecklistProgressBar({required this.passed, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? passed / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              ratio >= 0.8 ? AppColors.secondary : AppColors.amber,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(ratio * 100).toInt()}% passed',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _DefectChip extends StatelessWidget {
  final DefectReport defect;
  const _DefectChip({required this.defect});

  Color get _severityColor {
    switch (defect.severity.toLowerCase()) {
      case 'critical': return AppColors.danger;
      case 'high':     return const Color(0xFFEA580C);
      case 'medium':   return AppColors.amber;
      default:         return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _severityColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _severityColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: _severityColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(defect.category, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(defect.description, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _severityColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              defect.severity,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _severityColor),
            ),
          ),
        ],
      ),
    );
  }
}
