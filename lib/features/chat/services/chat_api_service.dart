import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/chat_settings.dart';

class ChatApiService {
  static final ChatApiService _instance = ChatApiService._internal();
  factory ChatApiService() => _instance;
  ChatApiService._internal();

  final ApiService _apiService = ApiService();

  // Get all conversations for a user
  Future<List<Conversation>> getConversations(String userId) async {
    try {
      final response = await _apiService.get('${ApiConstants.chatConversations}/$userId');
      
      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> conversationsJson = response.data['data'];
        return conversationsJson.map((json) => Conversation.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error getting conversations: $e');
      return [];
    }
  }

  // Get active conversation for a user
  Future<Conversation?> getActiveConversation(String userId) async {
    try {
      final response = await _apiService.get('${ApiConstants.chatActiveConversation}/$userId');
      
      if (response.statusCode == 200 && response.data['success']) {
        final conversationJson = response.data['data'];
        if (conversationJson != null) {
          return Conversation.fromJson(conversationJson);
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting active conversation: $e');
      return null;
    }
  }

  // Create new conversation
  Future<Conversation?> createConversation(String userId, {String? title}) async {
    try {
      final response = await _apiService.post(
        ApiConstants.chatCreateConversation,
        data: {
          'userId': userId,
          'title': title ?? 'New Chat with Loona',
        },
      );
      
      if (response.statusCode == 201 && response.data['success']) {
        final conversationJson = response.data['data'];
        return Conversation.fromJson(conversationJson);
      }
      
      return null;
    } catch (e) {
      print('Error creating conversation: $e');
      return null;
    }
  }

  // Add message to conversation
  Future<bool> addMessage(String conversationId, ChatMessage message) async {
    try {
      final response = await _apiService.post(
        '${ApiConstants.chatAddMessage}/$conversationId/messages',
        data: {
          'message': message.toJson(),
        },
      );
      
      return response.statusCode == 200 && response.data['success'];
    } catch (e) {
      print('Error adding message: $e');
      return false;
    }
  }

  // Update conversation settings
  Future<bool> updateSettings(String conversationId, ChatSettings settings) async {
    try {
      final response = await _apiService.put(
        '${ApiConstants.chatUpdateSettings}/$conversationId/settings',
        data: {
          'settings': settings.toJson(),
        },
      );
      
      return response.statusCode == 200 && response.data['success'];
    } catch (e) {
      print('Error updating settings: $e');
      return false;
    }
  }

  // Clear conversation history
  Future<bool> clearHistory(String userId) async {
    try {
      final response = await _apiService.delete('${ApiConstants.chatClearHistory}/$userId');
      
      return response.statusCode == 200 && response.data['success'];
    } catch (e) {
      print('Error clearing history: $e');
      return false;
    }
  }

  // Delete specific conversation
  Future<bool> deleteConversation(String conversationId) async {
    try {
      final response = await _apiService.delete('${ApiConstants.chatDeleteConversation}/$conversationId');
      
      return response.statusCode == 200 && response.data['success'];
    } catch (e) {
      print('Error deleting conversation: $e');
      return false;
    }
  }
}














