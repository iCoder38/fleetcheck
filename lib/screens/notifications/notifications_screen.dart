import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/inspection_model.dart';
import '../../repositories/inspection_repository.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repo = InspectionRepository();

  bool _showUnreadOnly = false;
  bool _isLoading      = true;
  String? _error;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() { _isLoading = true; _error = null; });
    final result = await _repo.getNotifications();
    if (!mounted) return;
    if (result.success) {
      setState(() { _notifications = result.data ?? []; _isLoading = false; });
    } else {
      setState(() { _error = result.error; _isLoading = false; });
    }
  }

  Future<void> _markRead(NotificationModel n) async {
    if (n.isRead) return;
    await _repo.markNotificationRead(n.id);
    setState(() {
      final idx = _notifications.indexWhere((x) => x.id == n.id);
      if (idx >= 0) {
        _notifications = List.from(_notifications)
          ..[idx] = NotificationModel(
            id:          n.id,
            title:       n.title,
            message:     n.message,
            type:        n.type,
            isRead:      true,
            createdAt:   n.createdAt,
            referenceId: n.referenceId,
          );
      }
    });
  }

  List<NotificationModel> get _filtered =>
      _showUnreadOnly ? _notifications.where((n) => !n.isRead).toList() : _notifications;

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

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
            Text(n.message, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.6)),
            const SizedBox(height: 12),
            Text(
              DateFormat('MM/dd/yyyy hh:mm a').format(n.createdAt),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            if (n.referenceId != null) ...[
              const SizedBox(height: 4),
              Text('Reference: ${n.referenceId}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'new_assignment':  return 'New Assignment';
      case 'reminder':        return 'Inspection Reminder';
      default:                return 'Management Message';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.notifications),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: () async {
                for (final n in _notifications.where((x) => !x.isRead)) {
                  await _repo.markNotificationRead(n.id);
                }
                setState(() {
                  _notifications = _notifications.map((n) => NotificationModel(
                    id: n.id, title: n.title, message: n.message,
                    type: n.type, isRead: true, createdAt: n.createdAt, referenceId: n.referenceId,
                  )).toList();
                });
              },
              child: const Text('Mark all read', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _FilterTab(
                  label: AppStrings.allNotifications,
                  count: _notifications.length,
                  selected: !_showUnreadOnly,
                  onTap: () => setState(() => _showUnreadOnly = false),
                ),
                const SizedBox(width: 10),
                _FilterTab(
                  label: AppStrings.unread,
                  count: _unreadCount,
                  selected: _showUnreadOnly,
                  onTap: () => setState(() => _showUnreadOnly = true),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
                : _error != null
                    ? _ErrorView(message: _error!, onRetry: _loadNotifications)
                    : _filtered.isEmpty
                        ? _EmptyView(isFiltered: _showUnreadOnly)
                        : RefreshIndicator(
                            onRefresh: _loadNotifications,
                            color: AppColors.secondary,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, i) => _NotificationCard(
                                notification: _filtered[i],
                                onTap: () => _showDetail(_filtered[i]),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTab({required this.label, required this.count, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:        selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border:       Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color:        selected ? Colors.white.withOpacity(0.25) : AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textSecondary)),
            ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        n.isRead ? AppColors.surface : AppColors.secondary.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: n.isRead ? AppColors.border : AppColors.secondary.withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NotifIcon(type: n.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(n.title, style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: n.isRead ? AppColors.textPrimary : AppColors.primary,
                        )),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8, height: 8,
                          margin: const EdgeInsets.only(left: 4, top: 2),
                          decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(n.message, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('MM/dd/yyyy hh:mm a').format(n.createdAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifIcon extends StatelessWidget {
  final String type;
  final double size;
  const _NotifIcon({required this.type, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      'new_assignment' => (Icons.assignment_rounded,      AppColors.secondary),
      'reminder'       => (Icons.alarm_on_rounded,        AppColors.amber),
      _                => (Icons.mark_chat_unread_rounded, AppColors.primary),
    };

    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
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
            ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Retry')),
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
            Icon(Icons.notifications_none_rounded, size: 56, color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              isFiltered ? 'No unread notifications.' : 'No notifications yet.',
              style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
