import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/driver_model.dart';
import '../../models/inspection_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/inspection_repository.dart';
import '../../routes/app_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authRepo  = AuthRepository();
  final _inspRepo  = InspectionRepository();

  DriverModel?        _driver;
  DriverStats?        _stats;
  List<ActivityItem>  _recent    = [];
  bool                _loading   = true;
  int                 _navIndex  = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _driver = _authRepo.getCachedDriver();

    final statsRes  = await _inspRepo.getDriverStats();
    final recentRes = await _inspRepo.getRecentActivity();

    if (!mounted) return;
    setState(() {
      _stats   = statsRes.data  ?? DriverStats.empty();
      _recent  = recentRes.data ?? [];
      _loading = false;
    });
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(AppStrings.confirmLogout, textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(AppStrings.confirmLogoutMessage, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _authRepo.logout();
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
          : RefreshIndicator(
              onRefresh: _load,
              color:     AppColors.secondary,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildScanButton()),
                  SliverToBoxAdapter(child: _buildStats()),
                  SliverToBoxAdapter(child: _buildRecentActivity()),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── Header ─────────────────────────────────────────────
  Widget _buildHeader() {
    final driver = _driver;
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 20),
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.greenGradient,
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                ),
                child: driver?.photoUrl != null
                    ? ClipOval(child: Image.network(driver!.photoUrl!, fit: BoxFit.cover))
                    : const Icon(Icons.person_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),

              // Name + ID
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Welcome back!',
                      style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
                  Text(driver?.fullName ?? 'Driver',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                  Row(children: [
                    _Pill(driver?.employeeId ?? '—', color: Colors.white.withOpacity(0.2)),
                    const SizedBox(width: 6),
                    _Pill('Active', color: AppColors.secondary.withOpacity(0.6)),
                  ]),
                ]),
              ),

              // Notification bell
              GestureDetector(
                onTap: () => context.push(AppRoutes.notifications),
                child: Stack(children: [
                  const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                  Positioned(top: 0, right: 0,
                    child: Container(width: 8, height: 8,
                      decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle))),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Date & time row
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()),
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
            Text(DateFormat('hh:mm a').format(DateTime.now()),
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
          ]),
        ],
      ),
    );
  }

  // ─── Scan QR button ──────────────────────────────────────
  Widget _buildScanButton() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
    child: GestureDetector(
      onTap: () => context.push(AppRoutes.qrScanner),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: AppColors.greenGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.secondary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 26),
            SizedBox(width: 10),
            Text(AppStrings.scanQrCode,
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    ),
  );

  // ─── Stats 4-box grid ────────────────────────────────────
  Widget _buildStats() {
    final s = _stats ?? DriverStats.empty();
    final boxes = [
      _StatBox(label: AppStrings.totalAssigned,    value: s.totalAssigned,    color: AppColors.primary,  icon: Icons.assignment_rounded),
      _StatBox(label: AppStrings.preTripCompleted, value: s.preTripCompleted, color: AppColors.secondary, icon: Icons.wb_sunny_rounded),
      _StatBox(label: AppStrings.postTripCompleted,value: s.postTripCompleted,color: const Color(0xFF7C3AED), icon: Icons.nights_stay_rounded),
      _StatBox(label: AppStrings.pendingInspections,value: s.pending,         color: AppColors.amber,    icon: Icons.pending_actions_rounded),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Stats', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount:    2,
            crossAxisSpacing:  12,
            mainAxisSpacing:   12,
            childAspectRatio:  1.45,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: boxes.map((b) => _StatCard(box: b)).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Recent activity ─────────────────────────────────────
  Widget _buildRecentActivity() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(AppStrings.recentActivity,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            TextButton(
              onPressed: () => context.push(AppRoutes.history),
              style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
              child: const Text('View All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_recent.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border)),
            child: const Center(
              child: Column(children: [
                Icon(Icons.inbox_outlined, size: 36, color: AppColors.textSecondary),
                SizedBox(height: 8),
                Text('No recent inspections.', style: TextStyle(color: AppColors.textSecondary)),
              ]),
            ),
          )
        else
          ...(_recent.map((item) => _ActivityCard(item: item))),
      ],
    ),
  );

  // ─── Bottom nav ──────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      _NavItem(icon: Icons.home_rounded,          label: 'Home'),
      _NavItem(icon: Icons.history_rounded,        label: 'History'),
      _NavItem(icon: Icons.notifications_rounded,  label: 'Alerts'),
      _NavItem(icon: Icons.person_rounded,         label: 'Profile'),
      _NavItem(icon: Icons.logout_rounded,         label: 'Logout'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, -3))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) => _NavButton(
              item:     items[i],
              selected: _navIndex == i,
              onTap:    () {
                if (i == 4) { _confirmLogout(); return; }
                setState(() => _navIndex = i);
                switch (i) {
                  case 0: break; // already on dashboard
                  case 1: context.push(AppRoutes.history);
                  case 2: context.push(AppRoutes.notifications);
                  case 3: context.push(AppRoutes.profile);
                }
              },
            )),
          ),
        ),
      ),
    );
  }
}

// ─── Helper data classes ──────────────────────────────────

class _StatBox { final String label; final int value; final Color color; final IconData icon;
  const _StatBox({required this.label, required this.value, required this.color, required this.icon}); }

class _NavItem { final IconData icon; final String label;
  const _NavItem({required this.icon, required this.label}); }

// ─── Sub-widgets ──────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String text; final Color color;
  const _Pill(this.text, {required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
    child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
  );
}

class _StatCard extends StatelessWidget {
  final _StatBox box;
  const _StatCard({super.key, required this.box});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: box.color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(box.icon, color: box.color, size: 20)),
      const Spacer(),
      Text('${box.value}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: box.color)),
      Text(box.label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _ActivityCard extends StatelessWidget {
  final ActivityItem item;
  const _ActivityCard({required this.item});
  @override
  Widget build(BuildContext context) {
    final isPreTrip = item.type == 'pre_trip';
    final col       = isPreTrip ? AppColors.secondary : AppColors.primary;
    final statusCol = item.status == 'completed' ? AppColors.secondary : item.status == 'pending' ? AppColors.amber : AppColors.danger;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(isPreTrip ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded, color: col, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.inspectionId, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary, fontFamily: 'monospace')),
          Text(item.vehicleNumber, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: statusCol.withOpacity(0.1), borderRadius: BorderRadius.circular(99)),
          child: Text(_capitalize(item.status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusCol))),
      ]),
    );
  }
  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _NavButton extends StatelessWidget {
  final _NavItem item; final bool selected; final VoidCallback onTap;
  const _NavButton({required this.item, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.secondary.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(item.icon, color: selected ? AppColors.accent : Colors.white.withOpacity(0.5), size: 24),
        const SizedBox(height: 3),
        Text(item.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
            color: selected ? AppColors.accent : Colors.white.withOpacity(0.5))),
      ]),
    ),
  );
}
