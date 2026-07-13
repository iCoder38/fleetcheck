import 'package:fleetcheck/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/checklist_constants.dart';
import '../../../core/theme/app_responsive.dart';
import '../../../models/inspection_model.dart';
import '../../../routes/app_router.dart';

const _ctaGradient = LinearGradient(
  colors: [AppColors.green, Color(0xFF43A047)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class ChecklistScreen extends StatefulWidget {
  final QrData qrData;
  final String inspectionType; // 'pre_trip' | 'post_trip'

  const ChecklistScreen(
      {super.key, required this.qrData, required this.inspectionType});

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
  bool _showOverview = true;

  bool get _isPreTrip => widget.inspectionType == 'pre_trip';
  ChecklistSection get _section => _sections[_currentSection];
  bool get _isNotesSection => _section.items.isEmpty;
  bool get _isVehicleDamageSection => _section.title == 'Vehicle Damage';
  bool get _isLastSection => _currentSection == _sections.length - 1;
  bool get _isFirstSection => _currentSection == 0;

  int get _totalItemsAll => _sections.fold(0, (sum, s) => sum + s.items.length);
  int get _completedItemsAll => List.generate(_sections.length, (i) => i).fold(
      0,
      (sum, i) =>
          sum +
          (_sections[i].items.isEmpty
              ? 0
              : _responses[i].values.where((v) => v != null).length));

  void _openSection(int index) {
    setState(() {
      _currentSection = index;
      _showOverview = false;
    });
  }

  void _backToOverview() => setState(() => _showOverview = true);

  void _startOrContinue() {
    final firstIncomplete = List.generate(_sections.length, (i) => i)
        .where((i) => !_isSectionComplete(i))
        .toList();
    if (firstIncomplete.isEmpty) {
      _proceedToGps();
    } else {
      _openSection(firstIncomplete.first);
    }
  }

  bool get _notesFilled => _notesCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _sections = _isPreTrip
        ? ChecklistConstants.preTripSections()
        : ChecklistConstants.postTripSections();

    _responses = List.generate(_sections.length, (i) {
      return {for (final item in _sections[i].items) item.id: null};
    });

    _notesCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  bool _isSectionComplete(int sectionIndex) {
    final section = _sections[sectionIndex];
    if (section.items.isEmpty)
      return true; // notes-only sections are always valid
    return _responses[sectionIndex].values.every((v) => v != null);
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
      final damagedItems = _responses[_currentSection]
          .entries
          .where((e) => e.value == 'Yes')
          .map((e) => _section.items.firstWhere((i) => i.id == e.key).label)
          .toList();

      if (damagedItems.isNotEmpty) {
        final newDefects = await context.push<List<DefectReport>>(
          AppRoutes.defectReport,
          extra: {
            'damagedItems': damagedItems,
            'defects': _defects,
            'vehicleNumber': widget.qrData.vehicleNumber
          },
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
      vehicleNumber: widget.qrData.vehicleNumber,
      trailerNumber: widget.qrData.trailerNumber,
      inspectionType: widget.inspectionType,
      responses: responses,
      defects: _defects,
      additionalNotes:
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      gpsLocation: GpsLocation(
        latitude: 0,
        longitude: 0,
        address: '',
        capturedAt: DateTime.now(),
      ),
      startedAt: DateTime.now(),
    );

    context.push(AppRoutes.gpsVerification,
        extra: {'submission': draftSubmission});
  }

  @override
  Widget build(BuildContext context) {
    if (_showOverview) {
      return _OverviewScreen(
        title: _isPreTrip ? AppStrings.preTrip : AppStrings.postTrip,
        sections: _sections,
        completedPerSection: List.generate(
            _sections.length,
            (i) => _sections[i].items.isEmpty
                ? (_notesFilled ? 1 : 0)
                : _responses[i].values.where((v) => v != null).length),
        totalCompleted: _completedItemsAll,
        totalItems: _totalItemsAll,
        onBack: () => context.pop(),
        onSectionTap: _openSection,
        onStart: _startOrContinue,
      );
    }

    final completedInSection = _isNotesSection
        ? (_notesFilled ? 1 : 0)
        : _responses[_currentSection].values.where((v) => v != null).length;
    final totalInSection = _isNotesSection ? 1 : _section.items.length;

    return Scaffold(
      backgroundColor: AppColors.appbg,
      body: Column(
        children: [
          _Header(
            sectionNumber: _currentSection + 1,
            title: _section.title,
            completed: completedInSection,
            total: totalInSection,
            onBack: _backToOverview,
          ),
          Expanded(
            child: _isNotesSection
                ? _buildNotesSection()
                : SingleChildScrollView(
                    padding: EdgeInsets.all(AppResponsive.padding(context, 20)),
                    child: _ChecklistCard(
                      items: _section.items,
                      responses: _responses[_currentSection],
                      onChanged: _setResponse,
                    ),
                  ),
          ),
          // _currentSection==0?_buildNavButtons():SizedBox(),
          _buildNavButtons()
        ],
      ),
    );
  }

  Widget _buildNotesSection() => Padding(
        padding: EdgeInsets.all(AppResponsive.padding(context, 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.additionalNotes,
                style: AppTextStyles.heading3(context, color: AppColors.primary)
                    .copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              AppStrings.notesOptionalHint(AppConstants.notesMaxChars),
              style: AppTextStyles.bodySmall(context),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesCtrl,
              maxLines: 8,
              maxLength: AppConstants.notesMaxChars,
              style: AppTextStyles.body(context, color: Colors.black),
              decoration: const InputDecoration(
                hintText: AppStrings.notesHint,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
        ),
      );

  Widget _buildNavButtons() => Padding(
        padding: EdgeInsets.fromLTRB(
            AppResponsive.padding(context, 20),
            AppResponsive.padding(context, 12),
            AppResponsive.padding(context, 20),
            AppResponsive.padding(context, 20)),
        child: SafeArea(
          top: false,
          child: Row(children: [
            if (!_isFirstSection) ...[
              Expanded(
                child: SizedBox(
                  height: AppResponsive.scale(context, 54),
                  child: OutlinedButton(
                    onPressed: _previous,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.green,
                      padding: EdgeInsets.symmetric(
                          horizontal: AppResponsive.padding(context, 4)),
                      side:
                          const BorderSide(color: AppColors.green, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_rounded,
                            size: 16, color: AppColors.green),
                        SizedBox(width: AppResponsive.spacing(context, 3)),
                        Flexible(
                          child: Text(AppStrings.previousBtn,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.button(context)
                                  .copyWith(color: AppColors.green, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppResponsive.spacing(context, 12)),
            ],
            Expanded(
              flex: 2,
              child: SizedBox(
                height: AppResponsive.scale(context, 54),
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: _ctaGradient,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.green.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          SizedBox(width: AppResponsive.spacing(context, 3)),
                          Flexible(
                            child: Text(  _isLastSection
                                ? AppStrings.finishAndContinue
                                : AppStrings.nextBtn,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.button(context)
                                    .copyWith(color: AppColors.textPrimary, fontSize: 12)),
                          ),
                          SizedBox(width: AppResponsive.spacing(context, 3)),
                          Icon(  _isLastSection
                              ? Icons.check_circle_outline_rounded
                              : Icons.arrow_forward_rounded,
                              size: 16, color: AppColors.textPrimary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      );
}

// ─── Header: gradient panel with section caption/title + fraction pill ─────
class _Header extends StatelessWidget {
  final int sectionNumber;
  final String title;
  final int completed;
  final int total;
  final VoidCallback onBack;

  const _Header({
    required this.sectionNumber,
    required this.title,
    required this.completed,
    required this.total,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              AppResponsive.padding(context, 20),
              AppResponsive.padding(context, 12),
              AppResponsive.padding(context, 20),
              AppResponsive.padding(context, 14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: AppResponsive.padding(context, 4),
                          right: AppResponsive.padding(context, 10)),
                      child: Icon(Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: AppResponsive.scale(context, 22)),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.sectionLabel(sectionNumber),
                            style: AppTextStyles.bodySmall(context,
                                    color: Colors.white.withValues(alpha: 0.6))
                                .copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                        SizedBox(height: AppResponsive.spacing(context, 2)),
                        Text(title,
                            style: AppTextStyles.heading1(context, color: Colors.white)
                                .copyWith(
                                    fontSize: AppResponsive.text(context, 22),
                                    fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  if (total > 0)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppResponsive.padding(context, 12),
                          vertical: AppResponsive.padding(context, 5)),
                      decoration: BoxDecoration(
                        color: AppColors.greenPale.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: AppColors.green, width: 1),
                      ),
                      child: Text(AppStrings.itemsFraction(completed, total),
                          style: AppTextStyles.label(context, color: AppColors.green)
                              .copyWith(fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
              SizedBox(height: AppResponsive.spacing(context, 14)),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF2E9E5B)),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Overview: section list with per-section progress, tap to jump ────────
class _OverviewScreen extends StatelessWidget {
  final String title;
  final List<ChecklistSection> sections;
  final List<int> completedPerSection;
  final int totalCompleted;
  final int totalItems;
  final VoidCallback onBack;
  final ValueChanged<int> onSectionTap;
  final VoidCallback onStart;

  const _OverviewScreen({
    required this.title,
    required this.sections,
    required this.completedPerSection,
    required this.totalCompleted,
    required this.totalItems,
    required this.onBack,
    required this.onSectionTap,
    required this.onStart,
  });

  static const _sectionIcons = {
    'Vehicle Exterior': Icons.directions_car_filled_rounded,
    'Tires & Wheels': Icons.trip_origin_rounded,
    'Engine Compartment': Icons.build_rounded,
    'Brakes': Icons.dangerous_rounded,
    'Safety Equipment': Icons.local_fire_department_rounded,
    'Vehicle Damage': Icons.warning_amber_rounded,
    'Additional Notes': Icons.edit_note_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final overallProgress = totalItems > 0 ? totalCompleted / totalItems : 0.0;
    final overallPct = (overallProgress * 100).round();

    return Scaffold(
      backgroundColor: AppColors.appbg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration:
                const BoxDecoration(gradient: AppColors.primaryGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    AppResponsive.padding(context, 20),
                    AppResponsive.padding(context, 12),
                    AppResponsive.padding(context, 20),
                    AppResponsive.padding(context, 14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: onBack,
                          child: Padding(
                            padding: EdgeInsets.only(
                                top: AppResponsive.padding(context, 4),
                                right: AppResponsive.padding(context, 10)),
                            child: Icon(Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: AppResponsive.scale(context, 22)),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: AppTextStyles.heading1(context, color: Colors.white)
                                      .copyWith(
                                          fontSize: AppResponsive.text(context, 22),
                                          fontWeight: FontWeight.w800)),
                              SizedBox(
                                  height: AppResponsive.spacing(context, 2)),
                              Text(
                                  AppStrings.itemsCheckedCounter(
                                      totalCompleted, totalItems),
                                  style: AppTextStyles.label(context,
                                          color: Colors.white.withValues(alpha: 0.6))
                                      .copyWith(fontWeight: FontWeight.w400)),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: AppResponsive.padding(context, 12),
                              vertical: AppResponsive.padding(context, 5)),
                          decoration: BoxDecoration(
                            color: AppColors.greenPale.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(99),
                            border:
                                Border.all(color: AppColors.green, width: 1),
                          ),
                          child: Text(AppStrings.percentComplete(overallPct),
                              style: AppTextStyles.label(context, color: AppColors.green)
                                  .copyWith(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    SizedBox(height: AppResponsive.spacing(context, 14)),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: overallProgress,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF2E9E5B)),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(AppResponsive.padding(context, 20)),
              itemCount: sections.length,
              itemBuilder: (_, i) {
                final section = sections[i];
                final isNotes = section.items.isEmpty;
                final completed = completedPerSection[i];
                final total = isNotes ? 1 : section.items.length;
                final isComplete = completed == total;
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: AppResponsive.spacing(context, 14)),
                  child: _SectionRow(
                    number: i + 1,
                    icon:
                        _sectionIcons[section.title] ?? Icons.checklist_rounded,
                    title: section.title,
                    caption: isNotes
                        ? (isComplete ? AppStrings.allSetLabel : AppStrings.notesPendingLabel)
                        : AppStrings.itemsFraction(completed, total),
                    progress: total > 0 ? completed / total : 0.0,
                    isComplete: isComplete,
                    onTap: () => onSectionTap(i),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  final int number;
  final IconData icon;
  final String title;
  final String caption;
  final double progress;
  final bool isComplete;
  final VoidCallback onTap;

  const _SectionRow({
    required this.number,
    required this.icon,
    required this.title,
    required this.caption,
    required this.progress,
    required this.isComplete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppResponsive.padding(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: AppResponsive.scale(context, 44),
              height: AppResponsive.scale(context, 44),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: AppColors.green,
                  size: AppResponsive.scale(context, 22)),
            ),
            SizedBox(width: AppResponsive.spacing(context, 14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$number. $title',
                      style: AppTextStyles.button(context, color: AppColors.primary)
                          .copyWith(fontWeight: FontWeight.w800)),
                  SizedBox(height: AppResponsive.spacing(context, 6)),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor:
                                AppColors.border.withValues(alpha: 0.4),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.green),
                            minHeight: 5,
                          ),
                        ),
                      ),
                      SizedBox(width: AppResponsive.spacing(context, 8)),
                      Text(caption,
                          style: AppTextStyles.bodySmall(context, color: AppColors.green)
                              .copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: AppResponsive.spacing(context, 10)),
            Container(
              width: AppResponsive.scale(context, 30),
              height: AppResponsive.scale(context, 30),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isComplete
                    ? AppColors.green
                    : AppColors.border.withValues(alpha: 0.3),
              ),
              child: Icon(Icons.check_rounded,
                  size: AppResponsive.scale(context, 18),
                  color: isComplete ? Colors.white : AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Checklist card: single white card, one divided row per item ──────────
class _ChecklistCard extends StatelessWidget {
  final List<ChecklistItem> items;
  final Map<String, String?> responses;
  final void Function(String itemId, String option) onChanged;

  const _ChecklistCard(
      {required this.items, required this.responses, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++)
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: AppResponsive.padding(context, 18),
                  vertical: AppResponsive.padding(context, 16)),
              decoration: BoxDecoration(
                border: i == items.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: AppColors.divider)),
              ),
              child: _ChecklistItemRow(
                item: items[i],
                currentValue: responses[items[i].id],
                onChanged: (value) => onChanged(items[i].id, value),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChecklistItemRow extends StatelessWidget {
  final ChecklistItem item;
  final String? currentValue;
  final ValueChanged<String> onChanged;

  const _ChecklistItemRow({
    required this.item,
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(item.label,
              style: AppTextStyles.label(context, color: AppColors.primary)
                  .copyWith(fontWeight: FontWeight.w600)),
        ),
        SizedBox(width: AppResponsive.spacing(context, 8)),
        Row(
          children: [
            for (int i = 0; i < item.options.length; i++) ...[
              if (i > 0) SizedBox(width: AppResponsive.spacing(context, 8)),
              _OptionPill(
                label: item.options[i],
                selected: currentValue == item.options[i],
                onTap: () => onChanged(item.options[i]),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _OptionPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionPill(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
              horizontal: AppResponsive.padding(context, 10),
              vertical: AppResponsive.padding(context, 5)),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.greenPale.withValues(alpha: 0.5)
                : AppColors.appbg,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
                color: selected ? AppColors.green : AppColors.border,
                width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon(Icons.check_rounded,
              //     size: 14, color: AppColors.green),
              // SizedBox(width: AppResponsive.spacing(context, 4)),
              Text(label,
                  style: AppTextStyles.label(context,
                          color: selected ? AppColors.green : AppColors.textSecondary)
                      .copyWith(fontWeight: FontWeight.w600,fontSize:AppResponsive.text(context, 11) )),
            ],
          ),
        ),
      );
}
