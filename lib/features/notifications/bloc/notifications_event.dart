import 'package:equatable/equatable.dart';
import '../models/notification_model.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotificationsEvent extends NotificationsEvent {
  final NotificationStatus? status;
  final NotificationType? type;
  final int page;

  const LoadNotificationsEvent({this.status, this.type, this.page = 1});
  @override
  List<Object?> get props => [status, type, page];
}

class LoadNotificationByIdEvent extends NotificationsEvent {
  final String id;
  const LoadNotificationByIdEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class MarkAsReadEvent extends NotificationsEvent {
  final String id;
  const MarkAsReadEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class MarkAllAsReadEvent extends NotificationsEvent {
  const MarkAllAsReadEvent();
}

class DeleteNotificationEvent extends NotificationsEvent {
  final String id;
  const DeleteNotificationEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class DeleteAllNotificationsEvent extends NotificationsEvent {
  const DeleteAllNotificationsEvent();
}

class ArchiveNotificationEvent extends NotificationsEvent {
  final String id;
  const ArchiveNotificationEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class LoadNotificationStatsEvent extends NotificationsEvent {
  const LoadNotificationStatsEvent();
}

class MarkMultipleAsReadEvent extends NotificationsEvent {
  final List<String> ids;
  const MarkMultipleAsReadEvent(this.ids);
  @override
  List<Object?> get props => [ids];
}

class DeleteMultipleEvent extends NotificationsEvent {
  final List<String> ids;
  const DeleteMultipleEvent(this.ids);
  @override
  List<Object?> get props => [ids];
}

class ArchiveMultipleEvent extends NotificationsEvent {
  final List<String> ids;
  const ArchiveMultipleEvent(this.ids);
  @override
  List<Object?> get props => [ids];
}

class FilterNotificationsEvent extends NotificationsEvent {
  final NotificationType? type;
  final NotificationPriority? priority;
  final DateTime? startDate;
  final DateTime? endDate;

  const FilterNotificationsEvent({
    this.type,
    this.priority,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [type, priority, startDate, endDate];
}

class RefreshNotificationsEvent extends NotificationsEvent {
  const RefreshNotificationsEvent();
}

class SearchNotificationsEvent extends NotificationsEvent {
  final String query;
  
  const SearchNotificationsEvent(this.query);
  
  @override
  List<Object?> get props => [query];
}

class ClearSearchEvent extends NotificationsEvent {
  const ClearSearchEvent();
}


