import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/inspection_model.dart';
import '../../routes/app_router.dart';

/// Shows scanned vehicle details + lets driver choose Pre-Trip or Post-Trip.
class InspectionTypeScreen extends StatefulWidget {
  final QrData qrData;
  const InspectionTypeScreen({super.key, required this.qrData});

  @override
  State<InspectionTypeScreen> createState() => _InspectionTypeScreenState();
}

class _InspectionTypeScreenState extends State<InspectionTypeScreen> {
  // null = nothing selected yet
  String? _selectedType; // 'pre_trip' | 'post_trip'

  @override
  Widget build(BuildContext context) {
    final q = widget.qrData;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Inspection Type')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Verified header ──────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: AppColors.greenGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_rounded, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text('QR Code Verified',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Scanned vehicle details ──────────────────────
                  _InfoCard(
                    title: 'Vehicle & Driver Details',
                    icon: Icons.local_shipping_rounded,
                    rows: [
                      _Row('Vehicle Number', q.vehicleNumber),
                      _Row('Trailer Number', q.trailerNumber ?? '—'),
                      _Row('Driver Name',    q.driverName),
                      _Row('Date & Time',    DateFormat('MM/dd/yyyy hh:mm a').format(DateTime.now())),
                      _Row('GPS Location',   'Fetching…'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Choose inspection type ───────────────────────
                  const Text(
                    'Choose Inspection Type',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),

                  _TypeCard(
                    isSelected: _selectedType == 'pre_trip',
                    icon:       Icons.wb_sunny_rounded,
                    iconColor:  AppColors.secondary,
                    title:      AppStrings.preTrip,
                    subtitle:   'Inspect vehicle before starting your Trip',
                    onTap:      () => setState(() => _selectedType = 'pre_trip'),
                  ),
                  const SizedBox(height: 12),

                  _TypeCard(
                    isSelected: _selectedType == 'post_trip',
                    icon:       Icons.nights_stay_rounded,
                    iconColor:  AppColors.primary,
                    title:      AppStrings.postTrip,
                    subtitle:   'Inspect vehicle after completing your Trip',
                    onTap:      () => setState(() => _selectedType = 'post_trip'),
                  ),

                  // Validation hint
                  if (_selectedType == null) ...[
                    const SizedBox(height: 14),
                    const Center(
                      child: Text(
                        '⚠  Please select an inspection type to continue.',
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
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _selectedType == null
                    ? null
                    : () => context.push(
                          AppRoutes.truckInfo,
                          extra: {'qrData': widget.qrData, 'inspectionType': _selectedType},
                        ),
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: AppColors.border,
                  disabledForegroundColor: AppColors.textSecondary,
                ),
                child: const Text(
                  AppStrings.startInspection,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Local widgets ────────────────────────────────────────

class _TypeCard extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final VoidCallback onTap;

  const _TypeCard({
    required this.isSelected,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:        isSelected ? iconColor.withOpacity(0.07) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(
            color: isSelected ? iconColor : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: iconColor.withOpacity(0.12), blurRadius: 14)]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color:         iconColor.withOpacity(0.1),
                borderRadius:  BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                        color: isSelected ? iconColor : AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? iconColor : AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_Row> rows;
  const _InfoCard({required this.title, required this.icon, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(children: [
              Icon(icon, color: AppColors.primary, size: 17),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary)),
            ]),
          ),
          // Rows
          ...rows.map((r) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              border: rows.last != r
                  ? const Border(bottom: BorderSide(color: AppColors.divider))
                  : null,
            ),
            child: Row(children: [
              Expanded(flex: 2, child: Text(r.label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
              Expanded(flex: 3, child: Text(r.value, textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
            ]),
          )),
        ],
      ),
    );
  }
}

class _Row {
  final String label, value;
  const _Row(this.label, this.value);
}
