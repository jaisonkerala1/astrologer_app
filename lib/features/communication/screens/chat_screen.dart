import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import 'video_call_screen.dart';

class ChatScreen extends StatefulWidget {
  final String contactName;

  const ChatScreen({
    super.key,
    required this.contactName,
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
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hi! Thank you for the wonderful birth chart reading yesterday.',
      'isMe': false,
      'time': '2:30 PM',
    },
    {
      'text': 'I wanted to ask about the timing you mentioned for my career change.',
      'isMe': false,
      'time': '2:31 PM',
    },
    {
      'text': 'Hello Sarah! I\'m glad you found the reading helpful. Based on your chart, the optimal timing would be when Jupiter transits through your 10th house.',
      'isMe': true,
      'time': '2:45 PM',
    },
    {
      'text': 'This period starts around mid-March and extends through early July. During this time, you\'ll have enhanced opportunities for professional growth.',
      'isMe': true,
      'time': '2:46 PM',
    },
    {
      'text': 'That\'s perfect timing! I was planning to start looking in April anyway.',
      'isMe': false,
      'time': 'Just now',
    },
  ];

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText != _isComposing) {
        setState(() {
          _isComposing = hasText;
        });
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
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
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
            CircleAvatar(
              backgroundColor: themeService.primaryColor,
              child: Text(
                widget.contactName.split(' ').map((e) => e[0]).join(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                  Text(
                    'Online now',
                    style: TextStyle(
                      color: themeService.successColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
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
            child: ListView.builder(
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

  Widget _buildMessageBubble(Map<String, dynamic> message, ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message['isMe']
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message['isMe']) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: themeService.primaryColor,
              child: Text(
                widget.contactName.split(' ').map((e) => e[0]).join(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                color: message['isMe'] ? themeService.primaryColor : themeService.surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(message['isMe'] ? 18 : 6),
                  bottomRight: Radius.circular(message['isMe'] ? 6 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['text'],
                    style: TextStyle(
                      color: message['isMe'] ? Colors.white : themeService.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message['time'],
                    style: TextStyle(
                      color: message['isMe']
                          ? Colors.white.withOpacity(0.7)
                          : themeService.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message['isMe']) ...[
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
    if (text.isNotEmpty) {
      setState(() {
        _messages.add({
          'text': text,
          'isMe': true,
          'time': 'Just now',
        });
      });
      _messageController.clear();
      _scrollToBottom();
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
            contactName: widget.contactName,
            isIncoming: false,
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
































