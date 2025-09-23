import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

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
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
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
                    style: const TextStyle(
                      color: AppTheme.textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text(
                    'Online now',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _makeCall(),
            icon: const Icon(Icons.phone, color: Colors.green),
          ),
          IconButton(
            onPressed: () => _showMoreOptions(),
            icon: const Icon(Icons.more_vert, color: AppTheme.textColor),
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
                return _buildMessageBubble(message);
              },
            ),
          ),
          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
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
              backgroundColor: AppTheme.primaryColor,
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
                color: message['isMe'] ? AppTheme.primaryColor : Colors.grey[200],
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
                      color: message['isMe'] ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message['time'],
                    style: TextStyle(
                      color: message['isMe']
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[600],
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
              backgroundColor: Colors.grey[300],
              child: const Icon(
                Icons.person,
                color: Colors.white,
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

  void _makeCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${widget.contactName}...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.call, color: Colors.green),
              title: const Text('Call'),
              onTap: () {
                Navigator.pop(context);
                _makeCall();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: AppTheme.primaryColor),
              title: const Text('Video Call'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement video call
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.blue),
              title: const Text('Contact Info'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show contact info
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Block Contact'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Block contact
              },
            ),
          ],
        ),
      ),
    );
  }
}


















