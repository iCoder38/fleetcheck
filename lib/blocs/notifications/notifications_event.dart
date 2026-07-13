part of 'notifications_bloc.dart';

sealed class NotificationsEvent {}

final class NotificationsLoadRequested extends NotificationsEvent {}

final class NotificationMarkedRead extends NotificationsEvent {
  final int id;
  NotificationMarkedRead(this.id);
}

final class MarkAllReadRequested extends NotificationsEvent {}
