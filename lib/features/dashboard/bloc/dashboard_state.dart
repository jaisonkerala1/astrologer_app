import '../models/dashboard_stats_model.dart';

abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoadedState extends DashboardState {
  final DashboardStatsModel stats;
  
  DashboardLoadedState(this.stats);
}

class DashboardErrorState extends DashboardState {
  final String message;
  
  DashboardErrorState(this.message);
}

class StatusUpdatedState extends DashboardState {
  final bool isOnline;
  
  StatusUpdatedState(this.isOnline);
}









