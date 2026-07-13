part of 'inspection_history_bloc.dart';

sealed class InspectionHistoryEvent {}

final class HistoryLoadRequested extends InspectionHistoryEvent {
  final String? dateRange;
  final String? dateFrom;
  final String? dateTo;
  final String? vehicleNumber;
  final String? type;
  final String? status;
  HistoryLoadRequested({
    this.dateRange,
    this.dateFrom,
    this.dateTo,
    this.vehicleNumber,
    this.type,
    this.status,
  });
}
