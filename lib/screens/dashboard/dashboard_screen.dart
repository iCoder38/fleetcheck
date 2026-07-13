import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/driver_model.dart';
import '../../models/inspection_model.dart';
import '../../routes/app_router.dart';
import '../../core/theme/app_responsive.dart';
import '../../core/theme/app_text_styles.dart';

// Bright accent green used for this screen's positive/active accents
// (View All link, Pre-Trip stat, active nav state), matching the brand
// green used on the login screen rather than the app's amber CTA color.
const _brightGreen = Color(0xFF2E9E5B);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _scanGradient = LinearGradient(
    colors: [Color(0xFF1E4D3D), Color(0xFF1A6B4F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return const Scaffold(
            backgroundColor: AppColors.appbg,
            body: Center(
                child: CircularProgressIndicator(color: AppColors.secondary)),
          );
        }
        final loaded = state as DashboardLoaded;
        return Scaffold(
          backgroundColor: AppColors.appbg,
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<DashboardBloc>().add(DashboardLoadRequested());
              await context
                  .read<DashboardBloc>()
                  .stream
                  .firstWhere((s) => s is DashboardLoaded);
            },
            color: AppColors.secondary,
            child: Column(
              children: [
                _buildHeader(
                    context, loaded.driver, loaded.recent.isNotEmpty),
                Expanded(child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildStats(loaded.stats)),
                    SliverToBoxAdapter(child: _buildRecentActivity(loaded.recent)),
                    SliverToBoxAdapter(
                        child: SizedBox(
                            height: AppResponsive.spacing(context, 100))),
                  ],
                ),)
              ],
            )
          ),
        );
      },
    );
  }

  // ─── Header: profile row + date + embedded scan card ─────
  Widget _buildHeader(
      BuildContext context, DriverModel? driver, bool hasUnread) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppResponsive.padding(context, 20),
        MediaQuery.of(context).padding.top + AppResponsive.padding(context, 16),
        AppResponsive.padding(context, 20),
        AppResponsive.padding(context, 20),
      ),
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with online indicator
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: AppResponsive.scale(context, 50),
                    height: AppResponsive.scale(context, 50),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.greenGradient,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4), width: 2),
                    ),
                    child: driver?.photoUrl != null
                        ? ClipOval(
                            child: Image.network(driver!.photoUrl!,
                                fit: BoxFit.cover))
                        : Icon(Icons.person_rounded,
                            color: Colors.white,
                            size: AppResponsive.scale(context, 28)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: AppResponsive.scale(context, 12),
                      height: AppResponsive.scale(context, 12),
                      decoration: BoxDecoration(
                        color: _brightGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: AppResponsive.spacing(context, 12)),

              // Name + ID
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.welcomeBackLabel.toUpperCase(),
                          style: TextStyle(
                              fontSize: AppResponsive.text(context, 11),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: Colors.white.withValues(alpha: 0.6))),
                      Text(driver?.fullName ?? AppStrings.defaultDriverName,
                          style: AppTextStyles.heading2(context,
                              color: Colors.white)),
                      SizedBox(height: AppResponsive.spacing(context, 4)),
                      _Pill(AppStrings.empIdLabel(driver?.employeeId ?? '—'),
                          color: Colors.white.withValues(alpha: 0.15)),
                    ]),
              ),

              // Notification bell
              GestureDetector(
                onTap: () => context.push(AppRoutes.notifications),
                child: Stack(clipBehavior: Clip.none, children: [
                  Container(
                    padding: EdgeInsets.all(AppResponsive.padding(context, 8)),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: AppResponsive.scale(context, 22)),
                  ),
                  if (hasUnread)
                    Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                            width: AppResponsive.scale(context, 10),
                            height: AppResponsive.scale(context, 10),
                            decoration: BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.primary, width: 1.5)))),
                ]),
              ),
            ],
          ),
          SizedBox(height: AppResponsive.spacing(context, 14)),
          // Date & time row
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
                '${DateFormat('MMM d, yyyy').format(DateTime.now())} | '
                '${DateFormat('hh:mm a').format(DateTime.now())}',
                style: AppTextStyles.bodySmall(context,
                    color: Colors.white.withValues(alpha: 0.55))),
          ),
          SizedBox(height: AppResponsive.spacing(context, 18)),

          // ── Embedded "Start Inspection / Scan QR Code" card ──
          GestureDetector(
            onTap: () => context.push(AppRoutes.qrScanner),
            child: Container(
              padding: EdgeInsets.all(AppResponsive.padding(context, 16)),
              decoration: BoxDecoration(
                gradient: _scanGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(children: [
                Container(
                  width: AppResponsive.scale(context, 52),
                  height: AppResponsive.scale(context, 52),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: AppResponsive.scale(context, 26)),
                ),
                SizedBox(width: AppResponsive.spacing(context, 14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.startInspection.toUpperCase(),
                          style: TextStyle(
                              fontSize: AppResponsive.text(context, 10),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: Colors.white.withValues(alpha: 0.6))),
                      Text(AppStrings.scanQrCode,
                          style: AppTextStyles.heading3(context,
                              color: Colors.white)),
                      SizedBox(height: AppResponsive.spacing(context, 2)),
                      Text(AppStrings.scanQrSubtitle,
                          style: AppTextStyles.bodySmall(context,
                              color: Colors.white.withValues(alpha: 0.55))),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(AppResponsive.padding(context, 10)),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: AppResponsive.scale(context, 18)),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats 4-box grid ────────────────────────────────────
  Widget _buildStats(DriverStats s) {
    final boxes = [
      _StatBox(
          label: AppStrings.totalInspectionsLabel,
          value: s.totalAssigned,
          color: AppColors.info,
          icon: Icons.bar_chart_rounded),
      _StatBox(
          label: AppStrings.preTripShort,
          value: s.preTripCompleted,
          color: _brightGreen,
          icon: Icons.wb_sunny_rounded),
      _StatBox(
          label: AppStrings.postTripShort,
          value: s.postTripCompleted,
          color: const Color(0xFF7C3AED),
          icon: Icons.nights_stay_rounded),
      _StatBox(
          label: AppStrings.pendingInspections,
          value: s.pending,
          color: AppColors.amber,
          icon: Icons.hourglass_bottom_rounded),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(AppResponsive.padding(context, 20),
          AppResponsive.padding(context, 20),
          AppResponsive.padding(context, 20), 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.quickStats,
                  style: AppTextStyles.heading3(context,
                      color: AppColors.primary)),
              GestureDetector(
                onTap: () => context.push(AppRoutes.history),
                child: Row(children: [
                  Text(AppStrings.viewAll,
                      style: AppTextStyles.label(context, color: _brightGreen)),
                  Icon(Icons.chevron_right_rounded,
                      color: _brightGreen,
                      size: AppResponsive.scale(context, 18)),
                ]),
              ),
            ],
          ),
          SizedBox(height: AppResponsive.spacing(context, 12)),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: AppResponsive.spacing(context, 12),
            mainAxisSpacing: AppResponsive.spacing(context, 12),
            childAspectRatio: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: boxes.map((b) => _StatCard(box: b)).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Recent activity ─────────────────────────────────────
  Widget _buildRecentActivity(List<ActivityItem> recent) => Padding(
        padding: EdgeInsets.fromLTRB(AppResponsive.padding(context, 20),
            AppResponsive.padding(context, 20),
            AppResponsive.padding(context, 20), 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.recentActivity,
                    style: AppTextStyles.heading3(context,
                        color: AppColors.primary)),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.history),
                  child: Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                      size: AppResponsive.scale(context, 20)),
                ),
              ],
            ),
            SizedBox(height: AppResponsive.spacing(context, 8)),
            if (recent.isEmpty)
              Container(
                padding: EdgeInsets.all(AppResponsive.padding(context, 24)),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3)),
                    ]),
                child: Center(
                  child: Column(children: [
                    Icon(Icons.inbox_outlined,
                        size: AppResponsive.scale(context, 36),
                        color: AppColors.textSecondary),
                    SizedBox(height: AppResponsive.spacing(context, 8)),
                    Text(AppStrings.noRecentInspections,
                        style: AppTextStyles.body(context,
                            color: AppColors.textSecondary)),
                  ]),
                ),
              )
            else
              ...(recent.map((item) => _ActivityCard(item: item))),
          ],
        ),
      );
}

// ─── Helper: relative "time ago" formatting ───────────────
String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return AppStrings.justNow;
  if (diff.inMinutes < 60) return AppStrings.agoMinutes(diff.inMinutes);
  if (diff.inHours < 24) return AppStrings.agoHours(diff.inHours);
  return AppStrings.agoDays(diff.inDays);
}

// ─── Helper data classes ──────────────────────────────────

class _StatBox {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const _StatBox(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});
}

// ─── Sub-widgets ──────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill(this.text, {required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: AppResponsive.padding(context, 10),
            vertical: AppResponsive.padding(context, 3)),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(99)),
        child: Text(text,
            style: TextStyle(
                fontSize: AppResponsive.text(context, 11),
                color: Colors.white,
                fontWeight: FontWeight.w700)),
      );
}

class _StatCard extends StatelessWidget {
  final _StatBox box;
  const _StatCard({super.key, required this.box});
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(AppResponsive.padding(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
                width: AppResponsive.scale(context, 40),
                height: AppResponsive.scale(context, 40),
                decoration: BoxDecoration(
                    color: box.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(box.icon,
                    color: box.color, size: AppResponsive.scale(context, 20))),
            SizedBox(width: AppResponsive.spacing(context, 10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${box.value}',
                      style: TextStyle(
                          fontSize: AppResponsive.text(context, 24),
                          fontWeight: FontWeight.w800,
                          color: box.color)),
                  Text(box.label,
                      style: TextStyle(
                          fontSize: AppResponsive.text(context, 11),
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ActivityCard extends StatelessWidget {
  final ActivityItem item;
  const _ActivityCard({required this.item});
  @override
  Widget build(BuildContext context) {
    final isPreTrip = item.type == 'pre_trip';
    final isCompleted = item.status == 'completed';
    final statusCol = isCompleted
        ? _brightGreen
        : item.status == 'pending'
            ? AppColors.amber
            : AppColors.danger;
    final title =
        '${isPreTrip ? AppStrings.preTrip : AppStrings.postTrip} ${item.status}';
    return Container(
      margin: EdgeInsets.only(bottom: AppResponsive.spacing(context, 10)),
      padding: EdgeInsets.all(AppResponsive.padding(context, 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        Container(
            width: AppResponsive.scale(context, 42),
            height: AppResponsive.scale(context, 42),
            decoration: BoxDecoration(
                color: statusCol.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.local_shipping_rounded,
                color: statusCol, size: AppResponsive.scale(context, 22))),
        SizedBox(width: AppResponsive.spacing(context, 12)),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: AppResponsive.text(context, 13),
                  color: AppColors.primary)),
          Text(item.vehicleNumber,
              style: TextStyle(
                  fontSize: AppResponsive.text(context, 12),
                  color: AppColors.textSecondary)),
        ])),
        Text(_relativeTime(item.date),
            style: TextStyle(
                fontSize: AppResponsive.text(context, 11),
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
