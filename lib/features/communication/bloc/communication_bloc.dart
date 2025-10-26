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
  // LOAD COMMUNICATIONS
  // ============================================================================

  Future<void> _onLoadCommunications(
    LoadCommunicationsEvent event,
    Emitter<CommunicationState> emit,
  ) async {
    emit(const CommunicationLoading());

    try {
      final communications = await repository.getAllCommunications(page: event.page);
      final unreadCounts = await repository.getUnreadCounts();

      emit(CommunicationLoadedState(
        allCommunications: communications,
        activeFilter: CommunicationFilter.all,
        unreadMessagesCount: unreadCounts['messages'] ?? 0,
        missedCallsCount: unreadCounts['missedCalls'] ?? 0,
        missedVideoCallsCount: unreadCounts['missedVideoCalls'] ?? 0,
      ));
    } catch (e) {
      emit(CommunicationErrorState(e.toString().replaceAll('Exception: ', '')));
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
    add(const LoadCommunicationsEvent());
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


