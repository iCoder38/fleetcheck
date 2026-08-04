// lib/screens/inspection/checklist/checklist_screen.dart
// Updated for Feature 2: renders dynamic checklist sections from QrData
// instead of hardcoded checklist_constants.dart items.
// checklist_constants.dart is kept as fallback only.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_responsive.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/inspection_model.dart';
import '../../../routes/app_router.dart';

class ChecklistScreen extends StatefulWidget {
  final QrData qrData;
  final String inspectionType;

  const ChecklistScreen({
    super.key,
    required this.qrData,
    required this.inspectionType,
  });

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  // ── Sections resolved from QrData (API) or fallback constants ────────────
  late final List<ChecklistTemplateSection> _sections;

  // ── State ─────────────────────────────────────────────────────────────────
  int _currentSection = 0;

  // responses[sectionIndex][itemId] = selected option string
  late final List<Map<int, String>> _responses;

  // text/number responses[sectionIndex][itemId] = value
  late final List<Map<int, String>> _textValues;

  // Additional notes (notes section)
  final Map<int, TextEditingController> _notesCtrl = {};

  // Defect reports collected during this inspection
  final List<DefectReport> _defects = [];

  // Track which items need defect reports (yes_no items answered Yes)
  final Set<int> _defectItems = {};

  @override
  void initState() {
    super.initState();

    // Use sections from the scan API response (Feature 2)
    // Filter out the standalone "Defect Report" section — defects are
    // collected via the popup dialog in Section 6 (Vehicle Damage).
    // Showing it again as a separate section causes duplicate data entry.
    final _defectSectionTitles = [
      'defect report',
      'defect reports',
      'vehicle defect',
      'vehicle defect details',
    ];
    final rawSections = widget.qrData.checklistSections.isNotEmpty
        ? widget.qrData.checklistSections
        : _fallbackSections();

    _sections = rawSections.where((sec) {
      final titleLower = sec.title.toLowerCase().trim();
      return !_defectSectionTitles.any((t) => titleLower.contains(t));
    }).toList();

    _responses = List.generate(_sections.length, (_) => {});
    _textValues = List.generate(_sections.length, (_) => {});

    // Pre-create notes controllers for notes sections
    for (int i = 0; i < _sections.length; i++) {
      if (_sections[i].isNotesSection) {
        _notesCtrl[i] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _notesCtrl.values) c.dispose();
    super.dispose();
  }

  // ── Fallback to hardcoded DOT items if API returns empty sections ─────────
  List<ChecklistTemplateSection> _fallbackSections() {
    // Minimal fallback — normally the API always returns sections after
    // Feature 1 (auto-assign) is deployed.
    return [
      ChecklistTemplateSection(
        id: 0,
        title: 'Vehicle Exterior',
        sortOrder: 1,
        isNotesSection: false,
        items: [
          ChecklistTemplateItem(
              id: 1,
              label: 'Headlights',
              responseType: 'good_defective',
              isRequired: true,
              isDotMandatory: true,
              sortOrder: 1,
              options: ['Good', 'Defective']),
          ChecklistTemplateItem(
              id: 2,
              label: 'Brake Lights',
              responseType: 'good_defective',
              isRequired: true,
              isDotMandatory: true,
              sortOrder: 2,
              options: ['Good', 'Defective']),
          ChecklistTemplateItem(
              id: 3,
              label: 'Turn Signals',
              responseType: 'good_defective',
              isRequired: true,
              isDotMandatory: true,
              sortOrder: 3,
              options: ['Good', 'Defective']),
          ChecklistTemplateItem(
              id: 4,
              label: 'Mirrors',
              responseType: 'good_defective',
              isRequired: true,
              isDotMandatory: true,
              sortOrder: 4,
              options: ['Good', 'Defective']),
          ChecklistTemplateItem(
              id: 5,
              label: 'Windshield',
              responseType: 'good_defective',
              isRequired: true,
              isDotMandatory: true,
              sortOrder: 5,
              options: ['Good', 'Defective']),
          ChecklistTemplateItem(
              id: 6,
              label: 'Wipers',
              responseType: 'good_defective',
              isRequired: true,
              isDotMandatory: true,
              sortOrder: 6,
              options: ['Good', 'Defective']),
          ChecklistTemplateItem(
              id: 7,
              label: 'Horn',
              responseType: 'good_defective',
              isRequired: true,
              isDotMandatory: true,
              sortOrder: 7,
              options: ['Good', 'Defective']),
        ],
      ),
      ChecklistTemplateSection(
        id: 0,
        title: 'Additional Notes',
        sortOrder: 2,
        isNotesSection: true,
        items: [],
      ),
    ];
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  ChecklistTemplateSection get _section => _sections[_currentSection];
  bool get _isNotesSection => _section.isNotesSection;
  bool get _isLastSection => _currentSection == _sections.length - 1;

  bool _isSectionComplete(int idx) {
    final sec = _sections[idx];
    if (sec.isNotesSection){
      // Collect additional notes
      final StringBuffer notes = StringBuffer();
      for (final entry in _notesCtrl.entries) {
        if (_notesCtrl[entry.key]!.text.trim().isNotEmpty) {
          notes.write(_notesCtrl[entry.key]!.text.trim());
        }
      }
      // if(notes.toString().isNotEmpty)
      return notes.toString().isNotEmpty;
    }  // notes always optional
    for (final item in sec.items) {
      if (item.isRequired && item.isSelectInput) {
        if (!_responses[idx].containsKey(item.id)) return false;
      }
    }
    return true;
  }

  int get _totalItems {
    int t = 0;
    for (final sec in _sections) t += sec.totalItems;
    return t;
  }

  int get _answeredItems {
    int a = 0;
    for (int i = 0; i < _sections.length; i++) {
      final sec = _sections[i];
      if (sec.isNotesSection) continue;
      for (final item in sec.items) {
        if (_responses[i].containsKey(item.id) ||
            _textValues[i].containsKey(item.id)) a++;
      }
    }
    return a;
  }

  double get _progress => _totalItems == 0 ? 0 : _answeredItems / _totalItems;

  // ── Navigation ────────────────────────────────────────────────────────────
  void _next() {
    if (!_isSectionComplete(_currentSection)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please answer all required items before continuing.'),
        backgroundColor: AppColors.danger,
        duration: Duration(seconds: 2),
      ));
      return;
    }

    // Check if any yes_no items answered Yes need defect reports
    _checkForDefects();

    if (_isLastSection) {
      _proceedToGps();
      return;
    }
    setState(() => _currentSection++);
  }

  void _prev() {
    if (_currentSection > 0) setState(() => _currentSection--);
  }

  void _checkForDefects() {
    final sec = _sections[_currentSection];
    for (final item in sec.items) {
      final resp = _responses[_currentSection][item.id];
      if (resp == 'Yes' && !_defectItems.contains(item.id)) {
        _defectItems.add(item.id);
        _showDefectDialog(item);
      }
    }
  }

  // void _showDefectDialog(ChecklistTemplateItem item) {
  //   String severity = 'low';
  //   final descCtrl = TextEditingController();
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (_) => StatefulBuilder(
  //       builder: (ctx, setDlg) => SizedBox(
  //         width: MediaQuery.of(context).size.width * 0.8,
  //         child: AlertDialog(
  //           backgroundColor: AppColors.appbg,
  //           shape:
  //               RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //           title:
  //               Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  //             Text('Defect Reported',
  //                 style: AppTextStyles.label(context,
  //                     color: AppColors.danger)),
  //             Text(item.label,
  //                 style: AppTextStyles.bodySmall(context,
  //                     color: AppColors.darkBackground)),
  //           ]),
  //           content: Column(mainAxisSize: MainAxisSize.min, children: [
  //             Align(
  //                 alignment: Alignment.centerLeft,
  //                 child: Text('Severity',
  //                     style: AppTextStyles.bodySmall(context,
  //                         color: AppColors.darkBackground)
  //                         .copyWith(fontWeight: FontWeight.w700))),
  //             SizedBox(height: AppResponsive.spacing(context, 6)),
  //             Row(
  //                 children: ['low', 'medium', 'high', 'critical'].map((s) {
  //               final col = {
  //                 'low': AppColors.green,//AppColors.textSecondary,
  //                 'medium': AppColors.green,
  //                 'high': AppColors.green,//AppColors.warning,
  //                 'critical': AppColors.green,//AppColors.danger
  //               }[s]!;
  //               return Expanded(
  //                   child: Padding(
  //                 padding: EdgeInsets.only(
  //                     right: AppResponsive.spacing(context, 4)),
  //                 child: GestureDetector(
  //                   onTap: () => setDlg(() => severity = s),
  //                   child: Container(
  //                     padding: EdgeInsets.symmetric(
  //                         vertical: AppResponsive.padding(context, 6)),
  //                     decoration: BoxDecoration(
  //                       color: severity == s
  //                           ? col.withOpacity(0.15)
  //                           : AppColors.textSecondary,
  //                       // color: col.withOpacity(0.15),
  //                       border: Border.all(
  //                           color: severity == s ? col : AppColors.background,
  //                           // color: col,
  //                           width: severity == s ? 2 : 1),
  //                       borderRadius: BorderRadius.circular(6),
  //                     ),
  //                     child: Text(s[0].toUpperCase() + s.substring(1),
  //                         textAlign: TextAlign.center,
  //                         style: TextStyle(
  //                             fontSize: AppResponsive.text(context, 10),
  //                             fontWeight: FontWeight.w700,
  //                             color: severity == s ? col : AppColors.primary)),
  //                             // color: AppColors.appbg)),
  //                   ),
  //                 ),
  //               ));
  //             }).toList()),
  //             SizedBox(height: AppResponsive.spacing(context, 12)),
  //             TextField(
  //               controller: descCtrl,
  //               maxLines: 3,
  //               decoration: InputDecoration(
  //                 hintText: 'Describe the defect…',
  //                 hintStyle: AppTextStyles.bodySmall(context,
  //                     color: AppColors.textSecondary),
  //                 border: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(8),
  //                     borderSide: const BorderSide(color: AppColors.border)),
  //                 contentPadding: EdgeInsets.all(AppResponsive.padding(context, 10)),
  //               ),
  //               style: AppTextStyles.bodySmall(context,
  //                   color: AppColors.darkBackground),
  //             ),
  //           ]),
  //           actions: [
  //             TextButton(
  //               onPressed: () {
  //                 Navigator.pop(ctx);
  //               },
  //               child: Text('Skip',
  //                   style: AppTextStyles.bodySmall(context,
  //                       color: AppColors.textSecondary)),
  //             ),
  //             ElevatedButton(
  //               onPressed: () {
  //                 if (descCtrl.text.trim().isNotEmpty) {
  //                   setState(() {
  //                     _defects.add(DefectReport(
  //                       category: item.label,
  //                       severity: severity,
  //                       description: descCtrl.text.trim(),
  //                       templateItemId: item.id > 0 ? item.id : null,
  //                     ));
  //                   });
  //                 }
  //                 Navigator.pop(ctx);
  //               },
  //               style: ElevatedButton.styleFrom(
  //                   backgroundColor: AppColors.danger,
  //                   foregroundColor: AppColors.textOnPrimary),
  //               child: const Text('Save Defect'),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // ── Defect categories and severity levels ─────────────────────────────────
  static const _defectCategories = [
    'Body Damage',
    'Tire Damage',
    'Mechanical Issue',
    'Accident Report',
  ];

  static const _severityLevels = ['low', 'medium', 'high', 'critical'];

  static Color _severityColor(String s) {
    switch (s) {
      case 'low':      return Colors.green;
      case 'medium':   return Colors.orange;
      case 'high':     return Colors.deepOrange;
      case 'critical': return Colors.red;
      default:         return Colors.green;
    }
  }

  void _showDefectDialog(ChecklistTemplateItem item) {
    String category = _defectCategories.first;
    String severity  = 'low';
    final descCtrl   = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            backgroundColor: AppColors.appbg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.appbg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Title ──────────────────────────────────────────────
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.warning_amber_rounded,
                            color: AppColors.danger, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Defect Report',
                              style: AppTextStyles.label(context,
                                  color: AppColors.danger)),
                          Text(item.label,
                              style: AppTextStyles.bodySmall(context,
                                  color: AppColors.darkBackground)),
                        ],
                      )),
                    ]),

                    const SizedBox(height: 20),

                    // ── Defect Category Dropdown ───────────────────────────
                    Text('Defect Category',
                        style: AppTextStyles.bodySmall(context,
                            color: AppColors.darkBackground)
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: category,
                          isExpanded: true,
                          dropdownColor: Colors.white,   // ← add this line
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: AppColors.primary),
                          style: AppTextStyles.body(context,
                              color: AppColors.primary),
                          onChanged: (val) {
                            if (val != null) setDlg(() => category = val);
                          },
                          items: _defectCategories.map((cat) =>
                            DropdownMenuItem(
                              value: cat,
                              child: Text(cat, style: AppTextStyles.body(context, color: AppColors.navy),),
                            ),
                          ).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Severity Level ─────────────────────────────────────
                    Text('Severity Level',
                        style: AppTextStyles.bodySmall(context,
                            color: AppColors.darkBackground)
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(
                      children: _severityLevels.map((s) {
                        final col      = _severityColor(s);
                        final selected = severity == s;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: InkWell(
                              onTap: () => setDlg(() => severity = s),
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? col.withOpacity(0.15)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selected ? col : Colors.grey.shade300,
                                    width: selected ? 2 : 1,
                                  ),
                                ),
                                child: Text(
                                  s[0].toUpperCase() + s.substring(1),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: selected ? col : Colors.black54,
                                    fontWeight: selected
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // ── Description ────────────────────────────────────────
                    Text('Description (optional)',
                        style: AppTextStyles.bodySmall(context,
                            color: AppColors.darkBackground)
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      style: AppTextStyles.body(context, color: AppColors.primary),
                      decoration: InputDecoration(
                        hintText: 'Describe the defect…',
                        hintStyle: AppTextStyles.bodySmall(context,
                            color: AppColors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Action Buttons ─────────────────────────────────────
                    Row(
                      children: [
                        // Skip — driver tapped No or wants to dismiss
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Skip',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Save defect
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              // Category + severity required; description optional
                              final desc = descCtrl.text.trim().isNotEmpty
                                  ? descCtrl.text.trim()
                                  : '$category — ${severity[0].toUpperCase() + severity.substring(1)} Severity';
                              setState(() {
                                _defects.add(DefectReport(
                                  category:       category,
                                  severity:       severity,
                                  description:    desc,
                                  templateItemId: item.id > 0 ? item.id : null,
                                ));
                              });
                              Navigator.pop(ctx);
                            },
                            child: const Text('Save Defect',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _proceedToGps() {
    // Build checklist responses list from all sections
    final List<ChecklistResponse> responses = [];
    for (int i = 0; i < _sections.length; i++) {
      final sec = _sections[i];
      if (sec.isNotesSection) continue;
      for (final item in sec.items) {
        final selected = _responses[i][item.id];
        final text = _textValues[i][item.id];
        if (selected != null || text != null) {
          responses.add(ChecklistResponse(
            templateItemId: item.id > 0 ? item.id : null,
            sectionTitle: sec.title,
            itemLabel: item.label,
            selectedOption: selected ?? text ?? '',
            response: selected != null
                ? item.optionToResponse(selected)
                : (text ?? ''),
            textValue: text,
          ));
        }
      }
    }

    // Collect additional notes
    final StringBuffer notes = StringBuffer();
    for (final entry in _notesCtrl.entries) {
      if (_notesCtrl[entry.key]!.text.trim().isNotEmpty) {
        notes.write(_notesCtrl[entry.key]!.text.trim());
      }
    }

    context.push(AppRoutes.gpsVerification, extra: {
      'qrData': widget.qrData,
      'inspectionType': widget.inspectionType,
      'responses': responses,
      'defects': _defects,
      'additionalNotes': notes.toString(),
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appbg,
      body: Column(children: [
        _buildHeader(),
        Expanded(child: _buildBody()),
        _buildBottomBar(),
      ]),
    );
  }

  Widget _buildHeader() {
    final top = MediaQuery.of(context).padding.top;
    final pct = (_progress * 100).toStringAsFixed(0);
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Column(children: [
        SizedBox(height: top + 4),
        Padding(
          padding: AppResponsive.symmetric(context, horizontal: 16, vertical: 10),
          child: Row(children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: AppResponsive.scale(context, 36),
                height: AppResponsive.scale(context, 36),
                decoration: BoxDecoration(
                    color: AppColors.textOnPrimary.withOpacity(0.15),
                    shape: BoxShape.circle),
                child: Icon(Icons.arrow_back_rounded,
                    color: AppColors.textOnPrimary,
                    size: AppResponsive.scale(context, 20)),
              ),
            ),
            SizedBox(width: AppResponsive.spacing(context, 12)),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.inspectionType == 'pre_trip'
                          ? 'Pre-Trip Inspection'
                          : 'Post-Trip Inspection',
                      style: AppTextStyles.button(context,
                          color: AppColors.textOnPrimary)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(widget.qrData.vehicleNumber,
                        style: AppTextStyles.bodySmall(context,
                            color:
                                AppColors.textOnPrimary.withOpacity(0.65))),
                  ]),
            ),
            // Overall progress badge
            Container(
              padding: AppResponsive.symmetric(context,
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.textOnPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text('$pct%',
                  style: AppTextStyles.bodySmall(context,
                          color: AppColors.textOnPrimary)
                      .copyWith(fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
        // Global progress bar
        Container(
          height: 3,
          margin: EdgeInsets.fromLTRB(
              AppResponsive.spacing(context, 16),
              0,
              AppResponsive.spacing(context, 16),
              AppResponsive.spacing(context, 12)),
          decoration: BoxDecoration(
            color: AppColors.textOnPrimary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(99),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(99)),
            ),
          ),
        ),
        // Section tab strip
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.fromLTRB(
              AppResponsive.spacing(context, 16),
              0,
              AppResponsive.spacing(context, 16),
              AppResponsive.spacing(context, 14)),
          child: Row(
            children: List.generate(_sections.length, (i) {
              final done = _isSectionComplete(i);
              final current = i == _currentSection;
              return GestureDetector(
                onTap: () {
                  // Allow going back to any completed section
                  if (i < _currentSection || done)
                    setState(() => _currentSection = i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: EdgeInsets.only(
                      right: AppResponsive.spacing(context, 8)),
                  padding: AppResponsive.symmetric(context,
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: current
                        ? AppColors.textOnPrimary
                        : done
                            ? AppColors.green.withOpacity(0.25)
                            : AppColors.textOnPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: current
                          ? AppColors.textOnPrimary
                          : AppColors.textOnPrimary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (done && !current)
                      Icon(Icons.check_circle_rounded,
                          size: AppResponsive.scale(context, 12),
                          color: AppColors.green),
                    if (done && !current)
                      SizedBox(width: AppResponsive.spacing(context, 4)),
                    Text(
                      '${i + 1}',
                      style: AppTextStyles.bodySmall(
                        context,
                        color: current
                            ? AppColors.primary
                            : AppColors.textOnPrimary.withOpacity(0.8),
                      ).copyWith(
                          fontSize: AppResponsive.text(context, 11),
                          fontWeight: FontWeight.w800),
                    ),
                  ]),
                ),
              );
            }),
          ),
        ),
      ]),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: AppResponsive.all(context, value: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Section heading
        Row(children: [
          Expanded(
            child: Text(_section.title,
                style: AppTextStyles.heading3(context,
                        color: AppColors.primary)
                    .copyWith(fontWeight: FontWeight.w800)),
          ),
          if (!_isNotesSection)
            Text(
                '${_responses[_currentSection].length + _textValues[_currentSection].length} / ${_section.items.length}',
                style: AppTextStyles.bodySmall(context,
                        color: AppColors.primary)
                    .copyWith(fontWeight: FontWeight.w600)),
        ]),
        SizedBox(height: AppResponsive.spacing(context, 4)),
        // Section progress bar
        if (!_isNotesSection)
          LinearProgressIndicator(
            value: _section.items.isEmpty
                ? 0
                : (_responses[_currentSection].length +
                        _textValues[_currentSection].length) /
                    _section.items.length,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.green),
            minHeight: 3,
            borderRadius: BorderRadius.circular(99),
          ),
        SizedBox(height: AppResponsive.spacing(context, 20)),

        // Notes section
        if (_isNotesSection) _buildNotesSection(),

        // Checklist items
        if (!_isNotesSection)
          ..._section.items.map((item) => _buildItemCard(item)),
      ]),
    );
  }

  Widget _buildNotesSection() {
    final ctrl = _notesCtrl[_currentSection] ??= TextEditingController();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Additional notes for this inspection (optional):',
          style: AppTextStyles.bodySmall(context,
              color: AppColors.textSecondary)),
      SizedBox(height: AppResponsive.spacing(context, 10)),
      TextField(
        controller: ctrl,
        maxLines: 6,
        maxLength: 1000,
        decoration: InputDecoration(
          hintText: 'Enter any additional observations…',
          hintStyle: AppTextStyles.bodySmall(context,
              color: AppColors.textSecondary),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.green, width: 2)),
          contentPadding: AppResponsive.all(context, value: 14),
          filled: true,
          fillColor: AppColors.appbg,
        ),
        style: AppTextStyles.bodySmall(context, color: AppColors.primary),
      ),
    ]);
  }

  Widget _buildItemCard(ChecklistTemplateItem item) {
    final selected = _responses[_currentSection][item.id];
    final textVal = _textValues[_currentSection][item.id];
    final answered =
        selected != null || (textVal != null && textVal.isNotEmpty);

    return Container(
      margin: EdgeInsets.only(bottom: AppResponsive.spacing(context, 12)),
      decoration: BoxDecoration(
        color: AppColors.appbg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: answered
              ? AppColors.green.withOpacity(0.4)
              : AppColors.border,
          width: answered ? 1.5 : 1,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Item header
        Padding(
          padding: EdgeInsets.fromLTRB(
              AppResponsive.spacing(context, 14),
              AppResponsive.spacing(context, 12),
              AppResponsive.spacing(context, 14),
              AppResponsive.spacing(context, 8)),
          child: Row(children: [
            if (item.isDotMandatory)
              Container(
                margin: EdgeInsets.only(right: AppResponsive.spacing(context, 6)),
                padding: AppResponsive.symmetric(context,
                    horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('🛡 DOT',
                    style: TextStyle(
                        fontSize: AppResponsive.text(context, 8),
                        fontWeight: FontWeight.w800,
                        color: AppColors.green)),
              ),
            Expanded(
              child: Text(item.label,
                  style: AppTextStyles.body(context,
                          color: AppColors.primary, weight: FontWeight.w700)),
            ),
            if (item.isRequired && !answered)
              Text('*',
                  style: TextStyle(
                      color: AppColors.danger,
                      fontSize: AppResponsive.text(context, 16),
                      fontWeight: FontWeight.w900)),
            if (answered)
              Icon(Icons.check_circle_rounded,
                  size: AppResponsive.scale(context, 18),
                  color: AppColors.green),
          ]),
        ),
        // Text input items
        if (item.isTextInput || item.isNumberInput)
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppResponsive.spacing(context, 14),
                0,
                AppResponsive.spacing(context, 14),
                AppResponsive.spacing(context, 12)),
            child: TextField(
              style:AppTextStyles.bodySmall(context,
                  color: AppColors.primary),
              keyboardType: item.isNumberInput
                  ? TextInputType.number
                  : TextInputType.text,
              onChanged: (val) => setState(() {
                if (val.trim().isEmpty) {
                  _textValues[_currentSection].remove(item.id);
                } else {
                  _textValues[_currentSection][item.id] = val.trim();
                }
              }),
              decoration: InputDecoration(
                hintText: item.isNumberInput ? 'Enter number…' : 'Enter value…',
                hintStyle: AppTextStyles.bodySmall(context,
                    color: AppColors.textSecondary),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border)),
                contentPadding: AppResponsive.symmetric(context,
                    horizontal: 10, vertical: 8),
                isDense: true,
              ),
            ),
          ),
        // Select option buttons
        if (item.isSelectInput)
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppResponsive.spacing(context, 14),
                0,
                AppResponsive.spacing(context, 14),
                AppResponsive.spacing(context, 12)),
            child: Row(
              children: item.options.map((opt) {
                final isSelected = selected == opt;
                // Colour scheme: first option = green (Good/Available/Yes/Pass),
                // last option   = red   (Defective/Not Available/No/Fail)
                final isGood = opt == item.options.first;
                final activeColor =
                    isGood ? AppColors.green : AppColors.danger;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: AppResponsive.spacing(context, 8)),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _responses[_currentSection][item.id] = opt;
                        if (item.responseType == 'yes_no') {
                          if (opt == 'Yes' && !_defectItems.contains(item.id)) {
                            // Driver selected Yes — show defect dialog
                            _defectItems.add(item.id);
                            Future.delayed(
                              const Duration(milliseconds: 150),
                              () => _showDefectDialog(item),
                            );
                          } else if (opt == 'No') {
                            // Driver selected No — remove any defect for this item
                            _defectItems.remove(item.id);
                            _defects.removeWhere(
                                (d) => d.templateItemId == item.id);
                          }
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: EdgeInsets.symmetric(
                            vertical: AppResponsive.padding(context, 10)),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? activeColor.withOpacity(0.12)
                              : AppColors.appbg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? activeColor : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(opt,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.label(
                              context,
                              color:
                                  isSelected ? activeColor : AppColors.textSecondary,
                            ).copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w500)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ]),
    );
  }

  Widget _buildBottomBar() {
    final sectionDone = _isSectionComplete(_currentSection);
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppResponsive.spacing(context, 20),
          AppResponsive.spacing(context, 12),
          AppResponsive.spacing(context, 20),
          MediaQuery.of(context).padding.bottom +
              AppResponsive.spacing(context, 12)),
      decoration: const BoxDecoration(
        color: AppColors.appbg,
        border: Border(top: BorderSide(color: AppColors.appbg)),
      ),
      child: Row(children: [
        // Previous button
        if (_currentSection > 0)
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: _prev,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                padding: EdgeInsets.symmetric(
                    vertical: AppResponsive.padding(context, 14)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('← Back',
                  style: AppTextStyles.body(context,
                      color: AppColors.primary, weight: FontWeight.w700)),
            ),
          ),
        if (_currentSection > 0)
          SizedBox(width: AppResponsive.spacing(context, 12)),
        // Next / Submit button
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: sectionDone ? _next : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
              AppColors.green,
              foregroundColor: AppColors.textOnPrimary,
              disabledBackgroundColor: AppColors.border,
              disabledForegroundColor: AppColors.textSecondary,
              padding: EdgeInsets.symmetric(
                  vertical: AppResponsive.padding(context, 14)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: sectionDone ? 3 : 0,
            ),
            child: Text(
              _isLastSection ? 'Complete & Continue →' : 'Next Section →',
              style: AppTextStyles.body(context,
                      color: AppColors.textOnPrimary, weight: FontWeight.w800)
                  .copyWith(fontSize: AppResponsive.text(context, 14)),
            ),
          ),
        ),
      ]),
    );
  }
}
