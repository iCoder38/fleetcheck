part of 'inspection_history_detail_bloc.dart';

sealed class InspectionHistoryDetailState {}

final class InspectionHistoryDetailLoading extends InspectionHistoryDetailState {}

final class InspectionHistoryDetailLoaded extends InspectionHistoryDetailState {
  final Map<String, dynamic> detail;
  InspectionHistoryDetailLoaded(this.detail);
}

final class InspectionHistoryDetailFailure extends InspectionHistoryDetailState {
  final String message;
  InspectionHistoryDetailFailure(this.message);
}
