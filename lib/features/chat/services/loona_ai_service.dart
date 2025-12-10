import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/api_constants.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/chat_settings.dart';
import '../../auth/models/astrologer_model.dart';
import 'chat_api_service.dart';

class LoonaAIService {
  static final LoonaAIService _instance = LoonaAIService._internal();
  factory LoonaAIService() => _instance;
  LoonaAIService._internal();

  final Dio _dio = Dio();
  final StorageService _storageService = StorageService();
  final ChatApiService _chatApiService = ChatApiService();

  void initialize() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    _dio.options.connectTimeout = const Duration(milliseconds: ApiConstants.connectTimeout);
    _dio.options.receiveTimeout = const Duration(milliseconds: ApiConstants.receiveTimeout);
    
    // Add request interceptor for debugging
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('Loona API Request: ${options.method} ${options.path}');
        print('Data: ${options.data}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('Loona API Response: ${response.statusCode}');
        print('Response Data: ${response.data}');
        handler.next(response);
      },
      onError: (error, handler) {
        print('Loona API Error: ${error.message}');
        print('Error Response: ${error.response?.data}');
        handler.next(error);
      },
    ));
  }

  Future<String> generateResponse({
    required String userMessage,
    required List<ChatMessage> conversationHistory,
    AstrologerModel? userProfile,
    ChatSettings? settings,
  }) async {
    try {
      // Prepare conversation history (non-typing messages only)
      final history = conversationHistory
          .where((m) => !m.isTyping)
          .map((m) => {
                'content': m.content,
                'isFromUser': m.isFromUser,
                'timestamp': m.timestamp.toIso8601String(),
              })
          .toList();
      
      // Prepare user profile data
      Map<String, dynamic>? profileData;
      if (userProfile != null) {
        profileData = {
          'name': userProfile.name,
          'experience': userProfile.experience,
          'specializations': userProfile.specializations,
          'languages': userProfile.languages,
        };
      }

      // Prepare settings data
      Map<String, dynamic>? settingsData;
      if (settings != null) {
        settingsData = {
          'shareUserInfo': settings.shareUserInfo,
        };
      }

      // Call backend endpoint
      final response = await _dio.post(
        ApiConstants.loonaGenerate,
        data: {
          'userMessage': userMessage,
          'conversationHistory': history,
          'userProfile': profileData,
          'settings': settingsData,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final aiResponse = response.data['data']['response'];
        return aiResponse.toString().trim();
      } else {
        throw Exception('Failed to get response from Loona AI');
      }
    } catch (e) {
      print('Loona AI Service Error: $e');
      print('Error type: ${e.runtimeType}');
      if (e is DioException) {
        print('Dio Error: ${e.message}');
        print('Response: ${e.response?.data}');
        print('Status Code: ${e.response?.statusCode}');
      }
      return _getFallbackResponse(userProfile);
    }
  }

  String _getFallbackResponse(AstrologerModel? userProfile) {
    final professionalGreetings = [
      "Hello! I'm Loona, your professional AI assistant. I'm here to support your astrological practice with expert guidance and app assistance.",
      "Greetings! I'm Loona, specializing in professional astrology support. How may I assist you with your practice today?",
      "Welcome! I'm Loona, your dedicated AI assistant for professional astrology guidance and app support.",
    ];
    
    if (userProfile != null) {
      return "Hello ${userProfile.name}! I'm Loona, your professional AI assistant. I'm here to support your astrological practice with expert guidance, app assistance, and professional insights. How may I help you today?";
    }
    
    return professionalGreetings[DateTime.now().millisecond % professionalGreetings.length];
  }

  // Save conversation to both local and API storage
  Future<void> saveConversation(Conversation conversation) async {
    try {
      // Save to local storage
      final conversations = await getConversations();
      conversations.removeWhere((c) => c.id == conversation.id);
      conversations.add(conversation);
      
      final conversationsJson = conversations.map((c) => c.toJson()).toList();
      await _storageService.setString('loona_conversations', jsonEncode(conversationsJson));
      
      // Try to save to API if user is available
      if (conversation.userId.isNotEmpty) {
        try {
          await _chatApiService.addMessage(conversation.id, conversation.messages.last);
        } catch (e) {
          print('Error saving to API (will use local storage): $e');
        }
      }
    } catch (e) {
      print('Error saving conversation: $e');
    }
  }

  // Get all conversations from local storage
  Future<List<Conversation>> getConversations() async {
    try {
      final conversationsJson = await _storageService.getString('loona_conversations');
      if (conversationsJson == null) return [];
      
      final List<dynamic> conversationsList = jsonDecode(conversationsJson);
      return conversationsList.map((json) => Conversation.fromJson(json)).toList();
    } catch (e) {
      print('Error loading conversations: $e');
      return [];
    }
  }

  // Get active conversation
  Future<Conversation?> getActiveConversation() async {
    try {
      final conversations = await getConversations();
      return conversations.where((c) => c.isActive).firstOrNull;
    } catch (e) {
      print('Error getting active conversation: $e');
      return null;
    }
  }

  // Create new conversation
  Future<Conversation> createNewConversation(String userId) async {
    try {
      // Try to create via API first
      final apiConversation = await _chatApiService.createConversation(userId);
      if (apiConversation != null) {
        await saveConversation(apiConversation);
        return apiConversation;
      }
    } catch (e) {
      print('Error creating conversation via API, using local storage: $e');
    }
    
    // Fallback to local storage
    final conversation = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: 'New Chat with Loona',
      messages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await saveConversation(conversation);
    return conversation;
  }

  // Add message to conversation
  Future<void> addMessageToConversation(String conversationId, ChatMessage message) async {
    try {
      final conversations = await getConversations();
      final conversationIndex = conversations.indexWhere((c) => c.id == conversationId);
      
      if (conversationIndex != -1) {
        final conversation = conversations[conversationIndex];
        final updatedMessages = List<ChatMessage>.from(conversation.messages)..add(message);
        
        final updatedConversation = conversation.copyWith(
          messages: updatedMessages,
          updatedAt: DateTime.now(),
        );
        
        conversations[conversationIndex] = updatedConversation;
        
        final conversationsJson = conversations.map((c) => c.toJson()).toList();
        await _storageService.setString('loona_conversations', jsonEncode(conversationsJson));
      }
    } catch (e) {
      print('Error adding message to conversation: $e');
    }
  }

  // Clear all conversations
  Future<void> clearAllConversations() async {
    try {
      // Clear local storage
      await _storageService.remove('loona_conversations');
      
      // Try to clear via API if user is available
      final conversations = await getConversations();
      if (conversations.isNotEmpty && conversations.first.userId.isNotEmpty) {
        try {
          await _chatApiService.clearHistory(conversations.first.userId);
        } catch (e) {
          print('Error clearing via API (local storage cleared): $e');
        }
      }
    } catch (e) {
      print('Error clearing conversations: $e');
    }
  }

  // Save chat settings
  Future<void> saveChatSettings(ChatSettings settings) async {
    try {
      await _storageService.setString('loona_chat_settings', jsonEncode(settings.toJson()));
    } catch (e) {
      print('Error saving chat settings: $e');
    }
  }

  // Get chat settings
  Future<ChatSettings> getChatSettings() async {
    try {
      final settingsJson = await _storageService.getString('loona_chat_settings');
      if (settingsJson == null) {
        return ChatSettings(lastCleared: DateTime.now());
      }
      
      return ChatSettings.fromJson(jsonDecode(settingsJson));
    } catch (e) {
      print('Error loading chat settings: $e');
      return ChatSettings(lastCleared: DateTime.now());
    }
  }
}
