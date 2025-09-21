import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/services/storage_service.dart';
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
  
  static const String _openRouterApiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _apiKey = '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';
  static const String _model = 'anthropic/claude-3-haiku';

  void initialize() {
    _dio.options.baseUrl = _openRouterApiUrl;
    _dio.options.headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://astrologer-app.com',
      'X-Title': 'Astrologer App',
    };
    
    // Add request interceptor for debugging
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('OpenRouter API Request: ${options.method} ${options.path}');
        print('Headers: ${options.headers}');
        print('Data: ${options.data}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('OpenRouter API Response: ${response.statusCode}');
        print('Response Data: ${response.data}');
        handler.next(response);
      },
      onError: (error, handler) {
        print('OpenRouter API Error: ${error.message}');
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
      // Build context for Loona
      final context = _buildContext(userProfile, settings);
      
      // Prepare messages for the API
      final messages = _prepareMessages(context, conversationHistory, userMessage);
      
      final response = await _dio.post('', data: {
        'model': _model,
        'messages': messages,
        'max_tokens': 800,
        'temperature': 0.3,
        'top_p': 0.8,
        'frequency_penalty': 0.0,
        'presence_penalty': 0.0,
      });

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'];
        return content.toString().trim();
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

  String _buildContext(AstrologerModel? userProfile, ChatSettings? settings) {
    final buffer = StringBuffer();
    
    // Loona's professional identity and role
    buffer.writeln("You are Loona, a professional AI assistant specialized in astrology and designed to support professional astrologers. You provide accurate, insightful, and helpful guidance while maintaining the highest standards of professionalism.");
    buffer.writeln();
    
    // Core expertise areas
    buffer.writeln("Your Expertise:");
    buffer.writeln("- Advanced astrological knowledge including natal charts, transits, progressions, and synastry");
    buffer.writeln("- Professional astrology practice guidance and business advice");
    buffer.writeln("- App features and functionality support");
    buffer.writeln("- Client consultation best practices");
    buffer.writeln("- Astrological software and tools guidance");
    buffer.writeln();
    
    // User context if available and sharing is enabled
    if (userProfile != null && (settings?.shareUserInfo ?? true)) {
      buffer.writeln("Astrologer Profile:");
      buffer.writeln("- Name: ${userProfile.name}");
      buffer.writeln("- Professional Experience: ${userProfile.experience} years");
      buffer.writeln("- Specializations: ${userProfile.specializations.join(', ')}");
      buffer.writeln("- Languages: ${userProfile.languages.join(', ')}");
      buffer.writeln();
    }
    
    // Professional guidelines for responses
    buffer.writeln("Professional Guidelines:");
    buffer.writeln("- Maintain a professional yet approachable tone");
    buffer.writeln("- Provide accurate, evidence-based astrological information");
    buffer.writeln("- Offer practical solutions and actionable advice");
    buffer.writeln("- Respect the astrologer's expertise and experience level");
    buffer.writeln("- Keep responses focused, informative, and relevant");
    buffer.writeln("- Acknowledge limitations and suggest professional resources when appropriate");
    buffer.writeln("- Support the astrologer's professional growth and client service quality");
    buffer.writeln("- Never make medical, legal, or financial advice outside astrological context");
    buffer.writeln("- Encourage ethical and responsible astrological practice");
    
    return buffer.toString();
  }

  List<Map<String, String>> _prepareMessages(
    String context,
    List<ChatMessage> conversationHistory,
    String userMessage,
  ) {
    final messages = <Map<String, String>>[];
    
    // Add system context
    messages.add({
      'role': 'system',
      'content': context,
    });
    
    // Add conversation history (last 8 messages to keep context manageable but comprehensive)
    final recentHistory = conversationHistory.take(8).toList();
    for (final message in recentHistory) {
      messages.add({
        'role': message.isFromUser ? 'user' : 'assistant',
        'content': message.content,
      });
    }
    
    // Add current user message
    messages.add({
      'role': 'user',
      'content': userMessage,
    });
    
    return messages;
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
