import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../constants/checklist_constants.dart';

/// Builds a FleetCheck-branded PDF inspection report.
///
/// [detail] is the raw map returned by
/// `InspectionRepository.getInspectionDetail()` (driver_name, vehicle_number,
/// vin, responses, defects, gps_location, additional_notes, ...). [driverData]
/// is the locally-stored logged-in driver profile (from `StorageService`),
/// used as a fallback for driver fields the detail payload doesn't carry
/// (employee/badge id, phone, license number).
class PdfReportService {
  static const PdfColor _navy    = PdfColor.fromInt(0xFF1A2A4A);
  static const PdfColor _amber   = PdfColor.fromInt(0xFFE8A020);
  static const PdfColor _green   = PdfColor.fromInt(0xFF1A7A47);
  static const PdfColor _red     = PdfColor.fromInt(0xFFC0392B);
  static const PdfColor _grey    = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _greyBg  = PdfColor.fromInt(0xFFE5E7EB);
  static const PdfColor _greenBg = PdfColor.fromInt(0xFFD5F0E3);
  static const PdfColor _redBg   = PdfColor.fromInt(0xFFFAD7D4);
  static const PdfColor _border  = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor _muted   = PdfColor.fromInt(0xFF9CA9C4);

  static final Map<String, String> _sectionTitles = _buildSectionTitles();

  static Map<String, String> _buildSectionTitles() {
    final titles = <String, String>{};
    for (final s in [
      ...ChecklistConstants.preTripSections(),
      ...ChecklistConstants.postTripSections(),
    ]) {
      if (s.items.isNotEmpty) titles[s.id] = s.title;
    }
    return titles;
  }

  final pw.Font _titleFont = pw.Font.helveticaBold();
  final pw.Font _bodyFont  = pw.Font.helvetica();

  Future<Uint8List> generateInspectionReport(
    Map<String, dynamic> detail, {
    Map<String, dynamic>? driverData,
  }) async {
    final doc = pw.Document();

    final responses = (detail['responses'] as List?)?.cast<dynamic>() ?? const [];
    final defects    = (detail['defects']   as List?)?.cast<dynamic>() ?? const [];
    final gps        = detail['gps_location'] as Map<String, dynamic>?;

    final failedCount = responses
        .where((r) => !_isOk((r as Map)['selected_option'] as String?))
        .length;
    final failed = failedCount > 0 || defects.isNotEmpty;

    final sections = _groupBySection(responses);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildHeader(detail, failed),
          pw.SizedBox(height: 16),
          _buildTwoColumnInfo(detail, driverData),
          pw.SizedBox(height: 14),
          _buildGpsSubmissionBanner(gps, detail),
          pw.SizedBox(height: 18),
          if (sections.isNotEmpty) ...[
            _sectionHeading('CHECKLIST RESPONSES'),
            pw.SizedBox(height: 6),
            ...sections.entries.expand((e) => [
                  _buildChecklistTable(e.key, e.value),
                  pw.SizedBox(height: 14),
                ]),
          ],
          if (defects.isNotEmpty) ...[
            _sectionHeading('DEFECTS / DAMAGE REPORTED'),
            pw.SizedBox(height: 6),
            _buildDefectsTable(defects.cast<Map<String, dynamic>>()),
            pw.SizedBox(height: 14),
          ],
          if ((detail['additional_notes'] as String?)?.isNotEmpty == true) ...[
            _sectionHeading('ADDITIONAL NOTES'),
            pw.SizedBox(height: 6),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _border),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                detail['additional_notes'].toString(),
                style: pw.TextStyle(font: _bodyFont, fontSize: 9.5, color: _navy),
              ),
            ),
            pw.SizedBox(height: 14),
          ],
          pw.Divider(color: _border),
          pw.SizedBox(height: 6),
          _buildFooter(detail),
        ],
      ),
    );

    return doc.save();
  }

  // ── Data helpers ──────────────────────────────────────────

  bool _isOk(String? raw) => raw == 'Good' || raw == 'Available' || raw == 'No';

  String _statusLabel(String? raw) {
    switch (raw) {
      case 'Good':          return 'GOOD';
      case 'Defective':     return 'DEFECTIVE';
      case 'Available':     return 'AVAILABLE';
      case 'Not Available': return 'NOT AVAILABLE';
      case 'Yes':            return 'YES';
      case 'No':             return 'NO';
      default:                return (raw ?? '—').toUpperCase();
    }
  }

  PdfColor _statusBg(String? raw) {
    if (_isOk(raw)) return _greenBg;
    if (raw == 'Not Available') return _greyBg;
    return _redBg;
  }

  PdfColor _statusFg(String? raw) {
    if (_isOk(raw)) return _green;
    if (raw == 'Not Available') return _grey;
    return _red;
  }

  Map<String, List<Map<String, dynamic>>> _groupBySection(List responses) {
    final order = <String>[];
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final raw in responses) {
      final r = raw as Map<String, dynamic>;
      final sid = (r['section_id'] ?? '').toString();
      if (sid.isEmpty) continue;
      if (!grouped.containsKey(sid)) {
        grouped[sid] = [];
        order.add(sid);
      }
      grouped[sid]!.add(r);
    }
    return {for (final sid in order) (_sectionTitles[sid] ?? sid): grouped[sid]!};
  }

  String _pick(Map<String, dynamic> d, String detailKey, Map<String, dynamic>? driver, [String? driverKey]) {
    final v = d[detailKey];
    if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    if (driverKey != null) {
      final dv = driver?[driverKey];
      if (dv != null && dv.toString().trim().isNotEmpty) return dv.toString();
    }
    return '—';
  }

  // ── Widget builders ───────────────────────────────────────

  pw.Widget _buildHeader(Map<String, dynamic> d, bool failed) {
    final isPreTrip = (d['inspection_type'] ?? '') == 'pre_trip';
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(color: _navy, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(children: [
                pw.Text('Fleet', style: pw.TextStyle(font: _titleFont, fontSize: 20, color: PdfColors.white)),
                pw.Text('Check', style: pw.TextStyle(font: _titleFont, fontSize: 20, color: _amber)),
              ]),
              pw.SizedBox(height: 6),
              pw.Text('Vehicle Inspection Report',
                  style: pw.TextStyle(font: _bodyFont, fontSize: 11, color: PdfColors.white)),
              pw.SizedBox(height: 2),
              pw.Text((d['company_name'] ?? d['vehicle_number'] ?? '—').toString(),
                  style: pw.TextStyle(font: _bodyFont, fontSize: 9, color: _muted)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text((d['inspection_id'] ?? '—').toString(),
                  style: pw.TextStyle(font: _titleFont, fontSize: 16, color: _amber)),
              pw.SizedBox(height: 4),
              pw.Text(isPreTrip ? 'Pre-Trip Inspection' : 'Post-Trip Inspection',
                  style: pw.TextStyle(font: _bodyFont, fontSize: 9, color: _muted)),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                    color: failed ? _redBg : _greenBg, borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    _passFailIcon(failed),
                    pw.SizedBox(width: 5),
                    pw.Text(failed ? 'FAILED' : 'PASSED',
                        style: pw.TextStyle(font: _titleFont, fontSize: 11, color: failed ? _red : _green)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Base14 Helvetica has no ✓/✗ glyphs, so those Unicode symbols silently
  // fail to render in the generated PDF — draw the check/cross as vector
  // strokes instead so it always shows regardless of font glyph coverage.
  pw.Widget _passFailIcon(bool failed) {
    final color = failed ? _red : _green;
    return pw.SizedBox(
      width: 9,
      height: 9,
      child: pw.CustomPaint(
        size: const PdfPoint(9, 9),
        painter: (canvas, size) {
          canvas
            ..setStrokeColor(color)
            ..setLineWidth(1.4);
          if (failed) {
            canvas
              ..moveTo(1, 1)
              ..lineTo(size.x - 1, size.y - 1)
              ..strokePath()
              ..moveTo(size.x - 1, 1)
              ..lineTo(1, size.y - 1)
              ..strokePath();
          } else {
            canvas
              ..moveTo(0.5, size.y * 0.5)
              ..lineTo(size.x * 0.4, size.y * 0.15)
              ..lineTo(size.x - 0.5, size.y * 0.85)
              ..strokePath();
          }
        },
      ),
    );
  }

  pw.Widget _buildTwoColumnInfo(Map<String, dynamic> d, Map<String, dynamic>? driver) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _infoCard('DRIVER INFORMATION', [
            MapEntry('Name', _pick(d, 'driver_name', driver, 'full_name')),
            MapEntry('Employee ID', _pick(d, 'employee_id', driver, 'employee_id')),
            MapEntry('Badge ID', _pick(d, 'badge_id', driver, 'badge_id')),
            MapEntry('Phone', _pick(d, 'phone', driver, 'phone')),
            MapEntry('License No.', _pick(d, 'license_number', driver, 'license_number')),
          ]),
        ),
        pw.SizedBox(width: 14),
        pw.Expanded(
          child: _infoCard('VEHICLE INFORMATION', [
            MapEntry('Vehicle No.', _pick(d, 'vehicle_number', null)),
            MapEntry('Type', _pick(d, 'vehicle_type', null)),
            MapEntry('VIN', _pick(d, 'vin', null)),
            MapEntry('Plate No.', _pick(d, 'plate_number', null)),
            MapEntry('Trailer No.', _pick(d, 'trailer_number', null)),
          ]),
        ),
      ],
    );
  }

  pw.Widget _infoCard(String title, List<MapEntry<String, String>> rows) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(font: _titleFont, fontSize: 8.5, color: _grey)),
          pw.SizedBox(height: 8),
          for (final r in rows) ...[
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(r.key, style: pw.TextStyle(font: _bodyFont, fontSize: 9, color: _grey)),
                pw.Text(r.value, style: pw.TextStyle(font: _titleFont, fontSize: 9, color: _navy)),
              ],
            ),
            pw.SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildGpsSubmissionBanner(Map<String, dynamic>? gps, Map<String, dynamic> d) {
    final submittedAt =
        d['submitted_at'] != null ? DateTime.tryParse(d['submitted_at'].toString()) : null;
    final dateStr = submittedAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(submittedAt)
        : '—';
    final address = gps?['address']?.toString() ?? '—';
    final lat = gps?['latitude'];
    final lng = gps?['longitude'];
    final coords = (lat != null && lng != null)
        ? '${double.tryParse(lat.toString())?.toStringAsFixed(6) ?? lat}, '
            '${double.tryParse(lng.toString())?.toStringAsFixed(6) ?? lng}'
        : null;

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(color: _greenBg, borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('GPS LOCATION', style: pw.TextStyle(font: _titleFont, fontSize: 8, color: _green)),
                pw.SizedBox(height: 3),
                pw.Text(address, style: pw.TextStyle(font: _titleFont, fontSize: 9, color: _navy)),
                if (coords != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(coords, style: pw.TextStyle(font: _bodyFont, fontSize: 8, color: _grey)),
                ],
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('SUBMISSION', style: pw.TextStyle(font: _titleFont, fontSize: 8, color: _green)),
              pw.SizedBox(height: 3),
              pw.Text(dateStr, style: pw.TextStyle(font: _titleFont, fontSize: 9, color: _navy)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionHeading(String text) =>
      pw.Text(text, style: pw.TextStyle(font: _titleFont, fontSize: 10, color: _grey));

  pw.Widget _buildChecklistTable(String title, List<Map<String, dynamic>> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: const pw.BoxDecoration(
            color: _navy,
            borderRadius: pw.BorderRadius.only(
              topLeft: pw.Radius.circular(6),
              topRight: pw.Radius.circular(6),
            ),
          ),
          child: pw.Text(title, style: pw.TextStyle(font: _titleFont, fontSize: 10, color: PdfColors.white)),
        ),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _border),
            borderRadius: const pw.BorderRadius.only(
              bottomLeft: pw.Radius.circular(6),
              bottomRight: pw.Radius.circular(6),
            ),
          ),
          child: pw.Column(
            children: [
              for (int i = 0; i < items.length; i++)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: pw.BoxDecoration(
                    border: i == items.length - 1
                        ? null
                        : const pw.Border(bottom: pw.BorderSide(color: _border)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text((items[i]['item_label'] ?? '').toString(),
                          style: pw.TextStyle(font: _bodyFont, fontSize: 9, color: _navy)),
                      _statusBadge(items[i]['selected_option'] as String?),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _statusBadge(String? raw) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(color: _statusBg(raw), borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Text(_statusLabel(raw),
          style: pw.TextStyle(font: _titleFont, fontSize: 7.5, color: _statusFg(raw))),
    );
  }

  pw.Widget _buildDefectsTable(List<Map<String, dynamic>> defects) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          for (int i = 0; i < defects.length; i++)
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: i == defects.length - 1
                    ? null
                    : const pw.Border(bottom: pw.BorderSide(color: _border)),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text((defects[i]['category'] ?? '').toString(),
                            style: pw.TextStyle(font: _titleFont, fontSize: 9.5, color: _navy)),
                        pw.SizedBox(height: 2),
                        pw.Text((defects[i]['description'] ?? '').toString(),
                            style: pw.TextStyle(font: _bodyFont, fontSize: 8.5, color: _grey)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  _severityBadge((defects[i]['severity'] ?? '').toString()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _severityBadge(String severity) {
    final PdfColor color = switch (severity.toLowerCase()) {
      'critical' => _red,
      'high'     => const PdfColor.fromInt(0xFFEA580C),
      'medium'   => _amber,
      _          => _green,
    };
    final label = severity.isEmpty ? '—' : '${severity[0].toUpperCase()}${severity.substring(1)}';
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: color), borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Text(label, style: pw.TextStyle(font: _titleFont, fontSize: 7.5, color: color)),
    );
  }

  pw.Widget _buildFooter(Map<String, dynamic> d) {
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Y-CheckPro — Inspection Report © ${DateTime.now().year}',
            style: pw.TextStyle(font: _bodyFont, fontSize: 8, color: _grey)),
        pw.Text('Generated: $now', style: pw.TextStyle(font: _bodyFont, fontSize: 8, color: _grey)),
        pw.Text((d['inspection_id'] ?? '').toString(),
            style: pw.TextStyle(font: _bodyFont, fontSize: 8, color: _grey)),
      ],
    );
  }
}
