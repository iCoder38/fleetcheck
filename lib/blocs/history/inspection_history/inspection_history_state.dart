part of 'inspection_history_bloc.dart';

sealed class InspectionHistoryState {}

final class InspectionHistoryLoading extends InspectionHistoryState {}

final class InspectionHistoryLoaded extends InspectionHistoryState {
  final List<InspectionResult> items;
  InspectionHistoryLoaded(this.items);
}

final class InspectionHistoryLoadFailure extends InspectionHistoryState {
  final String message;
  InspectionHistoryLoadFailure(this.message);
}
