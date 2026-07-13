part of 'inspection_submit_bloc.dart';

sealed class InspectionSubmitState {}

final class InspectionSubmitIdle extends InspectionSubmitState {}

final class InspectionSubmitting extends InspectionSubmitState {}

final class InspectionSubmitted extends InspectionSubmitState {
  final InspectionResult result;
  InspectionSubmitted(this.result);
}

final class InspectionSubmitFailure extends InspectionSubmitState {
  final String message;
  InspectionSubmitFailure(this.message);
}
