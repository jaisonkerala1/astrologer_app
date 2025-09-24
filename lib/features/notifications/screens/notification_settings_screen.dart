import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/local_notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // Basic notification settings
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  
  // Time settings
  bool _quietHoursEnabled = false;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 8, minute: 0);
  bool _workingHoursOnly = false;
  
  // Notification type toggles
  Map<NotificationType, bool> _notificationToggles = {
    NotificationType.consultationRequest: true,
    NotificationType.consultationAccepted: true,
    NotificationType.consultationCancelled: true,
    NotificationType.consultationCompleted: true,
    NotificationType.paymentReceived: true,
    NotificationType.paymentFailed: true,
    NotificationType.reviewReceived: true,
    NotificationType.messageReceived: true,
    NotificationType.callMissed: true,
    NotificationType.systemUpdate: true,
    NotificationType.promotional: false,
    NotificationType.reminder: true,
    NotificationType.emergency: true,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load settings from storage or use defaults
    // This is a simplified version - you might want to load from actual storage
    setState(() {
      // Settings are already initialized with defaults
    });
  }

  Future<void> _saveSettings() async {
    // Save settings to storage
    // This is a simplified version - you might want to save to actual storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          appBar: AppBar(
            title: const Text(
              'Notification Settings',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: themeService.primaryColor,
            elevation: 0,
            actions: [
              TextButton(
                onPressed: _saveSettings,
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General Settings
            _buildSection(
              'General Settings',
              Icons.settings,
              [
                _buildSwitchTile(
                  'Push Notifications',
                  'Receive push notifications on your device',
                  _pushNotificationsEnabled,
                  (value) => setState(() => _pushNotificationsEnabled = value),
                  themeService,
                ),
                _buildSwitchTile(
                  'Email Notifications',
                  'Receive important updates via email',
                  _emailNotificationsEnabled,
                  (value) => setState(() => _emailNotificationsEnabled = value),
                  themeService,
                ),
                _buildSwitchTile(
                  'Sound',
                  'Play sound for notifications',
                  _soundEnabled,
                  (value) => setState(() => _soundEnabled = value),
                  themeService,
                ),
                _buildSwitchTile(
                  'Vibration',
                  'Vibrate for notifications',
                  _vibrationEnabled,
                  (value) => setState(() => _vibrationEnabled = value),
                  themeService,
                ),
              ],
              themeService,
            ),
            
            const SizedBox(height: 24),
            
            // Time Settings
            _buildSection(
              'Time Settings',
              Icons.access_time,
              [
                _buildSwitchTile(
                  'Quiet Hours',
                  'Pause notifications during specified hours',
                  _quietHoursEnabled,
                  (value) => setState(() => _quietHoursEnabled = value),
                  themeService,
                ),
                if (_quietHoursEnabled) ...[
                  _buildTimeTile(
                    'Start Time',
                    _quietHoursStart,
                    (time) => setState(() => _quietHoursStart = time),
                    themeService,
                  ),
                  _buildTimeTile(
                    'End Time',
                    _quietHoursEnd,
                    (time) => setState(() => _quietHoursEnd = time),
                    themeService,
                  ),
                ],
                _buildSwitchTile(
                  'Working Hours Only',
                  'Only receive notifications during work hours',
                  _workingHoursOnly,
                  (value) => setState(() => _workingHoursOnly = value),
                  themeService,
                ),
              ],
              themeService,
            ),
            
            const SizedBox(height: 24),
            
            // Notification Types
            _buildSection(
              'Notification Types',
              Icons.notifications,
              _buildNotificationTypeToggles(themeService),
              themeService,
            ),
            
            const SizedBox(height: 24),
            
            // Test Notification
            _buildTestNotificationButton(themeService),
          ],
        ),
      ),
        );
      },
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children, ThemeService themeService) {
    return Container(
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeService.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: themeService.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: themeService.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged, ThemeService? themeService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeService?.textPrimary ?? Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: themeService?.textSecondary ?? Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: themeService?.primaryColor ?? Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTile(String title, TimeOfDay time, ValueChanged<TimeOfDay> onChanged, ThemeService? themeService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        onTap: () async {
          final selectedTime = await showTimePicker(
            context: context,
            initialTime: time,
          );
          if (selectedTime != null) {
            onChanged(selectedTime);
          }
        },
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: themeService?.textPrimary ?? Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time.format(context),
                    style: TextStyle(
                      fontSize: 14,
                      color: themeService?.textSecondary ?? Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.access_time,
              color: themeService?.textSecondary ?? Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNotificationTypeToggles(ThemeService themeService) {
    return NotificationType.values.map((type) {
      return _buildNotificationTypeTile(type, themeService);
    }).toList();
  }

  Widget _buildNotificationTypeTile(NotificationType type, ThemeService themeService) {
    final isEnabled = _notificationToggles[type] ?? false;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getNotificationTypeColor(type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getNotificationTypeIcon(type),
              color: _getNotificationTypeColor(type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getNotificationTypeTitle(type),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeService.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getNotificationTypeDescription(type),
                  style: TextStyle(
                    fontSize: 14,
                    color: themeService.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (value) {
              setState(() {
                _notificationToggles[type] = value;
              });
            },
            activeColor: themeService.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildTestNotificationButton(ThemeService themeService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_active,
            size: 48,
            color: themeService.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Test Notification',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a test notification to verify your settings',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: themeService.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _sendTestNotification,
            icon: const Icon(Icons.send),
            label: const Text('Send Test'),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeService.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendTestNotification() async {
    try {
      // Check if permissions are granted
      final hasPermission = await LocalNotificationService.checkPermissions();
      
      if (!hasPermission) {
        // Show permission dialog
        final granted = await _showPermissionDialog();
        if (!granted) {
          return;
        }
      }

      // Send actual local notification
      final success = await LocalNotificationService.sendTestNotification();
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification sent! Check your notification panel.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send notification. Please check permissions.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _showPermissionDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Permission Required'),
        content: const Text(
          'To send test notifications, please allow notification permissions for this app. You can enable this in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(false);
              await LocalNotificationService.requestPermissions();
            },
            child: const Text('Request Permission'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(false);
              await LocalNotificationService.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    ) ?? false;
  }

  String _getNotificationTypeTitle(NotificationType type) {
    switch (type) {
      case NotificationType.consultationRequest:
        return 'New Consultation Request';
      case NotificationType.consultationAccepted:
        return 'Consultation Accepted';
      case NotificationType.consultationCancelled:
        return 'Consultation Cancelled';
      case NotificationType.consultationCompleted:
        return 'Consultation Completed';
      case NotificationType.paymentReceived:
        return 'Payment Received';
      case NotificationType.paymentFailed:
        return 'Payment Failed';
      case NotificationType.reviewReceived:
        return 'New Review';
      case NotificationType.messageReceived:
        return 'New Message';
      case NotificationType.callMissed:
        return 'Missed Call';
      case NotificationType.systemUpdate:
        return 'System Updates';
      case NotificationType.promotional:
        return 'Promotional';
      case NotificationType.reminder:
        return 'Reminders';
      case NotificationType.emergency:
        return 'Emergency';
    }
  }

  String _getNotificationTypeDescription(NotificationType type) {
    switch (type) {
      case NotificationType.consultationRequest:
        return 'When a client requests a consultation';
      case NotificationType.consultationAccepted:
        return 'When your consultation is accepted';
      case NotificationType.consultationCancelled:
        return 'When a consultation is cancelled';
      case NotificationType.consultationCompleted:
        return 'When a consultation is completed';
      case NotificationType.paymentReceived:
        return 'When you receive payment';
      case NotificationType.paymentFailed:
        return 'When payment processing fails';
      case NotificationType.reviewReceived:
        return 'When you receive a new review';
      case NotificationType.messageReceived:
        return 'When you receive a new message';
      case NotificationType.callMissed:
        return 'When you miss a call';
      case NotificationType.systemUpdate:
        return 'App updates and maintenance';
      case NotificationType.promotional:
        return 'Promotional offers and updates';
      case NotificationType.reminder:
        return 'Important reminders';
      case NotificationType.emergency:
        return 'Emergency notifications';
    }
  }

  IconData _getNotificationTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.consultationRequest:
        return Icons.event_note;
      case NotificationType.consultationAccepted:
        return Icons.check_circle;
      case NotificationType.consultationCancelled:
        return Icons.cancel;
      case NotificationType.consultationCompleted:
        return Icons.done_all;
      case NotificationType.paymentReceived:
        return Icons.payment;
      case NotificationType.paymentFailed:
        return Icons.error;
      case NotificationType.reviewReceived:
        return Icons.star;
      case NotificationType.messageReceived:
        return Icons.message;
      case NotificationType.callMissed:
        return Icons.phone_missed;
      case NotificationType.systemUpdate:
        return Icons.system_update;
      case NotificationType.promotional:
        return Icons.local_offer;
      case NotificationType.reminder:
        return Icons.schedule;
      case NotificationType.emergency:
        return Icons.warning;
    }
  }

  Color _getNotificationTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.consultationRequest:
        return Colors.blue;
      case NotificationType.consultationAccepted:
        return Colors.green;
      case NotificationType.consultationCancelled:
        return Colors.red;
      case NotificationType.consultationCompleted:
        return Colors.green;
      case NotificationType.paymentReceived:
        return Colors.green;
      case NotificationType.paymentFailed:
        return Colors.red;
      case NotificationType.reviewReceived:
        return Colors.orange;
      case NotificationType.messageReceived:
        return Colors.blue;
      case NotificationType.callMissed:
        return Colors.red;
      case NotificationType.systemUpdate:
        return Colors.purple;
      case NotificationType.promotional:
        return Colors.pink;
      case NotificationType.reminder:
        return Colors.orange;
      case NotificationType.emergency:
        return Colors.red;
    }
  }
}
