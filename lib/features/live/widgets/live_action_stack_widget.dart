import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/live_stream_model.dart';

/// TikTok-style vertical action stack on the right side of live streams
/// Includes: Profile, Likes, Comments, Gifts, Share buttons with engagement metrics
class LiveActionStackWidget extends StatefulWidget {
  final LiveStreamModel liveStream;
  final int heartsCount;    // Total heart reactions (can spam)
  final int commentsCount;
  final VoidCallback onProfileTap;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentsTap;
  final VoidCallback onShareTap;
  final bool isLiked;

  const LiveActionStackWidget({
    super.key,
    required this.liveStream,
    required this.heartsCount,
    required this.commentsCount,
    required this.onProfileTap,
    required this.onLikeTap,
    required this.onCommentsTap,
    required this.onShareTap,
    this.isLiked = false,
  });

  @override
  State<LiveActionStackWidget> createState() => _LiveActionStackWidgetState();
}

class _LiveActionStackWidgetState extends State<LiveActionStackWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _likeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _likeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _likeController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _likeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LiveActionStackWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked && !oldWidget.isLiked) {
      _likeController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Astrologer Profile Picture
              _buildProfileButton(themeService),
              const SizedBox(height: 24),

              // Like/Heart Button
              _buildLikeButton(themeService),
              const SizedBox(height: 24),

              // Comments Button
              _buildCommentsButton(themeService),
              const SizedBox(height: 24),

              // Share Button
              _buildShareButton(themeService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileButton(ThemeService themeService) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onProfileTap();
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: (widget.liveStream.astrologerProfilePicture != null &&
                  widget.liveStream.astrologerProfilePicture!.isNotEmpty)
              ? Image.network(
                  widget.liveStream.astrologerProfilePicture!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultAvatar(themeService);
                  },
                )
              : _buildDefaultAvatar(themeService),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(ThemeService themeService) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeService.primaryColor,
            themeService.secondaryColor,
          ],
        ),
      ),
      child: Center(
        child: Text(
          widget.liveStream.astrologerName[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLikeButton(ThemeService themeService) {
    return _buildActionButton(
      icon: widget.isLiked ? Icons.favorite : Icons.favorite_border,
      iconColor: widget.isLiked ? Colors.red : Colors.white,
      count: _formatCount(widget.heartsCount), // Shows total hearts (Instagram/TikTok style)
      onTap: widget.onLikeTap,
      scale: widget.isLiked ? _scaleAnimation : null,
    );
  }

  Widget _buildCommentsButton(ThemeService themeService) {
    return _buildActionButton(
      icon: Icons.chat_bubble_outline,
      iconColor: Colors.white,
      count: _formatCount(widget.commentsCount),
      onTap: widget.onCommentsTap,
    );
  }

  Widget _buildShareButton(ThemeService themeService) {
    return _buildActionButton(
      icon: Icons.share,
      iconColor: Colors.white,
      count: '',
      onTap: widget.onShareTap,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    required String count,
    required VoidCallback onTap,
    Animation<double>? scale,
  }) {
    final button = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 26,
          ),
        ),
        if (count.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ],
    );

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: scale != null
          ? AnimatedBuilder(
              animation: scale,
              builder: (context, child) {
                return Transform.scale(
                  scale: scale.value,
                  child: button,
                );
              },
            )
          : button,
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else if (count > 0) {
      return count.toString();
    }
    return '0';
  }
}

