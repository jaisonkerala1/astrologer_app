import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/notifications/notifications_repository.dart';
import '../models/notification_model.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRepository repository;

  NotificationsBloc({required this.repository}) : super(const NotificationsInitial()) {
    on<LoadNotificationsEvent>(_onLoadNotifications);
    on<LoadNotificationByIdEvent>(_onLoadNotificationById);
    on<MarkAsReadEvent>(_onMarkAsRead);
    on<MarkAllAsReadEvent>(_onMarkAllAsRead);
    on<DeleteNotificationEvent>(_onDeleteNotification);
    on<DeleteAllNotificationsEvent>(_onDeleteAllNotifications);
    on<ArchiveNotificationEvent>(_onArchiveNotification);
    on<LoadNotificationStatsEvent>(_onLoadNotificationStats);
    on<MarkMultipleAsReadEvent>(_onMarkMultipleAsRead);
    on<DeleteMultipleEvent>(_onDeleteMultiple);
    on<ArchiveMultipleEvent>(_onArchiveMultiple);
    on<FilterNotificationsEvent>(_onFilterNotifications);
    on<RefreshNotificationsEvent>(_onRefresh);
  }

  Future<void> _onLoadNotifications(LoadNotificationsEvent event, Emitter<NotificationsState> emit) async {
    emit(const NotificationsLoading());
    try {
      final notifications = await repository.getNotifications(
        status: event.status,
        type: event.type,
        page: event.page,
      );
      final stats = await repository.getNotificationStats();
      emit(NotificationsLoadedState(
        notifications: notifications,
        stats: stats,
        currentFilter: event.status,
      ));
    } catch (e) {
      emit(NotificationsErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadNotificationById(LoadNotificationByIdEvent event, Emitter<NotificationsState> emit) async {
    try {
      final notification = await repository.getNotificationById(event.id);
      if (state is NotificationsLoadedState) {
        final currentState = state as NotificationsLoadedState;
        emit(currentState.copyWith(selectedNotification: notification));
      }
    } catch (e) {
      emit(NotificationsErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onMarkAsRead(MarkAsReadEvent event, Emitter<NotificationsState> emit) async {
    // Store current state before any operations
    final currentState = state;
    
    try {
      await repository.markAsRead(event.id);
      
      // Only update if we have a loaded state
      if (currentState is NotificationsLoadedState) {
        final updatedNotifications = currentState.notifications.map((n) {
          if (n.id == event.id) {
            return n.copyWith(
              status: NotificationStatus.read,
              readAt: DateTime.now(),
            );
          }
          return n;
        }).toList();
        
        // Update stats
        final stats = await repository.getNotificationStats();
        
        emit(currentState.copyWith(
          notifications: updatedNotifications,
          stats: stats,
        ));
      }
    } catch (e) {
      emit(NotificationsErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onMarkAllAsRead(MarkAllAsReadEvent event, Emitter<NotificationsState> emit) async {
    // Store current state before any operations
    final currentState = state;
    
    try {
      await repository.markAllAsRead();
      
      // Only update if we have a loaded state
      if (currentState is NotificationsLoadedState) {
        // Mark all notifications as read
        final updatedNotifications = currentState.notifications.map((n) {
          return n.copyWith(
            status: NotificationStatus.read,
            readAt: DateTime.now(),
          );
        }).toList();
        
        // Update stats
        final stats = await repository.getNotificationStats();
        
        emit(currentState.copyWith(
          notifications: updatedNotifications,
          stats: NotificationStats(
            total: stats.total,
            unread: 0, // All marked as read
            read: stats.total,
            archived: stats.archived,
            urgent: 0,
            today: stats.today,
          ),
          successMessage: 'All notifications marked as read',
        ));
      }
    } catch (e) {
      emit(NotificationsErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteNotification(DeleteNotificationEvent event, Emitter<NotificationsState> emit) async {
    // Store current state before any operations
    final currentState = state;
    
    try {
      await repository.deleteNotification(event.id);
      
      // Only update if we have a loaded state
      if (currentState is NotificationsLoadedState) {
        final updatedNotifications = currentState.notifications
            .where((n) => n.id != event.id)
            .toList();
        
        final stats = await repository.getNotificationStats();
        
        emit(currentState.copyWith(
          notifications: updatedNotifications,
          stats: stats,
          successMessage: 'Notification deleted',
        ));
      }
    } catch (e) {
      emit(NotificationsErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteAllNotifications(DeleteAllNotificationsEvent event, Emitter<NotificationsState> emit) async {
    try {
      await repository.deleteAllNotifications();
      emit(NotificationsLoadedState(
        notifications: [],
        stats: const NotificationStats(
          total: 0,
          unread: 0,
          read: 0,
          archived: 0,
          urgent: 0,
          today: 0,
        ),
        successMessage: 'All notifications deleted',
      ));
    } catch (e) {
      emit(NotificationsErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onArchiveNotification(ArchiveNotificationEvent event, Emitter<NotificationsState> emit) async {
    // Store current state before any operations
    final currentState = state;
    
    try {
      await repository.archiveNotification(event.id);
      
      // Only update if we have a loaded state
      if (currentState is NotificationsLoadedState) {
        final updatedNotifications = currentState.notifications.map((n) {
          if (n.id == event.id) {
            return n.copyWith(status: NotificationStatus.archived);
          }
          return n;
        }).toList();
        
        final stats = await repository.getNotificationStats();
        
        emit(currentState.copyWith(
          notifications: updatedNotifications,
          stats: stats,
          successMessage: 'Notification archived',
        ));
      }
    } catch (e) {
      emit(NotificationsErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadNotificationStats(LoadNotificationStatsEvent event, Emitter<NotificationsState> emit) async {
    try {
      final stats = await repository.getNotificationStats();
      if (state is NotificationsLoadedState) {
        final currentState = state as NotificationsLoadedState;
        emit(currentState.copyWith(stats: stats));
      }
    } catch (e) {
      print('Error loading notification stats: $e');
    }
  }

  Future<void> _onMarkMultipleAsRead(MarkMultipleAsReadEvent event, Emitter<NotificationsState> emit) async {
    // Store current state before any operations
    final currentState = state;
    
    try {
      await repository.markMultipleAsRead(event.ids);
      
      // Only update if we have a loaded state
      if (currentState is NotificationsLoadedState) {
        // Mark selected notifications as read
        final updatedNotifications = currentState.notifications.map((n) {
          if (event.ids.contains(n.id)) {
            return n.copyWith(
              status: NotificationStatus.read,
              readAt: DateTime.now(),
            );
          }
          return n;
        }).toList();
        
        // Update stats
        final stats = await repository.getNotificationStats();
        
        emit(currentState.copyWith(
          notifications: updatedNotifications,
          stats: stats,
          successMessage: '${event.ids.length} notifications marked as read',
        ));
      }
    } catch (e) {
      emit(NotificationsErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteMultiple(DeleteMultipleEvent event, Emitter<NotificationsState> emit) async {
    // Store current state before any operations
    final currentState = state;
    
    try {
      await repository.deleteMultiple(event.ids);
      
      // Only update if we have a loaded state
      if (currentState is NotificationsLoadedState) {
        // Remove deleted notifications
        final updatedNotifications = currentState.notifications
            .where((n) => !event.ids.contains(n.id))
            .toList();
        
        // Update stats
        final stats = await repository.getNotificationStats();
        
        emit(currentState.copyWith(
          notifications: updatedNotifications,
          stats: stats,
          successMessage: '${event.ids.length} notifications deleted',
        ));
      }
    } catch (e) {
      emit(NotificationsErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onArchiveMultiple(ArchiveMultipleEvent event, Emitter<NotificationsState> emit) async {
    // Store current state before any operations
    final currentState = state;
    
    try {
      await repository.archiveMultiple(event.ids);
      
      // Only update if we have a loaded state
      if (currentState is NotificationsLoadedState) {
        // Mark selected notifications as archived
        final updatedNotifications = currentState.notifications.map((n) {
          if (event.ids.contains(n.id)) {
            return n.copyWith(status: NotificationStatus.archived);
          }
          return n;
        }).toList();
        
        // Update stats
        final stats = await repository.getNotificationStats();
        
        emit(currentState.copyWith(
          notifications: updatedNotifications,
          stats: stats,
          successMessage: '${event.ids.length} notifications archived',
        ));
      }
    } catch (e) {
      emit(NotificationsErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFilterNotifications(FilterNotificationsEvent event, Emitter<NotificationsState> emit) async {
    emit(const NotificationsLoading(isInitialLoad: false));
    try {
      final notifications = await repository.filterNotifications(
        type: event.type,
        priority: event.priority,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      
      if (state is NotificationsLoadedState) {
        final currentState = state as NotificationsLoadedState;
        emit(currentState.copyWith(notifications: notifications));
      } else {
        emit(NotificationsLoadedState(notifications: notifications));
      }
    } catch (e) {
      emit(NotificationsErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRefresh(RefreshNotificationsEvent event, Emitter<NotificationsState> emit) async {
    add(const LoadNotificationsEvent());
  }
}

