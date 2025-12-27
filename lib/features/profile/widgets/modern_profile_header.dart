import 'package:flutter/material.dart';
import '../../../shared/widgets/profile_avatar_widget.dart';
import '../../../shared/widgets/verification_badge.dart';
import '../../auth/models/astrologer_model.dart';
import '../../../shared/theme/services/theme_service.dart';

class ModernProfileHeader extends StatelessWidget {
  final AstrologerModel? astrologer;
  final ThemeService themeService;
  final VoidCallback onEditTap;

  const ModernProfileHeader({
    super.key,
    required this.astrologer,
    required this.themeService,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          // Large Profile Avatar with Verification Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Avatar with verification badge wrapper
              if (astrologer?.isVerified == true)
                VerifiedAvatarBadge(
                  badgeSize: 28,
                  badgeOffset: 4,
                  child: _buildAvatar(),
                )
              else
                _buildAvatar(),

              // Online Status Indicator - Only show on profile picture if NOT verified
              // If verified, show it after the name instead
              if (astrologer?.isOnline == true && astrologer?.isVerified != true)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Name with Online Status (if verified)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  astrologer?.name ?? 'Loading...',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: themeService.textPrimary,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Online Status Indicator - Show after name if verified
              if (astrologer?.isVerified == true && astrologer?.isOnline == true) ...[
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 4),

          // Email
          Text(
            astrologer?.email ?? 'loading@email.com',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: themeService.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ProfileAvatarWidget(
        imagePath: astrologer?.profilePicture,
        radius: 60,
        fallbackText: astrologer?.name?.substring(0, 1).toUpperCase() ?? 'A',
        backgroundColor: themeService.cardColor,
        textColor: themeService.primaryColor,
      ),
    );
  }
}

