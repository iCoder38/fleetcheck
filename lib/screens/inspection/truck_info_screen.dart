import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/inspection_model.dart';
import '../../routes/app_router.dart';

const _ctaGradient = LinearGradient(
  colors: [AppColors.green, Color(0xFF43A047)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const _avatarGradient = LinearGradient(
  colors: [Color(0xFF1E9E8F), Color(0xFF1B6FB8)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

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
      backgroundColor: AppColors.appbg,
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: SafeArea(
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
                          child: const Padding(
                            padding: EdgeInsets.only(top: 4, right: 14),
                            child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(AppStrings.truckInformation,
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                              const SizedBox(height: 4),
                              Text(AppStrings.qrCodeVerified,
                                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.65))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        const _VerifiedPill(),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Inspection type pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPreTrip ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
                            size: 15,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isPreTrip ? AppStrings.preTrip : AppStrings.postTrip,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Details Card
                  _InfoCard(
                    icon: Icons.local_shipping_rounded,
                    title: AppStrings.vehicleDetails,
                    rows: [
                      _InfoRow(AppStrings.labelTruckNumber,    qrData.vehicleNumber),
                      _InfoRow(AppStrings.labelVinNumber,      qrData.vin ?? '—'),
                      _InfoRow(AppStrings.labelTrailerNumber,  qrData.trailerNumber ?? '—'),
                      _InfoRow(AppStrings.labelLicensePlate,   qrData.plateNumber ?? '—'),
                      _InfoRow(AppStrings.labelFleetNumber,    qrData.fleetNumber ?? '—'),
                      _InfoRow(AppStrings.labelCompanyName,    qrData.companyName),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Driver Verification Card
                  _DriverCard(
                    name: qrData.driverName,
                    employeeId: qrData.employeeId,
                  ),
                  const SizedBox(height: 14),

                  // Info note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.amber, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppStrings.autoFilledNote,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => context.push(
                        AppRoutes.checklist,
                        extra: {'qrData': qrData, 'inspectionType': inspectionType},
                      ),
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
                            BoxShadow(color: AppColors.green.withValues(alpha: 0.35),
                                blurRadius: 16, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(AppStrings.continueBtn,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared UI components (used by multiple inspection screens) ────────────

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

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_InfoRow> rows;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.textSecondary,
                letterSpacing: 0.6,
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
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

class _DriverCard extends StatelessWidget {
  final String name;
  final String employeeId;
  const _DriverCard({required this.name, required this.employeeId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              AppStrings.driverVerification.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.textSecondary,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: const BoxDecoration(gradient: _avatarGradient, shape: BoxShape.circle),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      const SizedBox(height: 2),
                      Text('${AppStrings.labelEmployeeId}: $employeeId',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, size: 13, color: AppColors.success),
                      SizedBox(width: 4),
                      Text(AppStrings.verifiedLabel,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
