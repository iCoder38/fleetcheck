import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/inspection_model.dart';
import '../../../repositories/inspection_repository.dart';

part 'inspection_submit_event.dart';
part 'inspection_submit_state.dart';

class InspectionSubmitBloc
    extends Bloc<InspectionSubmitEvent, InspectionSubmitState> {
  final InspectionRepository _repo;

  InspectionSubmitBloc(this._repo) : super(InspectionSubmitIdle()) {
    on<SubmitRequested>(_onSubmitRequested);
  }

  Future<void> _onSubmitRequested(
      SubmitRequested event, Emitter<InspectionSubmitState> emit) async {
    emit(InspectionSubmitting());
    final result = await _repo.submitInspection(event.submission);
    if (result.success && result.data != null) {
      emit(InspectionSubmitted(result.data!));
    } else {
      emit(InspectionSubmitFailure(
          result.error ?? 'Submission failed. Please try again.'));
    }
  }
}
