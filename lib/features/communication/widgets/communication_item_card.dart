import 'package:flutter/material.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/communication_item.dart';

/// Beautiful, minimal communication item card (Instagram-inspired)
class CommunicationItemCard extends StatelessWidget {
  final CommunicationItem item;
  final ThemeService themeService;
  final VoidCallback onTap;

  const CommunicationItemCard({
    super.key,
    required this.item,
    required this.themeService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with online indicator
                _buildAvatar(),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNameAndTime(),
                      const SizedBox(height: 4),
                      _buildPreview(),
                      const SizedBox(height: 6),
                      _buildMetadata(),
                    ],
                  ),
                ),
                
                // Right side (unread badge or action icon)
                _buildRightSide(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeService.primaryColor,
                themeService.primaryColor.withOpacity(0.7),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: themeService.primaryColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              item.avatar,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        
        // Online indicator
        if (item.isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981), // Green
                shape: BoxShape.circle,
                border: Border.all(
                  color: themeService.cardColor,
                  width: 2.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNameAndTime() {
    return Row(
      children: [
        Expanded(
          child: Text(
            item.contactName,
            style: TextStyle(
              color: themeService.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          item.timeAgo,
          style: TextStyle(
            color: themeService.textHint,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    // For calls, show status icon
    String displayText = item.preview;
    if (item.statusIcon != null) {
      displayText = '${item.statusIcon} ${item.preview}';
    }
    
    return Text(
      displayText,
      style: TextStyle(
        color: themeService.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMetadata() {
    return Row(
      children: [
        // Type icon with background
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getTypeColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.typeIcon,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 4),
              Text(
                _getTypeLabel(),
                style: TextStyle(
                  color: _getTypeColor(),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        
        // Duration or amount
        if (item.duration != null || item.chargedAmount != null) ...[
          const SizedBox(width: 8),
          Text(
            '•',
            style: TextStyle(
              color: themeService.textHint,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          if (item.duration != null)
            Text(
              item.duration!,
              style: TextStyle(
                color: themeService.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (item.chargedAmount != null) ...[
            const SizedBox(width: 4),
            Text(
              '₹${item.chargedAmount!.toStringAsFixed(0)}',
              style: TextStyle(
                color: themeService.successColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildRightSide() {
    if (item.unreadCount > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: themeService.errorColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: themeService.errorColor.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          item.unreadCount.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    
    // Show action icon based on type
    IconData actionIcon;
    Color iconColor;
    
    switch (item.type) {
      case CommunicationType.message:
        actionIcon = Icons.message_rounded;
        iconColor = themeService.primaryColor;
        break;
      case CommunicationType.voiceCall:
        actionIcon = Icons.phone_rounded;
        iconColor = const Color(0xFF10B981); // Green
        break;
      case CommunicationType.videoCall:
        actionIcon = Icons.videocam_rounded;
        iconColor = const Color(0xFF8B5CF6); // Purple
        break;
    }
    
    return Icon(
      actionIcon,
      color: iconColor.withOpacity(0.3),
      size: 20,
    );
  }

  Color _getTypeColor() {
    switch (item.type) {
      case CommunicationType.message:
        return themeService.primaryColor;
      case CommunicationType.voiceCall:
        return const Color(0xFF10B981); // Green
      case CommunicationType.videoCall:
        return const Color(0xFF8B5CF6); // Purple
    }
  }

  String _getTypeLabel() {
    switch (item.type) {
      case CommunicationType.message:
        return 'Message';
      case CommunicationType.voiceCall:
        return 'Call';
      case CommunicationType.videoCall:
        return 'Video';
    }
  }
}


