import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/profile_avatar_widget.dart';

class LiveAstrologerCircleWidget extends StatelessWidget {
  final dynamic astrologer;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const LiveAstrologerCircleWidget({
    super.key,
    required this.astrologer,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Minimize column height
            children: [
              // Main circle with Instagram Stories-style live border
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF09433), // Orange
                      Color(0xFFE6683C), // Red-orange
                      Color(0xFFDC2743), // Red
                      Color(0xFFCC2366), // Pink-red
                      Color(0xFFBC1888), // Pink
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeService.backgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: themeService.isVedicMode() 
                            ? Colors.black.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Live streaming thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: themeService.surfaceColor,
                          ),
                          child: (astrologer.thumbnailUrl != null && astrologer.thumbnailUrl.isNotEmpty)
                              ? Image.network(
                                  astrologer.thumbnailUrl,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return ProfileAvatarWidget(
                                      imagePath: astrologer.profilePicture,
                                      radius: 32,
                                      fallbackText: (astrologer.name != null && astrologer.name.isNotEmpty) 
                                          ? astrologer.name.substring(0, 1).toUpperCase()
                                          : 'A',
                                      backgroundColor: themeService.primaryColor,
                                      textColor: Colors.white,
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: themeService.surfaceColor,
                                        borderRadius: BorderRadius.circular(32),
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            themeService.primaryColor,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : ProfileAvatarWidget(
                                  imagePath: astrologer.profilePicture,
                                  radius: 32,
                                  fallbackText: (astrologer.name != null && astrologer.name.isNotEmpty) 
                                      ? astrologer.name.substring(0, 1).toUpperCase()
                                      : 'A',
                                  backgroundColor: themeService.primaryColor,
                                  textColor: Colors.white,
                                ),
                        ),
                      ),
                      
                      // Live indicator badge - Instagram Stories style
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.red, Colors.redAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.5),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Online status indicator
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.4),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 4), // Reduced spacing
              
              // Astrologer name
              SizedBox(
                width: 80, // Increased width to prevent overflow
                child: Text(
                  astrologer.name ?? 'Unknown',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: themeService.textPrimary,
                    fontSize: 10, // Slightly smaller font
                    fontWeight: FontWeight.w500,
                    height: 1.2, // Reduced line height
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 1), // Reduced spacing
              
              // Viewer count
              Container(
                width: 80, // Match the name container width
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: themeService.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: themeService.borderColor.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center, // Center the content
                  children: [
                    Icon(
                      Icons.visibility,
                      size: 9, // Slightly smaller icon
                      color: themeService.textSecondary,
                    ),
                    const SizedBox(width: 2),
                    Flexible( // Use Flexible to prevent overflow
                      child: Text(
                        _formatViewerCount(astrologer.viewerCount ?? 0),
                        style: TextStyle(
                          color: themeService.textSecondary,
                          fontSize: 8, // Slightly smaller font
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatViewerCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}



