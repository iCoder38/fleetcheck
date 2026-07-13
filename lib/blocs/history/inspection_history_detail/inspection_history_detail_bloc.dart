import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../repositories/inspection_repository.dart';

part 'inspection_history_detail_event.dart';
part 'inspection_history_detail_state.dart';

class InspectionHistoryDetailBloc
    extends Bloc<InspectionHistoryDetailEvent, InspectionHistoryDetailState> {
  final InspectionRepository _repo;

  InspectionHistoryDetailBloc(this._repo)
      : super(InspectionHistoryDetailLoading()) {
    on<DetailRequested>(_onDetailRequested);
  }

  Future<void> _onDetailRequested(DetailRequested event,
      Emitter<InspectionHistoryDetailState> emit) async {
    emit(InspectionHistoryDetailLoading());
    final result = await _repo.getInspectionDetail(event.inspectionId);
    if (result.success) {
      emit(InspectionHistoryDetailLoaded(result.data ?? {}));
    } else {
      emit(InspectionHistoryDetailFailure(
          result.error ?? 'Failed to load inspection.'));
    }
  }
}
