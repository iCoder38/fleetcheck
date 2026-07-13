import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/inspection_model.dart';
import '../../repositories/inspection_repository.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final InspectionRepository _repo;

  NotificationsBloc(this._repo) : super(NotificationsLoading()) {
    on<NotificationsLoadRequested>(_onLoadRequested);
    on<NotificationMarkedRead>(_onMarkedRead);
    on<MarkAllReadRequested>(_onMarkAllRead);
  }

  Future<void> _onLoadRequested(
      NotificationsLoadRequested event, Emitter<NotificationsState> emit) async {
    emit(NotificationsLoading());
    final result = await _repo.getNotifications();
    if (result.success) {
      emit(NotificationsLoaded(result.data ?? []));
    } else {
      emit(NotificationsLoadFailure(result.error ?? 'Failed to load notifications.'));
    }
  }

  Future<void> _onMarkedRead(
      NotificationMarkedRead event, Emitter<NotificationsState> emit) async {
    final current = state;
    if (current is! NotificationsLoaded) return;
    final n = current.notifications.firstWhere((x) => x.id == event.id);
    if (n.isRead) return;

    await _repo.markNotificationRead(event.id);
    final idx = current.notifications.indexWhere((x) => x.id == event.id);
    if (idx >= 0) {
      final updated = List<NotificationModel>.from(current.notifications);
      updated[idx] = NotificationModel(
        id: n.id,
        title: n.title,
        message: n.message,
        type: n.type,
        isRead: true,
        createdAt: n.createdAt,
        referenceId: n.referenceId,
      );
      emit(NotificationsLoaded(updated));
    }
  }

  Future<void> _onMarkAllRead(
      MarkAllReadRequested event, Emitter<NotificationsState> emit) async {
    final current = state;
    if (current is! NotificationsLoaded) return;

    for (final n in current.notifications.where((x) => !x.isRead)) {
      await _repo.markNotificationRead(n.id);
    }
    emit(NotificationsLoaded(current.notifications
        .map((n) => NotificationModel(
              id: n.id,
              title: n.title,
              message: n.message,
              type: n.type,
              isRead: true,
              createdAt: n.createdAt,
              referenceId: n.referenceId,
            ))
        .toList()));
  }
}
