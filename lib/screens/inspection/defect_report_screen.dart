// lib/screens/inspection/defect_report_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/checklist_constants.dart';
import '../../models/inspection_model.dart';

class DefectReportScreen extends StatefulWidget {
  final List<String> damagedItems;
  final List<DefectReport> existingDefects;
  const DefectReportScreen({super.key, required this.damagedItems, required this.existingDefects});
  @override State<DefectReportScreen> createState() => _DefectReportScreenState();
}

class _DefectReportScreenState extends State<DefectReportScreen> {
  String? _category;
  String? _severity;
  final _descCtrl = TextEditingController();
  final List<DefectReport> _savedDefects = [];

  @override
  void initState() {
    super.initState();
    _savedDefects.addAll(widget.existingDefects);
    if (widget.damagedItems.isNotEmpty) _category = widget.damagedItems.first;
  }

  @override
  void dispose() { _descCtrl.dispose(); super.dispose(); }

  final _severityColors = {'Low': AppColors.green, 'Medium': AppColors.amber, 'High': const Color(0xFFEA580C), 'Critical': AppColors.red};

  void _saveDefect() {
    if (_category == null || _severity == null || _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields.'), backgroundColor: AppColors.amber));
      return;
    }
    setState(() {
      _savedDefects.add(DefectReport(category: _category!, severity: _severity!.toLowerCase(), description: _descCtrl.text.trim()));
      _descCtrl.clear();
      _severity = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Defect saved.'), backgroundColor: AppColors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Defect Report'), backgroundColor: AppColors.navy,
          leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context, _savedDefects))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Saved defects
          if (_savedDefects.isNotEmpty) ...[
            const Text('Saved Defects', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy)),
            const SizedBox(height: 8),
            ..._savedDefects.map((d) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Container(width: 8, height: 40, decoration: BoxDecoration(
                  color: _severityColors[d.severity[0].toUpperCase() + d.severity.substring(1)] ?? AppColors.muted,
                  borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.category, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(d.description, style: const TextStyle(fontSize: 12, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: (_severityColors[d.severity[0].toUpperCase() + d.severity.substring(1)] ?? AppColors.muted).withOpacity(0.1), borderRadius: BorderRadius.circular(99)),
                  child: Text(d.severity[0].toUpperCase() + d.severity.substring(1), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: _severityColors[d.severity[0].toUpperCase() + d.severity.substring(1)] ?? AppColors.muted))),
              ]),
            )),
            const Divider(height: 32),
          ],

          const Text('Add Defect Report', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 16),

          // Category
          const _FieldLabel(label: 'Defect / Damage Category'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value:     _category,
                isExpanded: true,
                hint:      const Text('Select category', style: TextStyle(color: AppColors.muted)),
                items:     widget.damagedItems.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Severity
          const _FieldLabel(label: 'Severity Level'),
          Wrap(spacing: 8, runSpacing: 8,
            children: ChecklistConstants.severityLevels.map((s) {
              final color   = _severityColors[s] ?? AppColors.muted;
              final selected = _severity == s;
              return GestureDetector(
                onTap: () => setState(() => _severity = s),
                child: AnimatedContainer(duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(color: selected ? color : Colors.white, borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: selected ? color : AppColors.border, width: 1.5)),
                  child: Text(s, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.muted)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Description
          const _FieldLabel(label: 'Description'),
          TextField(
            controller: _descCtrl, maxLines: 4,
            decoration: const InputDecoration(hintText: 'Describe the damage or defect in detail...',
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.green, width: 2))),
          ),
          const SizedBox(height: 20),

          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _saveDefect,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text(AppStrings.saveDefect, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, _savedDefects),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.green, side: const BorderSide(color: AppColors.green),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Done — Return to Checklist', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 6),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.4)));
}
