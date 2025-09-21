import 'package:flutter/material.dart';
import '../models/chat_settings.dart';
import '../../../shared/theme/app_theme.dart';

class ChatSettingsDialog extends StatefulWidget {
  final ChatSettings currentSettings;
  final Function(ChatSettings) onSettingsChanged;

  const ChatSettingsDialog({
    super.key,
    required this.currentSettings,
    required this.onSettingsChanged,
  });

  @override
  State<ChatSettingsDialog> createState() => _ChatSettingsDialogState();
}

class _ChatSettingsDialogState extends State<ChatSettingsDialog> {
  late ChatSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.currentSettings;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.settings,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text('Chat Settings'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingTile(
              icon: Icons.memory,
              title: 'Remember Conversations',
              subtitle: 'Loona will remember your chat history',
              value: _settings.rememberConversations,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(rememberConversations: value);
                });
              },
            ),
            const SizedBox(height: 16),
            _buildSettingTile(
              icon: Icons.person,
              title: 'Share Profile Info',
              subtitle: 'Let Loona know about your astrology background',
              value: _settings.shareUserInfo,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(shareUserInfo: value);
                });
              },
            ),
            const SizedBox(height: 16),
            _buildSettingTile(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Get notified about new messages',
              value: _settings.notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(notificationsEnabled: value);
                });
              },
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your conversations are stored locally on your device and are not shared with anyone.',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSettingsChanged(_settings);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }
}









