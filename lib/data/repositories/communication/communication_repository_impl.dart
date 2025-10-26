import 'dart:convert';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/communication/models/communication_item.dart';
import '../base_repository.dart';
import 'communication_repository.dart';

/// Implementation of CommunicationRepository
/// Handles communication data (messages, calls, video calls)
class CommunicationRepositoryImpl extends BaseRepository implements CommunicationRepository {
  final ApiService apiService;
  final StorageService storageService;

  CommunicationRepositoryImpl({
    required this.apiService,
    required this.storageService,
  });

  // ============================================================================
  // COMMUNICATIONS LIST
  // ============================================================================

  @override
  Future<List<CommunicationItem>> getAllCommunications({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      // Try cache first
      final cached = await getCachedCommunications();
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }

      final astrologerId = await _getAstrologerId();
      final response = await apiService.get(
        '/api/communications/$astrologerId',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.data['success'] == true) {
        final List<dynamic> itemsData = response.data['data'] ?? [];
        final items = itemsData
            .map((json) => CommunicationItem.fromJson(json))
            .toList();
        
        // Cache the result
        await cacheCommunications(items);
        
        return items;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load communications');
      }
    } catch (e) {
      // Fallback to cache on error
      final cached = await getCachedCommunications();
      if (cached != null) {
        return cached;
      }
      throw Exception(handleError(e));
    }
  }

  @override
  Future<List<CommunicationItem>> getFilteredCommunications({
    required CommunicationFilter filter,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final allItems = await getAllCommunications(page: page, limit: limit);
      
      switch (filter) {
        case CommunicationFilter.all:
          return allItems;
        case CommunicationFilter.calls:
          return allItems
              .where((item) => item.type == CommunicationType.voiceCall)
              .toList();
        case CommunicationFilter.messages:
          return allItems
              .where((item) => item.type == CommunicationType.message)
              .toList();
        case CommunicationFilter.video:
          return allItems
              .where((item) => item.type == CommunicationType.videoCall)
              .toList();
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  // ============================================================================
  // UNREAD COUNTS
  // ============================================================================

  @override
  Future<Map<String, int>> getUnreadCounts() async {
    try {
      final astrologerId = await _getAstrologerId();
      final response = await apiService.get(
        '/api/communications/$astrologerId/unread-counts',
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        return {
          'messages': data['messages'] ?? 0,
          'missedCalls': data['missedCalls'] ?? 0,
          'missedVideoCalls': data['missedVideoCalls'] ?? 0,
        };
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load unread counts');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  // ============================================================================
  // MARK AS READ
  // ============================================================================

  @override
  Future<void> markMessageAsRead(String messageId) async {
    try {
      final response = await apiService.patch(
        '/api/communications/messages/$messageId/read',
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to mark message as read');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<void> markAllMessagesAsRead() async {
    try {
      final astrologerId = await _getAstrologerId();
      final response = await apiService.patch(
        '/api/communications/$astrologerId/messages/mark-all-read',
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to mark all messages as read');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<void> clearMissedCalls() async {
    try {
      final astrologerId = await _getAstrologerId();
      final response = await apiService.patch(
        '/api/communications/$astrologerId/calls/clear-missed',
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to clear missed calls');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  // ============================================================================
  // SEND MESSAGE
  // ============================================================================

  @override
  Future<CommunicationItem> sendMessage({
    required String contactId,
    required String message,
  }) async {
    try {
      final astrologerId = await _getAstrologerId();
      final response = await apiService.post(
        '/api/communications/$astrologerId/messages',
        data: {
          'contactId': contactId,
          'message': message,
        },
      );

      if (response.data['success'] == true) {
        return CommunicationItem.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to send message');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  // ============================================================================
  // INITIATE CALLS
  // ============================================================================

  @override
  Future<CommunicationItem> initiateVoiceCall(String contactId) async {
    try {
      final astrologerId = await _getAstrologerId();
      final response = await apiService.post(
        '/api/communications/$astrologerId/calls/voice',
        data: {'contactId': contactId},
      );

      if (response.data['success'] == true) {
        return CommunicationItem.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to initiate voice call');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<CommunicationItem> initiateVideoCall(String contactId) async {
    try {
      final astrologerId = await _getAstrologerId();
      final response = await apiService.post(
        '/api/communications/$astrologerId/calls/video',
        data: {'contactId': contactId},
      );

      if (response.data['success'] == true) {
        return CommunicationItem.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to initiate video call');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  // ============================================================================
  // CACHE MANAGEMENT
  // ============================================================================

  @override
  Future<void> cacheCommunications(List<CommunicationItem> items) async {
    try {
      final jsonString = jsonEncode(
        items.map((item) => item.toJson()).toList(),
      );
      await storageService.setString('communications_cache', jsonString);
      await storageService.setString(
        'communications_cache_timestamp',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('Error caching communications: $e');
    }
  }

  @override
  Future<List<CommunicationItem>?> getCachedCommunications() async {
    try {
      final jsonString = await storageService.getString('communications_cache');
      final timestamp = await storageService.getString('communications_cache_timestamp');

      if (jsonString != null && timestamp != null) {
        final cacheTime = DateTime.parse(timestamp);
        // Cache valid for 2 minutes (real-time data)
        if (DateTime.now().difference(cacheTime).inMinutes < 2) {
          final List<dynamic> jsonList = jsonDecode(jsonString);
          return jsonList.map((json) => CommunicationItem.fromJson(json)).toList();
        }
      }
      return null;
    } catch (e) {
      print('Error getting cached communications: $e');
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await storageService.remove('communications_cache');
      await storageService.remove('communications_cache_timestamp');
    } catch (e) {
      print('Error clearing communications cache: $e');
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  Future<String> _getAstrologerId() async {
    try {
      final userData = await storageService.getUserData();
      if (userData != null) {
        final userDataMap = jsonDecode(userData);
        final astrologerId = userDataMap['id'] ?? userDataMap['_id'] as String?;
        if (astrologerId != null) {
          return astrologerId;
        }
      }
    } catch (e) {
      print('Error getting astrologer ID: $e');
    }
    throw Exception('Astrologer ID not found');
  }
}


