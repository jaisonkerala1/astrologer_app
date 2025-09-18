abstract class DashboardEvent {}

class LoadDashboardStatsEvent extends DashboardEvent {}

class UpdateOnlineStatusEvent extends DashboardEvent {
  final bool isOnline;
  
  UpdateOnlineStatusEvent(this.isOnline);
}

class RefreshDashboardEvent extends DashboardEvent {}









