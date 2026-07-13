part of 'inspection_history_detail_bloc.dart';

sealed class InspectionHistoryDetailEvent {}

final class DetailRequested extends InspectionHistoryDetailEvent {
  final int inspectionId;
  DetailRequested(this.inspectionId);
}
