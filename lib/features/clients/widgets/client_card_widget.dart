import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/client_model.dart';
import '../screens/client_detail_screen.dart';
import '../../../shared/widgets/profile_avatar_widget.dart';

/// Beautiful client card widget with modern design
/// Shows client info, stats, and provides tap interaction
class ClientCardWidget extends StatelessWidget {
  final ClientModel client;
  final VoidCallback? onTap;

  const ClientCardWidget({
    super.key,
    required this.client,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ?? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClientDetailScreen(client: client),
                ),
              );
            },
            borderRadius: themeService.borderRadius,
            splashColor: themeService.primaryColor.withOpacity(0.1),
            highlightColor: themeService.primaryColor.withOpacity(0.05),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: themeService.borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildAvatar(themeService),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    client.clientName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: themeService.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (client.isVIP) ...[
                                  const SizedBox(width: 6),
                                  _buildVIPBadge(themeService),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: themeService.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Last: ${client.lastConsultationText}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: themeService.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: themeService.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        client.preferredTypeIcon,
                                        size: 11,
                                        color: themeService.primaryColor,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        client.preferredTypeDisplay,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: themeService.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: themeService.textHint,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: themeService.borderColor,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.event_note,
                          label: 'Sessions',
                          value: client.totalConsultations.toString(),
                          color: themeService.infoColor,
                          themeService: themeService,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.currency_rupee,
                          label: 'Spent',
                          value: _formatAmount(client.totalSpent),
                          color: themeService.successColor,
                          themeService: themeService,
                        ),
                      ),
                      if (client.averageRating != null)
                        Expanded(
                          child: _buildStatItem(
                            icon: Icons.star,
                            label: 'Rating',
                            value: client.averageRating!.toStringAsFixed(1),
                            color: themeService.warningColor,
                            themeService: themeService,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(ThemeService themeService) {
    final imageUrl = 'https://i.pravatar.cc/150?u=' + Uri.encodeComponent(client.clientName);
    return ProfileAvatarWidget(
      imagePath: imageUrl,
      radius: 22,
      fallbackText: client.initials,
      backgroundColor: client.avatarColor.withOpacity(0.15),
      textColor: client.avatarColor,
    );
  }

  Widget _buildVIPBadge(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700),
            const Color(0xFFFFA500),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 10,
            color: Colors.white,
          ),
          SizedBox(width: 2),
          Text(
            'VIP',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeService themeService,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: themeService.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: themeService.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

