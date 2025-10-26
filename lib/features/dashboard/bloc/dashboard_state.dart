import 'package:equatable/equatable.dart';
import '../models/dashboard_stats_model.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoadedState extends DashboardState {
  final DashboardStatsModel stats;
  
  DashboardLoadedState(this.stats);
  
  @override
  List<Object?> get props => [stats];
}

class DashboardErrorState extends DashboardState {
  final String message;
  
  const DashboardErrorState(this.message);
  
  @override
  List<Object?> get props => [message];
}

// StatusUpdatedState removed - use DashboardLoadedState with copyWith instead









