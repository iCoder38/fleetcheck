import 'package:fleetcheck/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/app_responsive.dart';
import '../repositories/auth_repository.dart';
import '../repositories/inspection_repository.dart';
import '../routes/app_router.dart';

const _brightGreen = Color(0xFF2E9E5B);

class NavItem {
  final IconData icon;
  final String label;
  final String route;
  const NavItem({required this.icon, required this.label, required this.route});
}

class NavigationMenu {
  static const List<NavItem> items = [
    NavItem(icon: Icons.home_rounded, label: AppStrings.navHome, route: AppRoutes.dashboard),
    NavItem(icon: Icons.description_outlined, label: AppStrings.navHistory, route: AppRoutes.history),
    NavItem(icon: Icons.notifications_none_rounded, label: AppStrings.navAlerts, route: AppRoutes.notifications),
    NavItem(icon: Icons.person_outline_rounded, label: AppStrings.navProfile, route: AppRoutes.profile),
    NavItem(icon: Icons.logout_rounded, label: AppStrings.navLogout, route: 'logout'),
  ];
}

class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _unreadCount = 0;
  int? _lastIndex;

  @override
  void initState() {
    super.initState();
    _refreshUnreadCount();
  }

  Future<void> _refreshUnreadCount() async {
    final result = await context.read<InspectionRepository>().getNotifications();
    if (!mounted || !result.success) return;
    setState(() => _unreadCount = result.data!.where((n) => !n.isRead).length);
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.dashboard)) return 0;
    if (location.startsWith(AppRoutes.history)) return 1;
    if (location.startsWith(AppRoutes.notifications)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    if (index == 4) {
      _confirmLogout(context);
      return;
    }
    
    final route = NavigationMenu.items[index].route;
    context.go(route);
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
          backgroundColor:AppColors.appbg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(AppStrings.confirmLogout,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800)),
        content:  Text(AppStrings.confirmLogoutMessage,
            textAlign: TextAlign.center,style: AppTextStyles.body(context,color: AppColors.primary),),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (context.mounted) {
        await context.read<AuthRepository>().logout();
        if (context.mounted) context.go(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    // Refresh the unread badge whenever the user navigates away from the
    // Notifications tab (e.g. after reading/marking notifications there).
    if (_lastIndex == 2 && selectedIndex != 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshUnreadCount());
    }
    _lastIndex = selectedIndex;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, -3))
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AppResponsive.padding(context, 8),
                vertical: AppResponsive.padding(context, 8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                  NavigationMenu.items.length,
                  (i) => _NavButton(
                        item: NavigationMenu.items[i],
                        selected: selectedIndex == i,
                        badgeCount: i == 2 ? _unreadCount : 0,
                        onTap: () => _onItemTapped(i, context),
                      )),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavButton(
      {required this.item, required this.selected, this.badgeCount = 0, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
                horizontal: AppResponsive.padding(context, 14),
                vertical: AppResponsive.padding(context, 8)),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.black.withValues(alpha: 0.28)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(item.icon,
                      color: selected
                          ? _brightGreen
                          : Colors.white.withValues(alpha: 0.5),
                      size: AppResponsive.scale(context, 24)),
                  if (badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppResponsive.padding(context, 5), vertical: 1),
                        constraints: BoxConstraints(minWidth: AppResponsive.scale(context, 16)),
                        decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                        child: Text('$badgeCount',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: AppResponsive.text(context, 9),
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                    ),
                ],
              ),
              SizedBox(height: AppResponsive.spacing(context, 4)),
              Text(item.label,
                  style: TextStyle(
                      fontSize: AppResponsive.text(context, 10),
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? _brightGreen
                          : Colors.white.withValues(alpha: 0.5))),
            ]),
          ),
          SizedBox(height: AppResponsive.spacing(context, 3)),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: selected ? AppResponsive.scale(context, 16) : 0,
            height: 2,
            decoration: BoxDecoration(
              color: _brightGreen,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}
