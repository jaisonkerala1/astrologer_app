import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';

class LiveStreamControlsWidget extends StatelessWidget {
  final VoidCallback onCommentsTap;
  final VoidCallback onGiftsTap;
  final VoidCallback onReactionsTap;
  final VoidCallback onShareTap;
  final VoidCallback onReportTap;

  const LiveStreamControlsWidget({
    super.key,
    required this.onCommentsTap,
    required this.onGiftsTap,
    required this.onReactionsTap,
    required this.onShareTap,
    required this.onReportTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Comments button
            _buildControlButton(
              icon: Icons.chat_bubble_outline,
              label: 'Comments',
              onTap: onCommentsTap,
              themeService: themeService,
            ),
            
            const SizedBox(height: 12),
            
            // Gifts button
            _buildControlButton(
              icon: Icons.card_giftcard,
              label: 'Gifts',
              onTap: onGiftsTap,
              themeService: themeService,
            ),
            
            const SizedBox(height: 12),
            
            // Reactions button
            _buildControlButton(
              icon: Icons.favorite_border,
              label: 'React',
              onTap: onReactionsTap,
              themeService: themeService,
            ),
            
            const SizedBox(height: 12),
            
            // Share button
            _buildControlButton(
              icon: Icons.share,
              label: 'Share',
              onTap: onShareTap,
              themeService: themeService,
            ),
            
            const SizedBox(height: 12),
            
            // More options button
            _buildControlButton(
              icon: Icons.more_vert,
              label: 'More',
              onTap: () => _showMoreOptions(context, themeService),
              themeService: themeService,
            ),
          ],
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeService themeService,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context, ThemeService themeService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: themeService.surfaceColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: themeService.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Options
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text('Report Stream'),
              onTap: () {
                Navigator.pop(context);
                onReportTap();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.block, color: Colors.orange),
              title: const Text('Block Astrologer'),
              onTap: () {
                Navigator.pop(context);
                _showBlockConfirmation(context, themeService);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.volume_off, color: Colors.grey),
              title: const Text('Mute Notifications'),
              onTap: () {
                Navigator.pop(context);
                _showMuteConfirmation(context, themeService);
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showBlockConfirmation(BuildContext context, ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Astrologer'),
        content: const Text('Are you sure you want to block this astrologer? You won\'t see their streams anymore.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Astrologer blocked')),
              );
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showMuteConfirmation(BuildContext context, ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mute Notifications'),
        content: const Text('You won\'t receive notifications for this astrologer\'s streams.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications muted')),
              );
            },
            child: const Text('Mute'),
          ),
        ],
      ),
    );
  }
}










