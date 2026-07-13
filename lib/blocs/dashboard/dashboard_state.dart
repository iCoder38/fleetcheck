part of 'dashboard_bloc.dart';

sealed class DashboardState {}

final class DashboardLoading extends DashboardState {}

final class DashboardLoaded extends DashboardState {
  final DriverModel? driver;
  final DriverStats stats;
  final List<ActivityItem> recent;
  DashboardLoaded({required this.driver, required this.stats, required this.recent});
}
