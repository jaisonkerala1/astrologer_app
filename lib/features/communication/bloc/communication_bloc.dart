import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/communication/communication_repository.dart';
import '../../../core/services/socket_service.dart';
import '../models/communication_item.dart';
import 'communication_event.dart';
import 'communication_state.dart';

/// BLoC for managing communication (messages, calls, video calls)
/// Follows clean architecture principles with repository pattern
class CommunicationBloc extends Bloc<CommunicationEvent, CommunicationState> {
  final CommunicationRepository repository;
  final SocketService socketService;
  StreamSubscription<Map<String, dynamic>>? _dmSub;

  CommunicationBloc({required this.repository, required this.socketService})
      : super(const CommunicationInitial()) {
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

    // Listen globally for direct messages (admin/user -> astrologer)
    _dmSub = socketService.dmGlobalStream.listen(_handleIncomingDm);
  }

  // Handle incoming DM to update list + unread counts
  void _handleIncomingDm(Map<String, dynamic> data) {
    if (state is! CommunicationLoadedState) return;
    final currentState = state as CommunicationLoadedState;

    final conversationId = (data['conversationId'] ?? '').toString();
    if (conversationId.isEmpty) return;

    final senderType = (data['senderType'] ?? '').toString();
    final senderId = (data['senderId'] ?? '').toString();
    final senderName = (data['senderName'] ?? 'User').toString();
    final content = (data['content'] ?? '').toString();
    final tsString = data['timestamp']?.toString();
    final timestamp = tsString != null ? DateTime.tryParse(tsString) ?? DateTime.now() : DateTime.now();

    String contactName;
    ContactType contactType;
    String contactId;
    switch (senderType) {
      case 'admin':
        contactName = 'Admin Support';
        contactType = ContactType.admin;
        contactId = 'admin';
        break;
      case 'astrologer':
        contactName = senderName.isNotEmpty ? senderName : 'Astrologer';
        contactType = ContactType.astrologer;
        contactId = senderId;
        break;
      default:
        contactName = senderName.isNotEmpty ? senderName : 'User';
        contactType = ContactType.user;
        contactId = senderId;
    }

    final updated = List<CommunicationItem>.from(currentState.allCommunications);
    final idx = updated.indexWhere((c) =>
        (c.conversationId != null && c.conversationId == conversationId) ||
        (c.contactId == contactId && c.contactType == contactType));

    if (idx >= 0) {
      final existing = updated[idx];
      updated[idx] = CommunicationItem(
        id: existing.id,
        type: existing.type,
        contactName: existing.contactName,
        contactId: existing.contactId,
        contactType: existing.contactType,
        avatar: existing.avatar,
        timestamp: timestamp,
        preview: content,
        unreadCount: existing.unreadCount + 1,
        isOnline: true,
        status: existing.status,
        duration: existing.duration,
        chargedAmount: existing.chargedAmount,
        sessionId: existing.sessionId,
        conversationId: existing.conversationId ?? conversationId,
      );
    } else {
      updated.insert(
        0,
        CommunicationItem(
          id: conversationId.isNotEmpty ? conversationId : DateTime.now().millisecondsSinceEpoch.toString(),
          type: CommunicationType.message,
          contactName: contactName,
          contactId: contactId,
          contactType: contactType,
          avatar: '',
          timestamp: timestamp,
          preview: content,
          unreadCount: 1,
          isOnline: true,
          status: CommunicationStatus.received,
          conversationId: conversationId,
        ),
      );
    }

    emit(currentState.copyWith(
      allCommunications: updated,
      unreadMessagesCount: currentState.unreadMessagesCount + 1,
    ));
  }

  @override
  Future<void> close() {
    _dmSub?.cancel();
    return super.close();
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


