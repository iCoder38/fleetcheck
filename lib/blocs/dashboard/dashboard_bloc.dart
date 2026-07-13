import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/driver_model.dart';
import '../../models/inspection_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/inspection_repository.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final AuthRepository _authRepo;
  final InspectionRepository _inspRepo;

  DashboardBloc(this._authRepo, this._inspRepo) : super(DashboardLoading()) {
    on<DashboardLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
      DashboardLoadRequested event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    final driver = _authRepo.getCachedDriver();

    // Start both calls without awaiting immediately so they run concurrently.
    final statsFuture = _inspRepo.getDriverStats();
    final recentFuture = _inspRepo.getRecentActivity();
    final statsRes = await statsFuture;
    final recentRes = await recentFuture;

    emit(DashboardLoaded(
      driver: driver,
      stats: statsRes.data ?? DriverStats.empty(),
      recent: recentRes.data ?? [],
    ));
  }
}
