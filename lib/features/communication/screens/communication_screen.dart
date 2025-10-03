import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../core/constants/app_constants.dart';
import 'chat_screen.dart';
import 'dialer_screen.dart';
import '../services/communication_service.dart';
import '../widgets/tab_badge.dart';

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Clear badges when viewing the active tab
    final commService = Provider.of<CommunicationService>(context, listen: false);
    if (_selectedTab == 0) {
      // Clear missed calls badge when viewing calls tab
      Future.delayed(const Duration(milliseconds: 500), () {
        commService.clearMissedCalls();
      });
    } else if (_selectedTab == 1) {
      // Note: Messages are cleared individually when opened
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeService, CommunicationService>(
      builder: (context, themeService, commService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          appBar: AppBar(
            title: const Text('Communication'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: themeService.textPrimary,
            actions: [
              // Test badge system button (remove in production)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'test_message':
                      commService.simulateNewMessage();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Simulated new message')),
                      );
                      break;
                    case 'test_call':
                      commService.simulateMissedCall();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Simulated missed call')),
                      );
                      break;
                    case 'reset':
                      commService.resetUnreadCounts();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reset all badges')),
                      );
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'test_message',
                    child: Text('Test New Message'),
                  ),
                  const PopupMenuItem(
                    value: 'test_call',
                    child: Text('Test Missed Call'),
                  ),
                  const PopupMenuItem(
                    value: 'reset',
                    child: Text('Reset Badges'),
                  ),
                ],
              ),
            ],
          ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeService.cardColor,
              borderRadius: themeService.borderRadius,
              border: Border.all(color: themeService.borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedTab = 0);
                      // Clear missed calls badge when switching to calls tab
                      Future.delayed(const Duration(milliseconds: 500), () {
                        commService.clearMissedCalls();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0 ? themeService.surfaceColor : Colors.transparent,
                        borderRadius: themeService.borderRadius,
                        boxShadow: _selectedTab == 0
                            ? [themeService.cardShadow]
                            : null,
                      ),
                      child: TabBadge(
                        label: 'Calls',
                        count: commService.missedCallsCount,
                        isActive: _selectedTab == 0,
                        activeColor: themeService.primaryColor,
                        inactiveColor: themeService.textSecondary,
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
                        color: _selectedTab == 1 ? themeService.surfaceColor : Colors.transparent,
                        borderRadius: themeService.borderRadius,
                        boxShadow: _selectedTab == 1
                            ? [themeService.cardShadow]
                            : null,
                      ),
                      child: TabBadge(
                        label: 'Messages',
                        count: commService.unreadMessagesCount,
                        isActive: _selectedTab == 1,
                        activeColor: themeService.primaryColor,
                        inactiveColor: themeService.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _selectedTab == 0 
                ? _buildCallsList(themeService, commService) 
                : _buildMessagesList(themeService, commService),
          ),
        ],
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton(
              onPressed: _showDialer,
              backgroundColor: themeService.primaryColor,
              child: const Icon(Icons.dialpad, color: Colors.white),
            )
          : FloatingActionButton(
              onPressed: _showNewMessageModal,
              backgroundColor: themeService.primaryColor,
              child: const Icon(Icons.message, color: Colors.white),
            ),
        );
      },
    );
  }

  Widget _buildCallsList(ThemeService themeService, CommunicationService commService) {
    final calls = commService.calls;

    if (calls.isEmpty) {
      return Center(
        child: Text(
          'No calls yet',
          style: TextStyle(color: themeService.textSecondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: calls.length,
      itemBuilder: (context, index) {
        final call = calls[index];
        return _buildCallItem(call, themeService);
      },
    );
  }

  Widget _buildCallItem(Map<String, dynamic> call, ThemeService themeService) {
    Color statusColor = themeService.textSecondary;
    IconData statusIcon = Icons.phone;

    switch (call['status']) {
      case 'answered':
        statusColor = themeService.successColor;
        statusIcon = Icons.call_received;
        break;
      case 'missed':
        statusColor = themeService.errorColor;
        statusIcon = Icons.call_missed;
        break;
      case 'outgoing':
        statusColor = themeService.primaryColor;
        statusIcon = Icons.call_made;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: themeService.borderRadius,
        boxShadow: [themeService.cardShadow],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: themeService.primaryColor,
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
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: themeService.textPrimary,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(statusIcon, size: 16, color: statusColor),
            const SizedBox(width: 8),
            Text(
              '${call['type']} • ${call['time']}',
              style: TextStyle(color: themeService.textSecondary),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _makeCall(call['name']),
              icon: Icon(Icons.phone, color: themeService.successColor),
            ),
            IconButton(
              onPressed: () => _openChat(call['name']),
              icon: Icon(Icons.message, color: themeService.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(ThemeService themeService, CommunicationService commService) {
    final messages = commService.messages;

    if (messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet',
          style: TextStyle(color: themeService.textSecondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageItem(message, themeService, commService);
      },
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message, ThemeService themeService, CommunicationService commService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: themeService.borderRadius,
        boxShadow: [themeService.cardShadow],
      ),
      child: ListTile(
        onTap: () {
          // Mark message as read when opened
          commService.markMessageAsRead(message['name']);
          _openChat(message['name']);
        },
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: themeService.primaryColor,
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
                    color: themeService.successColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: themeService.cardColor, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          message['name'],
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: themeService.textPrimary,
          ),
        ),
        subtitle: Text(
          message['preview'],
          style: TextStyle(
            color: themeService.textSecondary,
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
                color: themeService.textHint,
                fontSize: 12,
              ),
            ),
            if (message['unread'] > 0)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: themeService.errorColor,
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
        backgroundColor: Theme.of(context).colorScheme.primary,
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
      builder: (context) => Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: themeService.cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'New Message',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: themeService.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Select a contact to start messaging',
                  style: TextStyle(color: themeService.textSecondary),
                ),
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
          );
        },
      ),
    );
  }
}
