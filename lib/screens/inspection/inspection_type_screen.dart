import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/inspection_model.dart';
import '../../routes/app_router.dart';

const _ctaGradient = LinearGradient(
  colors: [AppColors.green, Color(0xFF43A047)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const _sunGradient = LinearGradient(
  colors: [Color(0xFFFF7A45), Color(0xFFFFC24B)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const _moonGradient = LinearGradient(
  colors: [Color(0xFF5B4FCF), Color(0xFF2E2A6B)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Shows scanned vehicle details + lets driver choose Pre-Trip or Post-Trip.
/// If the admin pre-assigned an inspection job for this QR, the type is
/// auto-selected and a job-assignment banner is shown.
class InspectionTypeScreen extends StatefulWidget {
  final QrData qrData;
  const InspectionTypeScreen({super.key, required this.qrData});

  @override
  State<InspectionTypeScreen> createState() => _InspectionTypeScreenState();
}

class _InspectionTypeScreenState extends State<InspectionTypeScreen> {
  late String? _selectedType;

  @override
  void initState() {
    super.initState();
    // If the admin assigned a specific inspection type for this QR + driver,
    // pre-select it so the driver can proceed immediately without manual selection.
    _selectedType = widget.qrData.inspectionType;
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.qrData;
    final hasJob = q.hasAssignedJob;

    return Scaffold(
      backgroundColor: AppColors.appbg,
      body: Column(
        children: [
          _HeroHeader(qrData: q, hasJob: hasJob, selectedType: _selectedType),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Choose inspection type ───────────────────────
                  Text(
                    (hasJob ? AppStrings.assignedInspectionType : AppStrings.chooseInspectionType)
                        .toUpperCase(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 14),

                  _TypeCard(
                    isSelected:   _selectedType == 'pre_trip',
                    icon:         Icons.wb_sunny_rounded,
                    iconGradient: _sunGradient,
                    title:        AppStrings.preTrip,
                    subtitle:     AppStrings.preTripCardSubtitle,
                    // Disable manual selection if admin assigned a specific type
                    onTap: hasJob ? null : () => setState(() => _selectedType = 'pre_trip'),
                  ),
                  const SizedBox(height: 12),

                  _TypeCard(
                    isSelected:   _selectedType == 'post_trip',
                    icon:         Icons.nights_stay_rounded,
                    iconGradient: _moonGradient,
                    title:        AppStrings.postTrip,
                    subtitle:     AppStrings.postTripCardSubtitle,
                    onTap: hasJob ? null : () => setState(() => _selectedType = 'post_trip'),
                  ),

                  // Validation hint (only shown in free-choice mode)
                  if (!hasJob && _selectedType == null) ...[
                    const SizedBox(height: 14),
                    const Center(
                      child: Text(
                        AppStrings.selectTypeHint,
                        style: TextStyle(fontSize: 12, color: AppColors.amber, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Bottom: Start Inspection ──────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
            color: AppColors.appbg,
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _selectedType == null
                    ? null
                    : () => context.push(
                          AppRoutes.truckInfo,
                          extra: {
                            'qrData': widget.qrData,
                            'inspectionType': _selectedType,
                          },
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  disabledBackgroundColor: Colors.transparent,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: _selectedType == null ? null : _ctaGradient,
                    color: _selectedType == null ? AppColors.border : null,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: _selectedType == null
                        ? []
                        : [BoxShadow(color: AppColors.green.withValues(alpha: 0.35),
                            blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppStrings.startInspection,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                                color: _selectedType == null ? AppColors.textSecondary : Colors.white)),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20,
                            color: _selectedType == null ? AppColors.textSecondary : Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero header: dark gradient panel with title, verified pill,
// vehicle/driver info grid and (optionally) the assigned-job banner ──────
class _HeroHeader extends StatelessWidget {
  final QrData qrData;
  final bool hasJob;
  final String? selectedType;

  const _HeroHeader({required this.qrData, required this.hasJob, required this.selectedType});

  @override
  Widget build(BuildContext context) {
    final q = qrData;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: ClipRect(
        child: Stack(
          children: [
            // Decorative soft glow circles
            Positioned(top: -40, right: -30, child: _glowCircle(140)),
            Positioned(bottom: -60, left: -50, child: _glowCircle(180)),

            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(AppStrings.inspectionTypeAppBarTitle,
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                                    color: Colors.white, height: 1.2)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const _VerifiedPill(),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Vehicle & driver info grid (translucent card)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        children: [
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(child: _InfoStat(AppStrings.labelVehicleNumber, q.vehicleNumber)),
                            const SizedBox(width: 16),
                            Expanded(child: _InfoStat(AppStrings.labelTrailerNumber, q.trailerNumber ?? '—')),
                          ]),
                          const SizedBox(height: 16),
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(child: _InfoStat(AppStrings.labelDriverName, q.driverName)),
                            Expanded(
                              child: _InfoStat(AppStrings.labelDateTime,
                                  DateFormat('MM/dd/yyyy hh:mm a').format(DateTime.now())),
                            ),
                          ]),
                          const SizedBox(height: 16),
                          const Row(children: [
                            Expanded(child: _InfoStat(AppStrings.labelGpsLocation, AppStrings.fetchingEllipsis)),
                          ]),
                        ],
                      ),
                    ),

                    // Assigned job banner (shown when admin pre-assigned a job)
                    if (hasJob) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          const Icon(Icons.assignment_turned_in_rounded, color: AppColors.secondary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppStrings.assignedJobLabel.toUpperCase(),
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                      color: Colors.white.withValues(alpha: 0.6), letterSpacing: 0.5)),
                              const SizedBox(height: 2),
                              Text(q.pendingInspectionRef ?? '—',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                                      color: Colors.white, fontFamily: 'monospace')),
                            ],
                          )),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              selectedType == 'pre_trip' ? AppStrings.preTripShort : AppStrings.postTripShort,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary),
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glowCircle(double size) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.035)),
  );
}

class _VerifiedPill extends StatelessWidget {
  const _VerifiedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.greenPale,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6,
            decoration: const BoxDecoration(color: AppColors.goodText, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        const Text(AppStrings.verifiedLabel,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.goodText)),
      ]),
    );
  }
}

class _InfoStat extends StatelessWidget {
  final String label;
  final String value;
  const _InfoStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.55), letterSpacing: 0.6)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
      ],
    );
  }
}

// ─── Type selection card ─────────────────────────────────────
class _TypeCard extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final Gradient iconGradient;
  final String title, subtitle;
  final VoidCallback? onTap; // nullable — null means admin-locked, not tappable

  const _TypeCard({
    required this.isSelected,
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        isSelected
              ? AppColors.success.withValues(alpha: 0.07)
              : locked
                  ? AppColors.appbg
                  : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(
            color: isSelected ? AppColors.success : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.success.withValues(alpha: 0.15), blurRadius: 16)]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient:     locked && !isSelected ? null : iconGradient,
                color:        locked && !isSelected ? AppColors.border.withValues(alpha: 0.4) : null,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                        color: isSelected
                            ? AppColors.success
                            : locked
                                ? AppColors.textSecondary
                                : AppColors.primary)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ),
            const SizedBox(width: 8),
            if (locked && isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text('Assigned',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)),
              )
            else if (!locked)
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected ? AppColors.success : AppColors.textSecondary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
