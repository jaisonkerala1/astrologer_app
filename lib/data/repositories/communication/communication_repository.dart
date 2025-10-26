import '../../../features/communication/models/communication_item.dart';

/// Abstract interface for Communication operations
abstract class CommunicationRepository {
  // Communications list
  Future<List<CommunicationItem>> getAllCommunications({
    int page = 1,
    int limit = 50,
  });
  
  Future<List<CommunicationItem>> getFilteredCommunications({
    required CommunicationFilter filter,
    int page = 1,
    int limit = 50,
  });
  
  // Unread counts
  Future<Map<String, int>> getUnreadCounts();
  
  // Mark as read
  Future<void> markMessageAsRead(String messageId);
  Future<void> markAllMessagesAsRead();
  Future<void> clearMissedCalls();
  
  // Send message
  Future<CommunicationItem> sendMessage({
    required String contactId,
    required String message,
  });
  
  // Initiate call
  Future<CommunicationItem> initiateVoiceCall(String contactId);
  Future<CommunicationItem> initiateVideoCall(String contactId);
  
  // Cache management
  Future<void> cacheCommunications(List<CommunicationItem> items);
  Future<List<CommunicationItem>?> getCachedCommunications();
  Future<void> clearCache();
}


