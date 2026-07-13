import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/inspection_model.dart';
import '../../../repositories/inspection_repository.dart';

part 'inspection_history_event.dart';
part 'inspection_history_state.dart';

class InspectionHistoryBloc
    extends Bloc<InspectionHistoryEvent, InspectionHistoryState> {
  final InspectionRepository _repo;

  InspectionHistoryBloc(this._repo) : super(InspectionHistoryLoading()) {
    on<HistoryLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
      HistoryLoadRequested event, Emitter<InspectionHistoryState> emit) async {
    emit(InspectionHistoryLoading());
    final result = await _repo.getInspections(
      dateRange: event.dateRange,
      dateFrom: event.dateFrom,
      dateTo: event.dateTo,
      vehicleNumber: event.vehicleNumber,
      type: event.type,
      status: event.status,
    );
    if (result.success) {
      emit(InspectionHistoryLoaded(result.data ?? []));
    } else {
      emit(InspectionHistoryLoadFailure(result.error ?? 'Failed to load inspections.'));
    }
  }
}
