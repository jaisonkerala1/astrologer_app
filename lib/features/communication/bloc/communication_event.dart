import 'package:equatable/equatable.dart';
import '../models/communication_item.dart';

/// Abstract base class for all Communication events
abstract class CommunicationEvent extends Equatable {
  const CommunicationEvent();

  @override
  List<Object?> get props => [];
}

// ============================================================================
// LOAD EVENTS
// ============================================================================

/// Event to load all communications
class LoadCommunicationsEvent extends CommunicationEvent {
  final int page;

  const LoadCommunicationsEvent({this.page = 1});

  @override
  List<Object?> get props => [page];
}

/// Event to filter communications
class FilterCommunicationsEvent extends CommunicationEvent {
  final CommunicationFilter filter;

  const FilterCommunicationsEvent(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// Event to refresh communications
class RefreshCommunicationsEvent extends CommunicationEvent {
  const RefreshCommunicationsEvent();
}

// ============================================================================
// UNREAD COUNTS EVENTS
// ============================================================================

/// Event to load unread counts
class LoadUnreadCountsEvent extends CommunicationEvent {
  const LoadUnreadCountsEvent();
}

// ============================================================================
// MARK AS READ EVENTS
// ============================================================================

/// Event to mark a message as read
class MarkMessageAsReadEvent extends CommunicationEvent {
  final String messageId;

  const MarkMessageAsReadEvent(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

/// Event to mark all messages as read
class MarkAllMessagesAsReadEvent extends CommunicationEvent {
  const MarkAllMessagesAsReadEvent();
}

/// Event to clear missed calls
class ClearMissedCallsEvent extends CommunicationEvent {
  const ClearMissedCallsEvent();
}

// ============================================================================
// SEND MESSAGE EVENT
// ============================================================================

/// Event to send a message
class SendMessageEvent extends CommunicationEvent {
  final String contactId;
  final String message;

  const SendMessageEvent({
    required this.contactId,
    required this.message,
  });

  @override
  List<Object?> get props => [contactId, message];
}

// ============================================================================
// CALL EVENTS
// ============================================================================

/// Event to initiate a voice call
class InitiateVoiceCallEvent extends CommunicationEvent {
  final String contactId;

  const InitiateVoiceCallEvent(this.contactId);

  @override
  List<Object?> get props => [contactId];
}

/// Event to initiate a video call
class InitiateVideoCallEvent extends CommunicationEvent {
  final String contactId;

  const InitiateVideoCallEvent(this.contactId);

  @override
  List<Object?> get props => [contactId];
}

// ============================================================================
// CACHE EVENT
// ============================================================================

/// Event to clear cache
class ClearCommunicationCacheEvent extends CommunicationEvent {
  const ClearCommunicationCacheEvent();
}


