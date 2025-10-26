import 'package:equatable/equatable.dart';
import '../models/communication_item.dart';

/// Abstract base class for all Communication states
abstract class CommunicationState extends Equatable {
  const CommunicationState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class CommunicationInitial extends CommunicationState {
  const CommunicationInitial();
}

/// Loading state
class CommunicationLoading extends CommunicationState {
  final bool isInitialLoad;

  const CommunicationLoading({this.isInitialLoad = true});

  @override
  List<Object?> get props => [isInitialLoad];
}

/// Loaded state
class CommunicationLoadedState extends CommunicationState {
  final List<CommunicationItem> allCommunications;
  final CommunicationFilter activeFilter;
  final int unreadMessagesCount;
  final int missedCallsCount;
  final int missedVideoCallsCount;
  final String? successMessage;

  CommunicationLoadedState({
    required this.allCommunications,
    required this.activeFilter,
    required this.unreadMessagesCount,
    required this.missedCallsCount,
    required this.missedVideoCallsCount,
    this.successMessage,
  });

  @override
  List<Object?> get props => [
        allCommunications,
        activeFilter,
        unreadMessagesCount,
        missedCallsCount,
        missedVideoCallsCount,
        successMessage,
      ];

  /// Copy with method
  CommunicationLoadedState copyWith({
    List<CommunicationItem>? allCommunications,
    CommunicationFilter? activeFilter,
    int? unreadMessagesCount,
    int? missedCallsCount,
    int? missedVideoCallsCount,
    String? successMessage,
  }) {
    return CommunicationLoadedState(
      allCommunications: allCommunications ?? this.allCommunications,
      activeFilter: activeFilter ?? this.activeFilter,
      unreadMessagesCount: unreadMessagesCount ?? this.unreadMessagesCount,
      missedCallsCount: missedCallsCount ?? this.missedCallsCount,
      missedVideoCallsCount: missedVideoCallsCount ?? this.missedVideoCallsCount,
      successMessage: successMessage,
    );
  }

  /// Get filtered communications
  List<CommunicationItem> get filteredCommunications {
    switch (activeFilter) {
      case CommunicationFilter.all:
        return allCommunications;
      case CommunicationFilter.calls:
        return allCommunications
            .where((item) => item.type == CommunicationType.voiceCall)
            .toList();
      case CommunicationFilter.messages:
        return allCommunications
            .where((item) => item.type == CommunicationType.message)
            .toList();
      case CommunicationFilter.video:
        return allCommunications
            .where((item) => item.type == CommunicationType.videoCall)
            .toList();
    }
  }

  /// Get total unread count
  int get totalUnreadCount =>
      unreadMessagesCount + missedCallsCount + missedVideoCallsCount;

  /// Get count for specific filter
  int getCountForFilter(CommunicationFilter filter) {
    switch (filter) {
      case CommunicationFilter.all:
        return allCommunications.length;
      case CommunicationFilter.calls:
        return allCommunications
            .where((item) => item.type == CommunicationType.voiceCall)
            .length;
      case CommunicationFilter.messages:
        return allCommunications
            .where((item) => item.type == CommunicationType.message)
            .length;
      case CommunicationFilter.video:
        return allCommunications
            .where((item) => item.type == CommunicationType.videoCall)
            .length;
    }
  }

  /// Get messages
  List<CommunicationItem> get messages {
    return allCommunications
        .where((item) => item.type == CommunicationType.message)
        .toList();
  }

  /// Get calls
  List<CommunicationItem> get calls {
    return allCommunications
        .where((item) => item.type == CommunicationType.voiceCall)
        .toList();
  }

  /// Get video calls
  List<CommunicationItem> get videoCalls {
    return allCommunications
        .where((item) => item.type == CommunicationType.videoCall)
        .toList();
  }

  /// Check if has unread
  bool get hasUnread => totalUnreadCount > 0;
}

/// Error state
class CommunicationErrorState extends CommunicationState {
  final String message;

  const CommunicationErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

/// Message sending state
class MessageSending extends CommunicationState {
  const MessageSending();
}

/// Call initiating state
class CallInitiating extends CommunicationState {
  final CommunicationType callType;

  const CallInitiating(this.callType);

  @override
  List<Object?> get props => [callType];
}


