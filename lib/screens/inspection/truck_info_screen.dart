import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/inspection_model.dart';
import '../../routes/app_router.dart';

class TruckInfoScreen extends StatelessWidget {
  final QrData qrData;
  final String inspectionType; // 'pre_trip' | 'post_trip'

  const TruckInfoScreen({
    super.key,
    required this.qrData,
    required this.inspectionType,
  });

  @override
  Widget build(BuildContext context) {
    final isPreTrip = inspectionType == 'pre_trip';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.truckInformation),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verified badge
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
                        Text(
                          'QR Code Verified',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Inspection type pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isPreTrip
                          ? AppColors.secondary.withOpacity(0.1)
                          : AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPreTrip
                            ? AppColors.secondary.withOpacity(0.4)
                            : AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPreTrip ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
                          size: 16,
                          color: isPreTrip ? AppColors.secondary : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isPreTrip ? AppStrings.preTrip : AppStrings.postTrip,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isPreTrip ? AppColors.secondary : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Vehicle Details Card
                  _InfoCard(
                    icon: Icons.local_shipping_rounded,
                    title: 'Vehicle Details',
                    rows: [
                      _InfoRow('Truck Number',    qrData.vehicleNumber),
                      _InfoRow('VIN Number',      qrData.vin ?? '—'),
                      _InfoRow('Trailer Number',  qrData.trailerNumber ?? '—'),
                      _InfoRow('License Plate',   qrData.plateNumber ?? '—'),
                      _InfoRow('Fleet Number',    qrData.fleetNumber ?? '—'),
                      _InfoRow('Company Name',    qrData.companyName),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Driver Verification Card
                  _InfoCard(
                    icon: Icons.badge_rounded,
                    title: 'Driver Verification',
                    iconColor: AppColors.secondary,
                    rows: [
                      _InfoRow('Driver Name',  qrData.driverName),
                      _InfoRow('Employee ID',  qrData.employeeId),
                    ],
                    badge: _VerifiedBadge(),
                  ),
                  const SizedBox(height: 8),

                  // Info note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.amber.withOpacity(0.3)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.amber, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'All details are automatically filled from the scanned QR Code. Please verify before continuing.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom: Continue button
          _BottomBar(
            label: AppStrings.continueBtn,
            onTap: () => context.push(
              AppRoutes.checklist,
              extra: {'qrData': qrData, 'inspectionType': inspectionType},
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared UI components (used by multiple inspection screens) ────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final List<_InfoRow> rows;
  final Widget? badge;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.rows,
    this.iconColor,
    this.badge,
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
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor ?? AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: iconColor ?? AppColors.primary,
                  ),
                ),
                if (badge != null) ...[
                  const Spacer(),
                  badge!,
                ],
              ],
            ),
          ),
          // Rows
          ...rows.map((r) => _buildRow(r, rows.last == r)),
        ],
      ),
    );
  }

  Widget _buildRow(_InfoRow row, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              row.label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
}

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 13, color: AppColors.secondary),
          SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BottomBar({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
