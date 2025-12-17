import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/di/service_locator.dart';
import '../models/communication_item.dart';
import '../models/message.dart';
import 'video_call_screen.dart';
import 'dart:async';

/// Generic ChatScreen that works for:
/// - Admin ↔ Astrologer communication
/// - User ↔ Astrologer communication (future)
/// - Astrologer ↔ Astrologer communication (future)
class ChatScreen extends StatefulWidget {
  final String contactId;          // Generic contact ID
  final String contactName;
  final ContactType contactType;   // 'admin', 'user', or 'astrologer'
  final String? conversationId;    // Link to backend conversation
  final String? avatarUrl;         // Contact avatar

  const ChatScreen({
    super.key,
    required this.contactId,
    required this.contactName,
    required this.contactType,
    this.conversationId,
    this.avatarUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _showEmojiPicker = false;
  bool _isComposing = false;
  
  // Services
  late final SocketService _socketService;
  late final ApiService _apiService;
  
  // State
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isOnline = false;
  bool _isTyping = false;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    
    // Initialize services
    _socketService = getIt<SocketService>();
    _apiService = getIt<ApiService>();
    
    // Load messages and setup real-time
    _loadMessages();
    _setupRealtimeMessaging();
    
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText != _isComposing) {
        setState(() {
          _isComposing = hasText;
        });
        
        // Send typing indicator
        if (hasText) {
          _sendTypingIndicator();
        }
      }
    });
    
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // Keyboard opened → scroll to bottom after layout
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    
    // Leave conversation room
    if (widget.conversationId != null) {
      _socketService.leaveDirectConversation(widget.conversationId!);
    }
    
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Load messages from backend via Socket.IO
  Future<void> _loadMessages() async {
    try {
      setState(() => _isLoading = true);
      
      final conversationId = widget.conversationId ?? 'admin_${widget.contactId}';
      
      // Request message history via Socket.IO
      _socketService.requestDirectMessageHistory(
        conversationId: conversationId,
        page: 1,
        limit: 50,
      );
      
      // Listen for history response (one-time)
      final historySubscription = _socketService.dmHistoryStream.listen((data) {
        try {
          if (data['conversationId'] == conversationId) {
            final messages = (data['messages'] as List?)
                ?.map((msg) => Message.fromJson(msg, currentUserId: _currentUserId))
                .toList() ?? [];
            
            if (mounted) {
              setState(() {
                _messages = messages;
                _isLoading = false;
              });
              
              _scrollToBottom();
            }
          }
        } catch (e) {
          print('❌ Error parsing message history: $e');
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      });
      
      // Cancel subscription after timeout
      Future.delayed(const Duration(seconds: 5), () {
        historySubscription.cancel();
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
          });
        }
      });
      
    } catch (e) {
      print('❌ Error loading messages: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Get the correct API endpoint based on contact type
  String _getMessagesEndpoint() {
    switch (widget.contactType) {
      case ContactType.admin:
        return '/api/conversations/admin/messages';
      case ContactType.user:
      case ContactType.astrologer:
        return '/api/conversations/${widget.conversationId}/messages';
    }
  }

  /// Setup Socket.IO for real-time messages
  void _setupRealtimeMessaging() {
    try {
      final conversationId = widget.conversationId ?? 'admin_${widget.contactId}';
      
      // Join conversation room
      _socketService.joinDirectConversation(
        conversationId: conversationId,
        userId: _currentUserId ?? '',
        userType: 'astrologer',
      );
      
      // Listen for incoming messages
      _messageSubscription = _socketService.dmMessageReceivedStream.listen((data) {
        try {
          final message = Message.fromJson(data, currentUserId: _currentUserId);
          
          // Only add if from this conversation
          if (message.conversationId == conversationId) {
            setState(() {
              _messages.add(message);
            });
            _scrollToBottom();
            
            // Mark as read
            _markMessageAsRead(message.id);
          }
        } catch (e) {
          print('❌ Error parsing message: $e');
        }
      });
      
      // Listen for typing indicators
      _typingSubscription = _socketService.dmTypingStream.listen((data) {
        if (data['conversationId'] == conversationId && data['userId'] != _currentUserId) {
          // Show typing indicator (optional)
          setState(() {
            _isTyping = true;
          });
          
          // Hide after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _isTyping = false;
              });
            }
          });
        }
      });
      
      print('✅ Real-time messaging setup for conversation: $conversationId');
    } catch (e) {
      print('❌ Error setting up real-time messaging: $e');
    }
  }

  /// Send typing indicator
  void _sendTypingIndicator() {
    try {
      _socketService.sendDirectMessageTyping(
        conversationId: widget.conversationId ?? 'admin_${widget.contactId}',
        userId: _currentUserId ?? '',
      );
    } catch (e) {
      print('❌ Error sending typing indicator: $e');
    }
  }

  /// Mark message as read
  Future<void> _markMessageAsRead(String messageId) async {
    try {
      _socketService.markDirectMessagesAsRead(
        conversationId: widget.conversationId ?? 'admin_${widget.contactId}',
        messageIds: [messageId],
      );
    } catch (e) {
      print('❌ Error marking message as read: $e');
    }
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
    if (_showEmojiPicker) {
      _focusNode.unfocus(); // Hide keyboard when showing emoji picker
      // Give time for emoji picker to animate in then scroll
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } else {
      _focusNode.requestFocus(); // Show keyboard when hiding emoji picker
      // Scroll after keyboard focus
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _onBackspacePressed() {
    final text = _messageController.text;
    if (text.isEmpty) return;
    
    // Get current cursor position
    final selection = _messageController.selection;
    if (!selection.isValid) return;
    
    final cursorPosition = selection.baseOffset;
    if (cursorPosition <= 0) return;
    
    // Handle emoji backspace properly (emojis can be multiple code units)
    final characters = text.characters;
    final charactersBefore = text.substring(0, cursorPosition).characters;
    final charactersAfter = text.substring(cursorPosition).characters;
    
    if (charactersBefore.isEmpty) return;
    
    // Remove one character before cursor
    final newTextBefore = charactersBefore.skipLast(1).toString();
    final newText = newTextBefore + charactersAfter.toString();
    
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newTextBefore.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back, color: themeService.textPrimary),
            ),
        title: Row(
          children: [
            // Show special icon for admin, avatar for others
            if (widget.contactType == ContactType.admin)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent,
                  color: Colors.blue,
                  size: 24,
                ),
              )
            else
              CircleAvatar(
                backgroundColor: themeService.primaryColor,
                backgroundImage: widget.avatarUrl != null
                    ? NetworkImage(widget.avatarUrl!)
                    : null,
                child: widget.avatarUrl == null
                    ? Text(
                        widget.contactName.split(' ').map((e) => e[0]).join(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contactName,
                    style: TextStyle(
                      color: themeService.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Show badge for admin
                  if (widget.contactType == ContactType.admin)
                    const Text(
                      'Support Team',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    Text(
                      _isOnline ? 'Online now' : 'Offline',
                      style: TextStyle(
                        color: _isOnline ? themeService.successColor : themeService.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Don't show call buttons for admin (admin will initiate)
          if (widget.contactType != ContactType.admin) ...[
            // Voice Call Button (Instagram-style)
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => _makeCall(),
                icon: const Icon(Icons.phone_rounded, color: Color(0xFF10B981)),
                tooltip: 'Voice Call',
              ),
            ),
            // Video Call Button (Instagram-style)
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => _makeVideoCall(),
                icon: const Icon(Icons.videocam_rounded, color: Color(0xFF8B5CF6)),
                tooltip: 'Video Call',
              ),
            ),
          ],
          // More Options
          IconButton(
            onPressed: () => _showOptionsMenu(),
            icon: Icon(Icons.more_vert_rounded, color: themeService.textPrimary),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: themeService.primaryColor,
                    ),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.contactType == ContactType.admin
                                  ? Icons.support_agent
                                  : Icons.chat_bubble_outline,
                              size: 64,
                              color: themeService.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.contactType == ContactType.admin
                                  ? 'Start a conversation with support'
                                  : 'No messages yet',
                              style: TextStyle(
                                color: themeService.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildMessageBubble(message, themeService);
                        },
                      ),
          ),
          // Message Input (WhatsApp-inspired)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: themeService.backgroundColor,
              border: Border(
                top: BorderSide(
                  color: themeService.borderColor.withOpacity(0.6),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Expanded input field with rounded design
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: themeService.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: themeService.borderColor.withOpacity(0.35),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Emoji icon (WhatsApp style - tappable)
                          GestureDetector(
                            onTap: _toggleEmojiPicker,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Icon(
                                _showEmojiPicker
                                    ? Icons.keyboard_rounded
                                    : Icons.emoji_emotions_outlined,
                                color: _showEmojiPicker
                                    ? themeService.primaryColor
                                    : themeService.textHint,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Text input
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              focusNode: _focusNode,
                              style: TextStyle(
                                color: themeService.textPrimary,
                                fontSize: 15,
                                height: 1.4,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Message',
                                hintStyle: TextStyle(
                                  color: themeService.textHint,
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 12,
                                ),
                              ),
                              maxLines: null,
                              minLines: 1,
                              maxLength: null,
                              textInputAction: TextInputAction.newline,
                              textCapitalization: TextCapitalization.sentences,
                              onTap: () {
                                if (_showEmojiPicker) {
                                  setState(() {
                                    _showEmojiPicker = false;
                                  });
                                }
                              },
                            ),
                          ),
                          // Attachments & Camera (inside input like WhatsApp)
                          IconButton(
                            icon: Icon(
                              Icons.attach_file_rounded,
                              color: themeService.textHint,
                              size: 22,
                            ),
                            onPressed: () {},
                            splashRadius: 22,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.camera_alt_rounded,
                              color: themeService.textHint,
                              size: 22,
                            ),
                            onPressed: () {},
                            splashRadius: 22,
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button (keeping it the same as requested)
                  GestureDetector(
                    onTap: _isComposing ? _sendMessage : null,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: themeService.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: themeService.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isComposing ? Icons.send_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Emoji Picker (WhatsApp-inspired)
          Offstage(
            offstage: !_showEmojiPicker,
            child: SizedBox(
              height: 280,
              child: EmojiPicker(
                textEditingController: _messageController,
                // onBackspacePressed: _onBackspacePressed, // Let the package handle it
                config: Config(
                  height: 256,
                  checkPlatformCompatibility: true,
                  emojiViewConfig: EmojiViewConfig(
                    backgroundColor: themeService.cardColor,
                    columns: 7,
                    emojiSizeMax: 28,
                    verticalSpacing: 0,
                    horizontalSpacing: 0,
                    gridPadding: EdgeInsets.zero,
                    recentsLimit: 28,
                    replaceEmojiOnLimitExceed: false,
                    noRecents: Text(
                      'No Recents',
                      style: TextStyle(
                        fontSize: 20,
                        color: themeService.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    buttonMode: ButtonMode.MATERIAL,
                  ),
                  skinToneConfig: SkinToneConfig(
                    enabled: true,
                    dialogBackgroundColor: themeService.cardColor,
                    indicatorColor: themeService.primaryColor,
                  ),
                  categoryViewConfig: CategoryViewConfig(
                    backgroundColor: themeService.cardColor,
                    iconColor: themeService.textSecondary,
                    iconColorSelected: themeService.primaryColor,
                    indicatorColor: themeService.primaryColor,
                    backspaceColor: themeService.primaryColor,
                    dividerColor: themeService.borderColor,
                    categoryIcons: const CategoryIcons(),
                    initCategory: Category.SMILEYS,
                  ),
                  bottomActionBarConfig: BottomActionBarConfig(
                    backgroundColor: themeService.cardColor,
                    buttonColor: themeService.surfaceColor,
                    buttonIconColor: themeService.textSecondary,
                    showSearchViewButton: false,
                  ),
                  searchViewConfig: SearchViewConfig(
                    backgroundColor: themeService.cardColor,
                    buttonIconColor: themeService.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildMessageBubble(Message message, ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) ...[
            // Show admin icon or user avatar
            if (widget.contactType == ContactType.admin)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent,
                  color: Colors.blue,
                  size: 18,
                ),
              )
            else
              CircleAvatar(
                radius: 16,
                backgroundColor: themeService.primaryColor,
                backgroundImage: widget.avatarUrl != null
                    ? NetworkImage(widget.avatarUrl!)
                    : null,
                child: widget.avatarUrl == null
                    ? Text(
                        widget.contactName.split(' ').map((e) => e[0]).join(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isMe 
                    ? themeService.primaryColor 
                    : (widget.contactType == ContactType.admin
                        ? Colors.blue.withOpacity(0.1)
                        : themeService.surfaceColor),
                border: widget.contactType == ContactType.admin && !message.isMe
                    ? Border.all(color: Colors.blue.withOpacity(0.3))
                    : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(message.isMe ? 18 : 6),
                  bottomRight: Radius.circular(message.isMe ? 6 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: message.isMe 
                          ? Colors.white 
                          : (widget.contactType == ContactType.admin && !message.isMe
                              ? Colors.blue.shade900
                              : themeService.textPrimary),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.formattedTime,
                        style: TextStyle(
                          color: message.isMe
                              ? Colors.white.withOpacity(0.7)
                              : themeService.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      if (message.isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.status == 'read'
                              ? Icons.done_all
                              : message.status == 'delivered'
                                  ? Icons.done_all
                                  : Icons.done,
                          size: 14,
                          color: message.status == 'read'
                              ? Colors.blue.shade300
                              : Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (message.isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: themeService.surfaceColor,
              child: Icon(
                Icons.person,
                color: themeService.textSecondary,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    try {
      final conversationId = widget.conversationId ?? 'admin_${widget.contactId}';
      
      // Send via Socket.IO for real-time delivery & persistence
      _socketService.sendDirectMessage(
        conversationId: conversationId,
        recipientId: widget.contactId,
        recipientType: widget.contactType.name,
        content: text,
        messageType: 'text',
      );
      
      // Optimistic update
      final tempMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: conversationId,
        senderId: _currentUserId ?? 'me',
        senderType: 'astrologer',
        content: text,
        timestamp: DateTime.now(),
        isMe: true,
        status: 'sent',
      );
      
      setState(() {
        _messages.add(tempMessage);
      });
      
      _messageController.clear();
      _scrollToBottom();
      
      print('✅ Message sent via Socket.IO: $text');
    } catch (e) {
      print('❌ Error sending message: $e');
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getSendMessageEndpoint() {
    switch (widget.contactType) {
      case ContactType.admin:
        return '/api/conversations/admin/messages';
      case ContactType.user:
      case ContactType.astrologer:
        return '/api/conversations/${widget.conversationId}/messages';
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

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.blue),
              title: const Text('Video Call'),
              onTap: () {
                Navigator.pop(context);
                _initiateVideoCall();
              },
            ),
            ListTile(
              leading: const Icon(Icons.call, color: Colors.green),
              title: const Text('Voice Call'),
              onTap: () {
                Navigator.pop(context);
                _makeCall();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.orange),
              title: const Text('Contact Info'),
              onTap: () {
                Navigator.pop(context);
                _showContactInfo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Block Contact'),
              onTap: () {
                Navigator.pop(context);
                _blockContact();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _initiateVideoCall() {
    print('🎥 Video call initiated for: ${widget.contactName}');
    
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            contactId: widget.contactId,
            contactName: widget.contactName,
            contactType: widget.contactType,
            isIncoming: false,
            avatarUrl: widget.avatarUrl,
          ),
        ),
      );
    } catch (e) {
      print('❌ Error opening video call: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening video call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _makeCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${widget.contactName}...'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
  
  void _makeVideoCall() {
    _initiateVideoCall();
  }

  void _showContactInfo() {
    // Show contact info dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Name: ${widget.contactName}'),
            const Text('Phone: +91 98765 43210'),
            const Text('Last seen: Just now'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _blockContact() {
    // Show block contact confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Contact'),
        content: Text('Are you sure you want to block ${widget.contactName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.contactName} has been blocked'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

}
































