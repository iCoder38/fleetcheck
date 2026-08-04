// lib/screens/inspection/defect_report_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/checklist_constants.dart';
import '../../models/inspection_model.dart';

class DefectReportScreen extends StatefulWidget {
  final List<String> damagedItems;
  final List<DefectReport> existingDefects;
  final String vehicleNumber;
  const DefectReportScreen({
    super.key,
    required this.damagedItems,
    required this.existingDefects,
    this.vehicleNumber = '',
  });
  @override State<DefectReportScreen> createState() => _DefectReportScreenState();
}

class _DefectReportScreenState extends State<DefectReportScreen> {
  late List<String> _categories;
  String? _category;
  String? _severity;
  final _descCtrl = TextEditingController();
  final List<DefectReport> _savedDefects = [];

  @override
  void initState() {
    super.initState();
    _categories = List.of(widget.damagedItems);
    _savedDefects.addAll(widget.existingDefects);
    if (_categories.isNotEmpty) _category = _categories.first;
  }

  @override
  void dispose() { _descCtrl.dispose(); super.dispose(); }

  final _severityColors = {'Low': AppColors.green, 'Medium': AppColors.amber, 'High': const Color(0xFFEA580C), 'Critical': AppColors.danger};

  void _pickCategory() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(AppStrings.categoryLabel,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ),
            ),
            ..._categories.map((c) => ListTile(
                  title: Text(c),
                  trailing: c == _category ? const Icon(Icons.check_rounded, color: AppColors.green) : null,
                  onTap: () { setState(() => _category = c); Navigator.pop(ctx); },
                )),
            ListTile(
              leading: const Icon(Icons.add_rounded, color: AppColors.green),
              title: const Text(AppStrings.addNewLabel, style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w700)),
              onTap: () async {
                Navigator.pop(ctx);
                final custom = await _promptCustomCategory();
                if (custom != null && custom.trim().isNotEmpty) {
                  setState(() {
                    _categories.add(custom.trim());
                    _category = custom.trim();
                  });
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<String?> _promptCustomCategory() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.addNewLabel),
        content: TextField(controller: ctrl, autofocus: true, style: const TextStyle(color: AppColors.primary), decoration: const InputDecoration(hintText: AppStrings.categoryLabel)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text(AppStrings.saveDefect)),
        ],
      ),
    );
  }

  void _saveDefect() {
    if (_category == null || _severity == null || _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.fillAllFields), backgroundColor: AppColors.amber));
      return;
    }
    setState(() {
      _savedDefects.add(DefectReport(category: _category!, severity: _severity!.toLowerCase(), description: _descCtrl.text.trim()));
      _descCtrl.clear();
      _severity = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.defectSaved), backgroundColor: AppColors.green));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.pop(context, _savedDefects);
      },
      child: Scaffold(
        backgroundColor: AppColors.appbg,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7A1E1E), Color(0xFF4A1010)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context, _savedDefects),
                        child: const Padding(
                          padding: EdgeInsets.only(right: 10, top: 2),
                          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(AppStrings.reportDefectDamageTitle,
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                          if (widget.vehicleNumber.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(AppStrings.vehicleLabel(widget.vehicleNumber),
                                style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.65))),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (_savedDefects.isNotEmpty) ...[
                    const Text(AppStrings.savedDefects, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    ..._savedDefects.map((d) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border)),
                      child: Row(children: [
                        Container(width: 8, height: 40, decoration: BoxDecoration(
                          color: _severityColors[d.severity[0].toUpperCase() + d.severity.substring(1)] ?? AppColors.textSecondary,
                          borderRadius: BorderRadius.circular(4))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(d.category, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          Text(d.description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ])),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: (_severityColors[d.severity[0].toUpperCase() + d.severity.substring(1)] ?? AppColors.textSecondary).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(99)),
                          child: Text(d.severity[0].toUpperCase() + d.severity.substring(1), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                            color: _severityColors[d.severity[0].toUpperCase() + d.severity.substring(1)] ?? AppColors.textSecondary))),
                      ]),
                    )),
                    const Divider(height: 32),
                  ],

                  // Category
                  const _SectionLabel(AppStrings.categoryLabel),
                  GestureDetector(
                    onTap: _pickCategory,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                      child: Row(children: [
                        Expanded(
                          child: Text(_category ?? AppStrings.selectCategoryHint,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                                  color: _category == null ? AppColors.textSecondary : AppColors.primary)),
                        ),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.add_rounded, size: 16, color: AppColors.green),
                          const SizedBox(width: 2),
                          const Text(AppStrings.addNewLabel, style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(width: 6),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                        ]),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Severity
                  const _SectionLabel(AppStrings.severityLevel),
                  Row(children: [
                    for (final s in ChecklistConstants.severityLevels) ...[
                      Expanded(child: _SeverityChip(
                        label: s,
                        color: _severityColors[s] ?? AppColors.textSecondary,
                        selected: _severity == s,
                        onTap: () => setState(() => _severity = s),
                      )),
                      if (s != ChecklistConstants.severityLevels.last) const SizedBox(width: 8),
                    ],
                  ]),
                  const SizedBox(height: 20),

                  // Description
                  const _SectionLabel(AppStrings.description),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 4,
                    maxLength: 1000,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: AppColors.primary),
                    decoration: InputDecoration(
                      hintText: AppStrings.describeDamageHint,
                      filled: true,
                      fillColor: Colors.white,
                      counterStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.green, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: _saveDefect,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: const Text(AppStrings.saveDefect, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.6)),
  );
}

class _SeverityChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _SeverityChip({required this.label, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: selected ? color : AppColors.border, width: 1.5),
      ),
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? color : AppColors.textSecondary)),
    ),
  );
}
