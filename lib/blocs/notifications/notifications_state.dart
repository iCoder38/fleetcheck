part of 'notifications_bloc.dart';

sealed class NotificationsState {}

final class NotificationsLoading extends NotificationsState {}

final class NotificationsLoaded extends NotificationsState {
  final List<NotificationModel> notifications;
  NotificationsLoaded(this.notifications);
}

final class NotificationsLoadFailure extends NotificationsState {
  final String message;
  NotificationsLoadFailure(this.message);
}
