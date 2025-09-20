import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/chat_settings.dart';
import '../services/loona_ai_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/chat_settings_dialog.dart';
import '../widgets/chat_suggestions.dart';
import '../../auth/models/astrologer_model.dart';
import '../../../shared/theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final AstrologerModel? userProfile;

  const ChatScreen({
    super.key,
    this.userProfile,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final LoonaAIService _loonaService = LoonaAIService();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  
  Conversation? _currentConversation;
  ChatSettings? _chatSettings;
  bool _isLoading = false;
  bool _isInitialized = false;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeChat();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _initializeChat() async {
    try {
      _loonaService.initialize();
      
      // Load chat settings
      _chatSettings = await _loonaService.getChatSettings();
      
      // Load or create conversation
      _currentConversation = await _loonaService.getActiveConversation();
      if (_currentConversation == null && widget.userProfile != null) {
        _currentConversation = await _loonaService.createNewConversation(widget.userProfile!.id);
      }
      
      // Load messages
      if (_currentConversation != null) {
        _messages.addAll(_currentConversation!.messages);
      }
      
      // Add welcome message if no messages
      if (_messages.isEmpty) {
        _addWelcomeMessage();
      }
      
      setState(() {
        _isInitialized = true;
      });
      
      _slideController.forward();
      _scrollToBottom();
    } catch (e) {
      print('Error initializing chat: $e');
      _addErrorMessage();
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: _getWelcomeMessage(),
      isFromUser: false,
      timestamp: DateTime.now(),
      conversationId: _currentConversation?.id,
    );
    
    _messages.add(welcomeMessage);
    _addMessageToConversation(welcomeMessage);
  }

  String _getWelcomeMessage() {
    if (widget.userProfile != null) {
      return "Hello ${widget.userProfile!.name}! I'm Loona, your AI companion. I'm here to help with astrology questions and guide you through the app. How can I assist you today?";
    }
    return "Hello! I'm Loona, your AI companion. I'm here to help with astrology questions and app guidance. How can I assist you today?";
  }

  void _addErrorMessage() {
    final errorMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: "Sorry, I'm having trouble connecting right now. Please try again later.",
      isFromUser: false,
      timestamp: DateTime.now(),
      conversationId: _currentConversation?.id,
    );
    
    _messages.add(errorMessage);
  }

  Future<void> _sendMessage(String content) async {
    if (content.trim().isEmpty || _isLoading) return;

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      isFromUser: true,
      timestamp: DateTime.now(),
      conversationId: _currentConversation?.id,
    );
    
    _messages.add(userMessage);
    _addMessageToConversation(userMessage);
    setState(() {});
    _scrollToBottom();

    // Show typing indicator
    final typingMessage = ChatMessage(
      id: 'typing_${DateTime.now().millisecondsSinceEpoch}',
      content: '',
      isFromUser: false,
      timestamp: DateTime.now(),
      conversationId: _currentConversation?.id,
      isTyping: true,
    );
    
    _messages.add(typingMessage);
    setState(() {
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      // Get AI response
      final response = await _loonaService.generateResponse(
        userMessage: content.trim(),
        conversationHistory: _messages.where((m) => !m.isTyping).toList(),
        userProfile: widget.userProfile,
        settings: _chatSettings,
      );

      // Remove typing indicator
      _messages.removeWhere((m) => m.isTyping);
      
      // Add AI response
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isFromUser: false,
        timestamp: DateTime.now(),
        conversationId: _currentConversation?.id,
      );
      
      _messages.add(aiMessage);
      _addMessageToConversation(aiMessage);
      
    } catch (e) {
      // Remove typing indicator
      _messages.removeWhere((m) => m.isTyping);
      
      // Add error message with more details
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: "Sorry, I encountered an error: ${e.toString()}. Please try again.",
        isFromUser: false,
        timestamp: DateTime.now(),
        conversationId: _currentConversation?.id,
      );
      
      _messages.add(errorMessage);
      _addMessageToConversation(errorMessage);
    }

    setState(() {
      _isLoading = false;
    });
    _scrollToBottom();
  }

  Future<void> _addMessageToConversation(ChatMessage message) async {
    if (_currentConversation != null) {
      await _loonaService.addMessageToConversation(_currentConversation!.id, message);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _showSettings() async {
    if (_chatSettings == null) return;
    
    final updatedSettings = await showDialog<ChatSettings>(
      context: context,
      builder: (context) => ChatSettingsDialog(
        currentSettings: _chatSettings!,
        onSettingsChanged: (settings) {
          _loonaService.saveChatSettings(settings);
        },
      ),
    );
    
    if (updatedSettings != null) {
      setState(() {
        _chatSettings = updatedSettings;
      });
    }
  }

  Future<void> _clearChatHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text('Are you sure you want to clear all chat history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _loonaService.clearAllConversations();
      setState(() {
        _messages.clear();
        _currentConversation = null;
      });
      _addWelcomeMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)], // Purple to blue-purple gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.nightlight_round,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Loona AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Your astrology companion',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _showSettings,
                    icon: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    onPressed: _clearChatHistory,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            
            // Messages
            Expanded(
              child: _isInitialized
                  ? Column(
                      children: [
                        // Show suggestions only if no messages or only welcome message
                        if (_messages.length <= 1)
                          ChatSuggestions(
                            onSuggestionTap: _sendMessage,
                          ),
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _messages.length,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              return ChatBubble(
                                message: message,
                                isTyping: message.isTyping,
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    ),
            ),
            
            // Input
            if (_isInitialized)
              ChatInput(
                onSendMessage: _sendMessage,
                isLoading: _isLoading,
                hintText: 'Ask Loona anything about astrology...',
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
