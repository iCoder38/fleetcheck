part of 'inspection_submit_bloc.dart';

sealed class InspectionSubmitEvent {}

final class SubmitRequested extends InspectionSubmitEvent {
  final InspectionSubmission submission;
  SubmitRequested(this.submission);
}
