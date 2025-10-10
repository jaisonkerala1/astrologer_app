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
    // Get screen width for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Base sizes used before we adapt to parent constraints
    final double baseCircle = screenWidth < 360
        ? 56.0
        : screenWidth < 400
            ? 62.0
            : 70.0;
    final double baseNameHeight = screenWidth < 360 ? 12.0 : 14.0;
    final double baseViewerHeight = screenWidth < 360 ? 12.0 : 14.0;
    final double baseNameFont = screenWidth < 360 ? 8.5 : 10.0;
    final double baseViewerFont = screenWidth < 360 ? 7.5 : 9.0;
    final double baseIcon = screenWidth < 360 ? 7.0 : 10.0;
    final double spacingAfterCircle = 2.0;
    final double spacingBeforeViewer = 0.0;
    
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxHeight = constraints.hasBoundedHeight
                  ? constraints.maxHeight
                  : (screenWidth < 360 ? 100 : screenWidth < 400 ? 110 : 130);

              final _LiveItemLayout layout = _computeLayout(
                maxHeight: maxHeight,
                baseCircle: baseCircle,
                baseNameHeight: baseNameHeight,
                baseViewerHeight: baseViewerHeight,
                baseNameFont: baseNameFont,
                baseViewerFont: baseViewerFont,
                baseIcon: baseIcon,
                spacingAfterCircle: spacingAfterCircle,
                spacingBeforeViewer: spacingBeforeViewer,
              );

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              // Main circle with Instagram Stories-style live border
              Container(
                width: layout.circle,
                height: layout.circle,
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
                        borderRadius: BorderRadius.circular(layout.circle / 2),
                        child: Container(
                          width: layout.circle - 6,
                          height: layout.circle - 6,
                          decoration: BoxDecoration(
                            color: themeService.surfaceColor,
                          ),
                          child: astrologer.thumbnailUrl.isNotEmpty
                              ? Image.network(
                                  astrologer.thumbnailUrl,
                                  width: layout.circle - 6,
                                  height: layout.circle - 6,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return ProfileAvatarWidget(
                                      imagePath: astrologer.profilePicture,
                                      radius: (layout.circle - 6) / 2,
                                      fallbackText: astrologer.name.isNotEmpty 
                                          ? astrologer.name.substring(0, 1).toUpperCase()
                                          : 'A',
                                      backgroundColor: themeService.primaryColor,
                                      textColor: Colors.white,
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: layout.circle - 6,
                                      height: layout.circle - 6,
                                      decoration: BoxDecoration(
                                        color: themeService.surfaceColor,
                                        borderRadius: BorderRadius.circular((layout.circle - 6) / 2),
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
                                  radius: (layout.circle - 6) / 2,
                                  fallbackText: astrologer.name.isNotEmpty 
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
              
              SizedBox(height: spacingAfterCircle),
              
              // Astrologer name - Responsive width and height
              Container(
                width: layout.circle,
                height: layout.nameHeight,
                alignment: Alignment.center,
                child: Text(
                  astrologer.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: themeService.textPrimary,
                    fontSize: layout.nameFont,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              SizedBox(height: spacingBeforeViewer),
              
              // Viewer count - Ultra compact for small screens
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: layout.viewerHeight),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 0.5,
                  ),
                  decoration: BoxDecoration(
                    color: themeService.surfaceColor,
                    borderRadius: BorderRadius.circular(screenWidth < 360 ? 5 : 8),
                    border: Border.all(
                      color: themeService.borderColor.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility,
                        size: layout.iconSize,
                        color: themeService.textSecondary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _formatViewerCount(astrologer.viewerCount),
                        style: TextStyle(
                          color: themeService.textSecondary,
                          fontSize: layout.viewerFont,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
            },
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

class _LiveItemLayout {
  final double circle;
  final double nameHeight;
  final double viewerHeight;
  final double nameFont;
  final double viewerFont;
  final double iconSize;
  const _LiveItemLayout({
    required this.circle,
    required this.nameHeight,
    required this.viewerHeight,
    required this.nameFont,
    required this.viewerFont,
    required this.iconSize,
  });
}

_LiveItemLayout _computeLayout({
  required double maxHeight,
  required double baseCircle,
  required double baseNameHeight,
  required double baseViewerHeight,
  required double baseNameFont,
  required double baseViewerFont,
  required double baseIcon,
  required double spacingAfterCircle,
  required double spacingBeforeViewer,
}) {
  // Start with base values
  double circle = baseCircle;
  double nameH = baseNameHeight;
  double viewerH = baseViewerHeight;
  double total = circle + spacingAfterCircle + nameH + spacingBeforeViewer + viewerH;

  // Minimums to preserve readability while fitting
  const double minCircle = 48.0;
  const double minNameH = 11.0;
  const double minViewerH = 11.0;

  if (total > maxHeight) {
    double overflow = total - maxHeight;
    final double reducibleCircle = (circle - minCircle).clamp(0, double.infinity);
    final double reduceCircle = overflow.clamp(0, reducibleCircle);
    circle -= reduceCircle;
    overflow -= reduceCircle;

    if (overflow > 0) {
      final double reducibleName = (nameH - minNameH).clamp(0, double.infinity);
      final double reduceName = (overflow / 2).clamp(0, reducibleName);
      nameH -= reduceName;
      overflow -= reduceName;

      final double reducibleViewer = (viewerH - minViewerH).clamp(0, double.infinity);
      final double reduceViewer = overflow.clamp(0, reducibleViewer);
      viewerH -= reduceViewer;
      overflow -= reduceViewer;
    }
  }

  // Scale text/icon based on the relative heights retained
  final double nameScale = (nameH / baseNameHeight).clamp(0.8, 1.0);
  final double viewerScale = (viewerH / baseViewerHeight).clamp(0.8, 1.0);
  final double nameFont = (baseNameFont * nameScale).clamp(7.5, baseNameFont);
  final double viewerFont = (baseViewerFont * viewerScale).clamp(6.5, baseViewerFont);
  final double iconSize = (baseIcon * viewerScale).clamp(6.0, baseIcon);

  return _LiveItemLayout(
    circle: circle,
    nameHeight: nameH,
    viewerHeight: viewerH,
    nameFont: nameFont,
    viewerFont: viewerFont,
    iconSize: iconSize,
  );
}



