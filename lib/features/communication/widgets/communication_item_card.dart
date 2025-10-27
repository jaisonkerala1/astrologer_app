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
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: themeService.primaryColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.network(
              item.avatar,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to initials if image fails to load
                return Container(
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
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(item.contactName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: themeService.surfaceColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          themeService.primaryColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                );
              },
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

  /// Get initials from contact name for fallback
  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
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
    // For calls, show status icon (Google Phone inspired)
    return Row(
      children: [
        if (item.type != CommunicationType.message) ...[
          Icon(
            _getStatusIcon(),
            size: 14,
            color: _getStatusIconColor(),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            item.preview,
            style: TextStyle(
              color: themeService.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon() {
    switch (item.status) {
      case CommunicationStatus.missed:
        return Icons.call_missed_outgoing_rounded;
      case CommunicationStatus.outgoing:
        return Icons.call_made_rounded;
      case CommunicationStatus.incoming:
        return Icons.call_received_rounded;
      default:
        return Icons.phone_rounded;
    }
  }

  Color _getStatusIconColor() {
    if (item.status == CommunicationStatus.missed) {
      return themeService.errorColor;
    }
    return themeService.textSecondary;
  }

  Widget _buildMetadata() {
    return Row(
      children: [
        // Type icon with background (Google Phone inspired - minimal, 20px)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getTypeColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getTypeIconData(),
                size: 14, // Slightly smaller in badge
                color: _getTypeColor(),
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
    
    // Show minimal outlined icon based on type (Google Phone style - 20px)
    IconData actionIcon;
    Color iconColor;
    
    switch (item.type) {
      case CommunicationType.message:
        actionIcon = Icons.chat_bubble_outline_rounded;
        iconColor = themeService.primaryColor;
        break;
      case CommunicationType.voiceCall:
        actionIcon = Icons.phone_outlined;
        iconColor = const Color(0xFF10B981); // Green
        break;
      case CommunicationType.videoCall:
        actionIcon = Icons.videocam_outlined;
        iconColor = const Color(0xFF8B5CF6); // Purple
        break;
    }
    
    return Icon(
      actionIcon,
      color: iconColor.withOpacity(0.3),
      size: 20, // Google Phone inspired - 20px
    );
  }

  IconData _getTypeIconData() {
    switch (item.type) {
      case CommunicationType.message:
        return Icons.chat_bubble_outline_rounded;
      case CommunicationType.voiceCall:
        return Icons.phone_outlined;
      case CommunicationType.videoCall:
        return Icons.videocam_outlined;
    }
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


