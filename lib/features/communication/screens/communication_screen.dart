import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import 'chat_screen.dart';
import 'dialer_screen.dart';

class CommunicationScreen extends StatefulWidget {
  final String? initialTab;
  
  const CommunicationScreen({super.key, this.initialTab});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    // Set initial tab based on parameter
    if (widget.initialTab == 'calls') {
      _selectedTab = 0;
    } else if (widget.initialTab == 'messages') {
      _selectedTab = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Communication'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textColor,
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _selectedTab == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        'Calls',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedTab == 0 ? AppTheme.primaryColor : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _selectedTab == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        'Messages',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedTab == 1 ? AppTheme.primaryColor : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _selectedTab == 0 ? _buildCallsList() : _buildMessagesList(),
          ),
        ],
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton(
              onPressed: _showDialer,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.dialpad, color: Colors.white),
            )
          : FloatingActionButton(
              onPressed: _showNewMessageModal,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.message, color: Colors.white),
            ),
    );
  }

  Widget _buildCallsList() {
    final calls = [
      {
        'name': 'Sarah Miller',
        'type': 'Incoming',
        'time': '2m ago',
        'status': 'answered',
        'avatar': 'SM',
      },
      {
        'name': 'Raj Kumar',
        'type': 'Missed',
        'time': '1h ago',
        'status': 'missed',
        'avatar': 'RK',
      },
      {
        'name': 'Anita Nair',
        'type': 'Outgoing',
        'time': '3h ago',
        'status': 'outgoing',
        'avatar': 'AN',
      },
    ];

    return ListView.builder(
      itemCount: calls.length,
      itemBuilder: (context, index) {
        final call = calls[index];
        return _buildCallItem(call);
      },
    );
  }

  Widget _buildCallItem(Map<String, dynamic> call) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.phone;

    switch (call['status']) {
      case 'answered':
        statusColor = Colors.green;
        statusIcon = Icons.call_received;
        break;
      case 'missed':
        statusColor = Colors.red;
        statusIcon = Icons.call_missed;
        break;
      case 'outgoing':
        statusColor = AppTheme.primaryColor;
        statusIcon = Icons.call_made;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            call['avatar'],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(
          call['name'],
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Row(
          children: [
            Icon(statusIcon, size: 16, color: statusColor),
            const SizedBox(width: 8),
            Text(
              '${call['type']} • ${call['time']}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _makeCall(call['name']),
              icon: const Icon(Icons.phone, color: Colors.green),
            ),
            IconButton(
              onPressed: () => _openChat(call['name']),
              icon: const Icon(Icons.message, color: AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    final messages = [
      {
        'name': 'Sarah Miller',
        'preview': 'Thank you for the reading! When is the best time to...',
        'time': '2m',
        'unread': 2,
        'avatar': 'SM',
        'isOnline': true,
      },
      {
        'name': 'Raj Kumar',
        'preview': 'I need guidance about my career transition...',
        'time': '1h',
        'unread': 0,
        'avatar': 'RK',
        'isOnline': false,
      },
      {
        'name': 'Anita Nair',
        'preview': 'The consultation was amazing! ⭐',
        'time': '3h',
        'unread': 0,
        'avatar': 'AN',
        'isOnline': false,
      },
    ];

    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageItem(message);
      },
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _openChat(message['name']),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                message['avatar'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (message['isOnline'])
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          message['name'],
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          message['preview'],
          style: TextStyle(
            color: Colors.grey[600],
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message['time'],
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
            if (message['unread'] > 0)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  message['unread'].toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _makeCall(String name) {
    // TODO: Implement actual calling functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $name...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _openChat(String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(contactName: name),
      ),
    );
  }

  void _showDialer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DialerScreen(),
    );
  }

  void _showNewMessageModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'New Message',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Select a contact to start messaging'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Show contact picker
              },
              child: const Text('Choose Contact'),
            ),
          ],
        ),
      ),
    );
  }
}
