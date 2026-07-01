import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/checklist_constants.dart';
import '../../../models/inspection_model.dart';
import '../../../routes/app_router.dart';

class ChecklistScreen extends StatefulWidget {
  final QrData qrData;
  final String inspectionType; // 'pre_trip' | 'post_trip'

  const ChecklistScreen({super.key, required this.qrData, required this.inspectionType});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  late final List<ChecklistSection> _sections;

  // sectionIndex -> itemId -> selected option string (e.g. 'Good','Defective','Available',...)
  late final List<Map<String, String?>> _responses;

  final List<DefectReport> _defects = [];
  final _notesCtrl = TextEditingController();

  int _currentSection = 0;

  bool get _isPreTrip => widget.inspectionType == 'pre_trip';
  ChecklistSection get _section => _sections[_currentSection];
  bool get _isNotesSection => _section.items.isEmpty;
  bool get _isVehicleDamageSection => _section.title == 'Vehicle Damage';
  bool get _isLastSection => _currentSection == _sections.length - 1;
  bool get _isFirstSection => _currentSection == 0;

  @override
  void initState() {
    super.initState();
    _sections = _isPreTrip
        ? ChecklistConstants.preTripSections()
        : ChecklistConstants.postTripSections();

    _responses = List.generate(_sections.length, (i) {
      return {for (final item in _sections[i].items) item.id: null};
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  bool _isSectionComplete(int sectionIndex) {
    final section = _sections[sectionIndex];
    if (section.items.isEmpty) return true; // notes-only sections are always valid
    return _responses[sectionIndex].values.every((v) => v != null);
  }

  double get _overallProgress {
    int completed = 0;
    for (int i = 0; i < _sections.length; i++) {
      if (_isSectionComplete(i)) completed++;
    }
    return completed / _sections.length;
  }

  void _setResponse(String itemId, String option) {
    setState(() => _responses[_currentSection][itemId] = option);
  }

  Future<void> _next() async {
    if (!_isNotesSection && !_isSectionComplete(_currentSection)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(AppStrings.allFieldsRequired),
        backgroundColor: AppColors.amber,
      ));
      return;
    }

    // If this is the Vehicle Damage section and any item was marked "Yes",
    // route through the Defect Report screen before continuing.
    if (_isVehicleDamageSection) {
      final damagedItems = _responses[_currentSection].entries
          .where((e) => e.value == 'Yes')
          .map((e) => _section.items.firstWhere((i) => i.id == e.key).label)
          .toList();

      if (damagedItems.isNotEmpty) {
        final newDefects = await context.push<List<DefectReport>>(
          AppRoutes.defectReport,
          extra: {'damagedItems': damagedItems, 'defects': _defects},
        );
        if (newDefects != null) {
          _defects
            ..clear()
            ..addAll(newDefects);
        }
      }
    }

    if (_isLastSection) {
      _proceedToGps();
    } else {
      setState(() => _currentSection++);
    }
  }

  void _previous() {
    if (!_isFirstSection) setState(() => _currentSection--);
  }

  void _proceedToGps() {
    final responses = <ChecklistResponse>[];
    for (int si = 0; si < _sections.length; si++) {
      for (final item in _sections[si].items) {
        final selected = _responses[si][item.id];
        if (selected != null) {
          responses.add(ChecklistResponse(
            itemId: item.id,
            sectionId: _sections[si].title,
            itemLabel: item.label,
            selectedOption: selected,
          ));
        }
      }
    }

    // GPS hasn't been captured yet — GpsVerificationScreen fills in the
    // real location and rebuilds the final InspectionSubmission before
    // continuing to the review screen.
    final draftSubmission = InspectionSubmission(
      qrCodeString: widget.qrData.qrCodeString,
      inspectionType: widget.inspectionType,
      responses: responses,
      defects: _defects,
      additionalNotes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      gpsLocation: GpsLocation(
        latitude: 0,
        longitude: 0,
        address: '',
        capturedAt: DateTime.now(),
      ),
      startedAt: DateTime.now(),
    );

    context.push(AppRoutes.gpsVerification, extra: {'submission': draftSubmission});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isPreTrip ? AppStrings.preTrip : AppStrings.postTrip),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _overallProgress,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            minHeight: 4,
          ),
        ),
      ),
      body: Column(
        children: [
          // Section header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.goodBg,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'Section ${_currentSection + 1} of ${_sections.length}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(_overallProgress * 100).toInt()}% Complete',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(_section.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary)),
                const SizedBox(height: 8),
                _SectionProgressBar(
                  completed: _isNotesSection ? 1 : _responses[_currentSection].values.where((v) => v != null).length,
                  total: _section.items.length,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _isNotesSection
                ? _buildNotesSection()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _section.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final item = _section.items[i];
                      return _ChecklistItemCard(
                        item: item,
                        currentValue: _responses[_currentSection][item.id],
                        onChanged: (value) => _setResponse(item.id, value),
                      );
                    },
                  ),
          ),

          _buildNavButtons(),
        ],
      ),
    );
  }

  Widget _buildNotesSection() => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(AppStrings.additionalNotes, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
        const SizedBox(height: 8),
        Text(
          'Optional — up to ${AppConstants.notesMaxChars} characters',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _notesCtrl,
          maxLines: 8,
          maxLength: AppConstants.notesMaxChars,
          decoration: const InputDecoration(
            hintText: 'Add any additional notes or observations here...',
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    ),
  );

  Widget _buildNavButtons() => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
    decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
    child: SafeArea(
      top: false,
      child: Row(children: [
        if (!_isFirstSection) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: _previous,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.border),
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(AppStrings.previousBtn, style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              _isLastSection ? 'Finish & Continue' : AppStrings.nextBtn,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ]),
    ),
  );
}

// ─── Checklist Item Card ───────────────────────────────────
class _ChecklistItemCard extends StatelessWidget {
  final ChecklistItem item;
  final String? currentValue;
  final ValueChanged<String> onChanged;

  const _ChecklistItemCard({
    required this.item,
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final goodOption = item.options.first;  // 'Good' | 'Available'
    final badOption  = item.options.last;   // 'Defective' | 'Not Available' | 'Yes'/'No' handled via order in constants

    final selectedGood = currentValue == goodOption;
    final selectedBad  = currentValue == badOption;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: currentValue != null ? AppColors.secondary.withOpacity(0.3) : AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: currentValue != null ? AppColors.goodBg : AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.check_circle_outline_rounded,
            color: currentValue != null ? AppColors.secondary : AppColors.textSecondary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(item.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ),
        const SizedBox(width: 8),
        Row(children: [
          _OptionButton(label: goodOption, selected: selectedGood, color: AppColors.secondary, onTap: () => onChanged(goodOption)),
          const SizedBox(width: 6),
          _OptionButton(label: badOption, selected: selectedBad, color: AppColors.danger, onTap: () => onChanged(badOption)),
        ]),
      ]),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _OptionButton({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? color : AppColors.border, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textSecondary),
      ),
    ),
  );
}

class _SectionProgressBar extends StatelessWidget {
  final int completed;
  final int total;

  const _SectionProgressBar({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? completed / total : 0,
            backgroundColor: AppColors.background,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text('$completed / $total items checked', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
