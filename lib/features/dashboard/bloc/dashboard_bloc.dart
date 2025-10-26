import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/dashboard/dashboard_repository.dart';
import '../models/dashboard_stats_model.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository repository;

  DashboardBloc({required this.repository}) : super(DashboardInitial()) {
    on<LoadDashboardStatsEvent>(_onLoadDashboardStats);
    on<UpdateOnlineStatusEvent>(_onUpdateOnlineStatus);
    on<RefreshDashboardEvent>(_onRefreshDashboard);
  }

  Future<void> _onLoadDashboardStats(LoadDashboardStatsEvent event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    
    try {
      final stats = await repository.getDashboardStats();
      emit(DashboardLoadedState(stats));
    } catch (e) {
      emit(DashboardErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateOnlineStatus(UpdateOnlineStatusEvent event, Emitter<DashboardState> emit) async {
    try {
      final success = await repository.updateOnlineStatus(event.isOnline);
      
      if (success) {
        // Update the current state with new online status
        if (state is DashboardLoadedState) {
          final currentStats = (state as DashboardLoadedState).stats;
          final updatedStats = currentStats.copyWith(isOnline: event.isOnline);
          emit(DashboardLoadedState(updatedStats));
        }
      } else {
        throw Exception('Failed to update status');
      }
    } catch (e) {
      emit(DashboardErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRefreshDashboard(RefreshDashboardEvent event, Emitter<DashboardState> emit) async {
    add(LoadDashboardStatsEvent());
  }
}
