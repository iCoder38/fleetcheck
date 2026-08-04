import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/pdf_report_service.dart';
import '../../core/services/storage_service.dart';
import '../../models/inspection_model.dart';
import '../../repositories/inspection_repository.dart';
import '../../routes/app_router.dart';

/// Thrown when the full inspection detail can't be fetched from the API —
/// carries the server/network error message so it can be shown as-is
/// instead of a generic "PDF failed" string.
class _ReportDataException implements Exception {
  final String message;
  _ReportDataException(this.message);
}

class SubmissionSuccessScreen extends StatefulWidget {
  final InspectionResult result;
  const SubmissionSuccessScreen({super.key, required this.result});

  @override
  State<SubmissionSuccessScreen> createState() => _SubmissionSuccessScreenState();
}

class _SubmissionSuccessScreenState extends State<SubmissionSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _aniController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  bool _isDownloading = false;
  bool _isSharing     = false;

  Uint8List? _cachedPdfBytes;

  @override
  void initState() {
    super.initState();
    _aniController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(parent: _aniController, curve: Curves.elasticOut);
    _fadeAnim  = CurvedAnimation(parent: _aniController, curve: Curves.easeIn);
    _aniController.forward();
  }

  @override
  void dispose() {
    _aniController.dispose();
    super.dispose();
  }

  String get _reportFileName {
    final safeId = widget.result.inspectionId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return 'FleetCheck_$safeId.pdf';
  }

  /// Fetches the full inspection detail (checklist responses, defects,
  /// driver/vehicle info) and renders the PDF, caching the bytes so a
  /// second tap (e.g. Download then Share) doesn't re-fetch from the API.
  Future<Uint8List> _buildPdfBytes() async {
    final cached = _cachedPdfBytes;
    if (cached != null) return cached;

    final repo = context.read<InspectionRepository>();
    final detailResult = await repo.getInspectionDetail(widget.result.id);
    final detail = detailResult.data;
    if (!detailResult.success || detail == null) {
      throw _ReportDataException(detailResult.error ?? AppStrings.pdfFailed);
    }

    final driverData = StorageService().getDriverData();
    final bytes = await PdfReportService()
        .generateInspectionReport(detail, driverData: driverData);
    _cachedPdfBytes = bytes;
    return bytes;
  }

  Future<Directory> _reportsDirectory() async {
    // App-scoped storage on both platforms — no runtime storage permission
    // needed on Android (app-specific external dir) or iOS (Documents dir).
    final base = Platform.isAndroid
        ? (await getExternalStorageDirectory()) ?? await getApplicationDocumentsDirectory()
        : await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/YCheckPro Reports');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _downloadPdf() async {
    setState(() => _isDownloading = true);
    try {
      final bytes = await _buildPdfBytes();
      final dir = await _reportsDirectory();
      final file = File('${dir.path}/$_reportFileName');
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.reportDownloadedSuccess),
          backgroundColor: AppColors.secondary,
          action: SnackBarAction(
            label: 'OPEN',
            textColor: Colors.white,
            onPressed: () => Printing.layoutPdf(
              onLayout: (_) async => bytes,
              name: _reportFileName,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is _ReportDataException ? e.message : AppStrings.pdfFailed),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _shareReport() async {
    setState(() => _isSharing = true);
    try {
      final bytes = await _buildPdfBytes();
      await Printing.sharePdf(
        bytes: bytes,
        filename: _reportFileName,
        subject: 'Y-CheckPro Inspection Report – ${widget.result.inspectionId}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is _ReportDataException ? e.message : AppStrings.shareFailed),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r         = widget.result;
    final isPreTrip = r.inspectionType == 'pre_trip';

    // Block back navigation — submission is final
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.appbg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ✅ Animated success icon
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.greenGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.35),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 56),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      const Text(
                        AppStrings.submissionSuccess,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.secondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        AppStrings.submissionSubtitle,
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Details card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Inspection ID
                      _DetailItem(
                        icon: Icons.confirmation_number_outlined,
                        label: AppStrings.labelInspectionId,
                        value: r.inspectionId,
                        multiLine: true,
                      ),
                      const Divider(height: 20),
                      _DetailItem(
                        icon: Icons.local_shipping_outlined,
                        label: AppStrings.labelVehicleNumber,
                        value: r.vehicleNumber,
                      ),
                      const Divider(height: 20),
                      _DetailItem(
                        icon: isPreTrip ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
                        label: AppStrings.labelInspectionType,
                        value: isPreTrip ? AppStrings.preTrip : AppStrings.postTrip,
                        valueColor: isPreTrip ? AppColors.secondary : AppColors.primary,
                      ),
                      const Divider(height: 20),
                      _DetailItem(
                        icon: Icons.calendar_today_outlined,
                        label: AppStrings.labelDateTime,
                        value: DateFormat('MM/dd/yyyy hh:mm a').format(r.displayDate),
                      ),
                      const Divider(height: 20),
                      _DetailItem(
                        icon: Icons.location_on_outlined,
                        label: AppStrings.labelGpsLocation,
                        value: r.gpsLocation?.address ?? '—',
                        multiLine: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Download PDF / Share Report — side-by-side
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.file_download_outlined,
                        label: _isDownloading ? AppStrings.generatingPdf : AppStrings.downloadPdf,
                        loading: _isDownloading,
                        onTap: _isDownloading ? null : _downloadPdf,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.ios_share_rounded,
                        label: _isSharing ? AppStrings.sharingLabel : AppStrings.shareReport,
                        loading: _isSharing,
                        onTap: _isSharing ? null : _shareReport,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Return to Dashboard
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => context.go(AppRoutes.dashboard),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(AppStrings.returnToDashboard, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  const _ActionCard({required this.icon, required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(9),
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.info),
                    )
                  : Icon(icon, color: AppColors.info, size: 20),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final TextStyle? valueStyle;
  final bool multiLine;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueStyle,
    this.multiLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: multiLine
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(value, style: valueStyle ?? TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.primary, height: 1.4)),
                ])
              : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Flexible(
                    child: Text(value, textAlign: TextAlign.right,
                        style: valueStyle ?? TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.primary)),
                  ),
                ]),
        ),
      ],
    );
  }
}
