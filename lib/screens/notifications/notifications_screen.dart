import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/notifications/notifications_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_responsive.dart';
import '../../models/inspection_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _showUnreadOnly = false;

  void _loadNotifications() {
    context.read<NotificationsBloc>().add(NotificationsLoadRequested());
  }

  void _markRead(NotificationModel n) {
    context.read<NotificationsBloc>().add(NotificationMarkedRead(n.id));
  }

  List<NotificationModel> _filtered(List<NotificationModel> all) =>
      _showUnreadOnly ? all.where((n) => !n.isRead).toList() : all;

  int _unreadCount(List<NotificationModel> all) =>
      all.where((n) => !n.isRead).length;

  void _showDetail(NotificationModel n) {
    _markRead(n);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              _NotifIcon(type: n.type, size: 44),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary)),
                Text(_typeLabel(n.type), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ])),
            ]),
            const SizedBox(height: 16),
            Text(n.message, style: const TextStyle(fontSize: 14, color: AppColors.primary, height: 1.6)),
            const SizedBox(height: 12),
            Text(
              DateFormat('MM/dd/yyyy hh:mm a').format(n.createdAt),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            if (n.referenceId != null) ...[
              const SizedBox(height: 4),
              Text(AppStrings.referenceLabel(n.referenceId!), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'new_assignment':  return AppStrings.notifTypeNewAssignment;
      case 'reminder':        return AppStrings.notifTypeReminder;
      default:                return AppStrings.notifTypeManagement;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        final all = state is NotificationsLoaded ? state.notifications : <NotificationModel>[];
        final filtered = _filtered(all);
        final unreadCount = _unreadCount(all);
        return Scaffold(
          backgroundColor: AppColors.appbg,
          body: Column(
            children: [
              _Header(
                unreadCount: unreadCount,
                showUnreadOnly: _showUnreadOnly,
                onSelectAll: () => setState(() => _showUnreadOnly = false),
                onSelectUnread: () => setState(() => _showUnreadOnly = true),
                onMarkAllRead: unreadCount > 0
                    ? () => context.read<NotificationsBloc>().add(MarkAllReadRequested())
                    : null,
              ),
              Expanded(
                child: state is NotificationsLoading
                    ?  Center(child: CircularProgressIndicator(color: AppColors.secondary))
                    : state is NotificationsLoadFailure
                        ? _ErrorView(message: state.message, onRetry: _loadNotifications)
                        : filtered.isEmpty
                            ? _EmptyView(isFiltered: _showUnreadOnly)
                            : RefreshIndicator(
                                onRefresh: () async => _loadNotifications(),
                                color: AppColors.secondary,
                                child: ListView.separated(
                                  padding: EdgeInsets.all(AppResponsive.padding(context, 16)),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => SizedBox(height: AppResponsive.spacing(context, 12)),
                                  itemBuilder: (_, i) => _NotificationCard(
                                    notification: filtered[i],
                                    onTap: () => _showDetail(filtered[i]),
                                  ),
                                ),
                              ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Header: flat navy panel with title + filter pills ─────────────────────
class _Header extends StatelessWidget {
  final int unreadCount;
  final bool showUnreadOnly;
  final VoidCallback onSelectAll;
  final VoidCallback onSelectUnread;
  final VoidCallback? onMarkAllRead;

  const _Header({
    required this.unreadCount,
    required this.showUnreadOnly,
    required this.onSelectAll,
    required this.onSelectUnread,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        padding: EdgeInsets.fromLTRB(
          AppResponsive.padding(context, 24),
          0,
          AppResponsive.padding(context, 24),
          AppResponsive.padding(context, 20),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppResponsive.spacing(context, 16)),
              Row(
                children: [
                  Expanded(
                    child: Text(AppStrings.notifications,
                        style: TextStyle(
                            fontSize: AppResponsive.text(context, 26),
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                  if (onMarkAllRead != null)
                    TextButton(
                      onPressed: onMarkAllRead,
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: AppResponsive.padding(context, 10))),
                      child: Text(AppStrings.markAllRead,
                          style: TextStyle(
                              fontSize: AppResponsive.text(context, 12),
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.8))),
                    ),
                ],
              ),
              SizedBox(height: AppResponsive.spacing(context, 16)),
              Row(
                children: [
                  _FilterPill(
                    label: AppStrings.allNotifications,
                    selected: !showUnreadOnly,
                    onTap: onSelectAll,
                  ),
                  SizedBox(width: AppResponsive.spacing(context, 10)),
                  _FilterPill(
                    label: AppStrings.unread,
                    badgeCount: unreadCount,
                    selected: showUnreadOnly,
                    onTap: onSelectUnread,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _FilterPill extends StatelessWidget {
  final String label;
  final int? badgeCount;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    this.badgeCount,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
            horizontal: AppResponsive.padding(context, 16),
            vertical: AppResponsive.padding(context, 9)),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: AppResponsive.text(context, 14),
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.primary : Colors.white.withValues(alpha: 0.85))),
            if (badgeCount != null && badgeCount! > 0) ...[
              SizedBox(width: AppResponsive.spacing(context, 6)),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: AppResponsive.padding(context, 7), vertical: 2),
                decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                constraints: BoxConstraints(minWidth: AppResponsive.scale(context, 20)),
                child: Text('$badgeCount',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: AppResponsive.text(context, 11),
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final accent = _accentColor(n.type);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
          ],
          border: Border(
            left: BorderSide(
              color: n.isRead ? Colors.transparent : accent,
              width: 3,
            ),
          ),
        ),
        padding: EdgeInsets.all(AppResponsive.padding(context, 14)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NotifIcon(type: n.type),
            SizedBox(width: AppResponsive.spacing(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(n.title, style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: AppResponsive.text(context, 15),
                          color: AppColors.primary,
                        )),
                      ),
                      SizedBox(width: AppResponsive.spacing(context, 8)),
                      Text(_relativeTime(n.createdAt),
                          style: TextStyle(
                              fontSize: AppResponsive.text(context, 11),
                              color: AppColors.textLight)),
                      if (!n.isRead) ...[
                        SizedBox(width: AppResponsive.spacing(context, 6)),
                        Container(
                          width: 8, height: 8,
                          margin: const EdgeInsets.only(top: 3),
                          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 4)),
                  Text(n.message, style: TextStyle(
                      fontSize: AppResponsive.text(context, 13),
                      color: AppColors.textSecondary, height: 1.4),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _accentColor(String type) => switch (type) {
        'new_assignment' => const Color(0xFF17A2B8),
        'reminder' => AppColors.amber,
        'system_update' => AppColors.info,
        _ => AppColors.textLight,
      };
}

String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return AppStrings.justNow;
  if (diff.inMinutes < 60) return AppStrings.agoMinutes(diff.inMinutes);
  if (diff.inHours < 24) return AppStrings.agoHours(diff.inHours);
  return AppStrings.agoDays(diff.inDays);
}

class _NotifIcon extends StatelessWidget {
  final String type;
  final double size;
  const _NotifIcon({required this.type, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      'new_assignment' => (Icons.local_shipping_rounded, const Color(0xFF17A2B8)),
      'reminder'       => (Icons.alarm_on_rounded,        AppColors.amber),
      'system_update'  => (Icons.sync_rounded,            AppColors.info),
      _                => (Icons.campaign_rounded,        AppColors.textSecondary),
    };

    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text(AppStrings.retryLabel)),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool isFiltered;
  const _EmptyView({required this.isFiltered});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_rounded, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              isFiltered ? AppStrings.noUnreadNotifications : AppStrings.noNotificationsYet,
              style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
