import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/communication/communication_repository.dart';
import '../models/communication_item.dart';
import 'communication_event.dart';
import 'communication_state.dart';

/// BLoC for managing communication (messages, calls, video calls)
/// Follows clean architecture principles with repository pattern
class CommunicationBloc extends Bloc<CommunicationEvent, CommunicationState> {
  final CommunicationRepository repository;

  CommunicationBloc({required this.repository}) : super(const CommunicationInitial()) {
    on<LoadCommunicationsEvent>(_onLoadCommunications);
    on<FilterCommunicationsEvent>(_onFilterCommunications);
    on<RefreshCommunicationsEvent>(_onRefreshCommunications);
    on<LoadUnreadCountsEvent>(_onLoadUnreadCounts);
    on<MarkMessageAsReadEvent>(_onMarkMessageAsRead);
    on<MarkAllMessagesAsReadEvent>(_onMarkAllMessagesAsRead);
    on<ClearMissedCallsEvent>(_onClearMissedCalls);
    on<SendMessageEvent>(_onSendMessage);
    on<InitiateVoiceCallEvent>(_onInitiateVoiceCall);
    on<InitiateVideoCallEvent>(_onInitiateVideoCall);
    on<ClearCommunicationCacheEvent>(_onClearCache);
  }

  // ============================================================================
  // LOAD COMMUNICATIONS (Instagram/WhatsApp-style instant load)
  // ============================================================================

  Future<void> _onLoadCommunications(
    LoadCommunicationsEvent event,
    Emitter<CommunicationState> emit,
  ) async {
    // Preserve the current filter if exists
    CommunicationFilter currentFilter = CommunicationFilter.all;
    if (state is CommunicationLoadedState) {
      currentFilter = (state as CommunicationLoadedState).activeFilter;
      print('🔖 [CommunicationBloc] Preserving current filter: $currentFilter');
    }

    // 🚀 PHASE 1: INSTANT LOAD - Show data immediately (no spinner!)
    // This makes the app feel instant like WhatsApp/Instagram
    try {
      final instantData = repository.getInstantData(); // Synchronous, no await!
      
      if (instantData.isNotEmpty) {
        // Emit data instantly with refreshing flag (preserve filter!)
        emit(CommunicationLoadedState(
          allCommunications: instantData,
          activeFilter: currentFilter, // Use preserved filter
          unreadMessagesCount: 0, // Will update in phase 2
          missedCallsCount: 0,
          missedVideoCallsCount: 0,
          isRefreshing: true, // Show subtle refresh indicator
        ));
      } else {
        // Only show full loading spinner if absolutely no data exists
        emit(const CommunicationLoading());
      }
    } catch (e) {
      // If instant data fails (shouldn't happen), show spinner
      emit(const CommunicationLoading());
    }

    // 🔄 PHASE 2: BACKGROUND REFRESH - Silently fetch fresh data
    try {
      final communications = await repository.getAllCommunications(page: event.page);
      final unreadCounts = await repository.getUnreadCounts();

      emit(CommunicationLoadedState(
        allCommunications: communications,
        activeFilter: currentFilter, // Use preserved filter
        unreadMessagesCount: unreadCounts['messages'] ?? 0,
        missedCallsCount: unreadCounts['missedCalls'] ?? 0,
        missedVideoCallsCount: unreadCounts['missedVideoCalls'] ?? 0,
        isRefreshing: false, // Hide refresh indicator
      ));
    } catch (e) {
      // If refresh fails but we already showed data, just hide refresh indicator
      if (state is CommunicationLoadedState) {
        final currentState = state as CommunicationLoadedState;
        emit(currentState.copyWith(isRefreshing: false));
      } else {
        // Only show error if no data was shown
        emit(CommunicationErrorState(e.toString().replaceAll('Exception: ', '')));
      }
    }
  }

  Future<void> _onFilterCommunications(
    FilterCommunicationsEvent event,
    Emitter<CommunicationState> emit,
  ) async {
    if (state is CommunicationLoadedState) {
      final currentState = state as CommunicationLoadedState;
      emit(currentState.copyWith(activeFilter: event.filter));
    }
  }

  Future<void> _onRefreshCommunications(
    RefreshCommunicationsEvent event,
    Emitter<CommunicationState> emit,
  ) async {
    // Simply reload communications (filter is now preserved in _onLoadCommunications)
    await _onLoadCommunications(const LoadCommunicationsEvent(), emit);
  }

  // ============================================================================
  // UNREAD COUNTS
  // ============================================================================

  Future<void> _onLoadUnreadCounts(
    LoadUnreadCountsEvent event,
    Emitter<CommunicationState> emit,
  ) async {
    try {
      final unreadCounts = await repository.getUnreadCounts();

      if (state is CommunicationLoadedState) {
        final currentState = state as CommunicationLoadedState;
        emit(currentState.copyWith(
          unreadMessagesCount: unreadCounts['messages'] ?? 0,
          missedCallsCount: unreadCounts['missedCalls'] ?? 0,
          missedVideoCallsCount: unreadCounts['missedVideoCalls'] ?? 0,
        ));
      }
    } catch (e) {
      // Silently fail for unread counts
      print('Error loading unread counts: $e');
    }
  }

  // ============================================================================
  // MARK AS READ
  // ============================================================================

  Future<void> _onMarkMessageAsRead(
    MarkMessageAsReadEvent event,
    Emitter<CommunicationState> emit,
  ) async {
    try {
      await repository.markMessageAsRead(event.messageId);

      // Reload unread counts
      add(const LoadUnreadCountsEvent());
    } catch (e) {
      emit(CommunicationErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onMarkAllMessagesAsRead(
    MarkAllMessagesAsReadEvent event,
    Emitter<CommunicationState> emit,
  ) async {
    try {
      await repository.markAllMessagesAsRead();

      if (state is CommunicationLoadedState) {
        final currentState = state as CommunicationLoadedState;
        emit(currentState.copyWith(
          unreadMessagesCount: 0,
          successMessage: 'All messages marked as read',
        ));
      }
    } catch (e) {
      emit(CommunicationErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onClearMissedCalls(
    ClearMissedCallsEvent event,
    Emitter<CommunicationState> emit,
  ) async {
    try {
      await repository.clearMissedCalls();

      if (state is CommunicationLoadedState) {
        final currentState = state as CommunicationLoadedState;
        emit(currentState.copyWith(
          missedCallsCount: 0,
          missedVideoCallsCount: 0,
          successMessage: 'Missed calls cleared',
        ));
      }
    } catch (e) {
      emit(CommunicationErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // ============================================================================
  // SEND MESSAGE
  // ============================================================================

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<CommunicationState> emit,
  ) async {
    emit(const MessageSending());

    try {
      final newMessage = await repository.sendMessage(
        contactId: event.contactId,
        message: event.message,
      );

      // Reload communications
      add(const RefreshCommunicationsEvent());
    } catch (e) {
      emit(CommunicationErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // ============================================================================
  // INITIATE CALLS
  // ============================================================================

  Future<void> _onInitiateVoiceCall(
    InitiateVoiceCallEvent event,
    Emitter<CommunicationState> emit,
  ) async {
    emit(const CallInitiating(CommunicationType.voiceCall));

    try {
      final call = await repository.initiateVoiceCall(event.contactId);

      // Reload communications
      add(const RefreshCommunicationsEvent());
    } catch (e) {
      emit(CommunicationErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onInitiateVideoCall(
    InitiateVideoCallEvent event,
    Emitter<CommunicationState> emit,
  ) async {
    emit(const CallInitiating(CommunicationType.videoCall));

    try {
      final call = await repository.initiateVideoCall(event.contactId);

      // Reload communications
      add(const RefreshCommunicationsEvent());
    } catch (e) {
      emit(CommunicationErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // ============================================================================
  // CACHE
  // ============================================================================

  Future<void> _onClearCache(
    ClearCommunicationCacheEvent event,
    Emitter<CommunicationState> emit,
  ) async {
    try {
      await repository.clearCache();
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
}


