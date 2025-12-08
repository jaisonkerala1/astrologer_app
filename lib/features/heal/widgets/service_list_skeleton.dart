import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';

/// Beautiful skeleton loader for service management screen
/// Inspired by astrologer discovery page shimmer design
class ServiceListSkeleton extends StatelessWidget {
  const ServiceListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildServiceCardSkeleton(themeService),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceCardSkeleton(ThemeService themeService) {
    return Container(
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: themeService.borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Service name + Status chip
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service name
                      _buildShimmerBox(
                        width: 150,
                        height: 16,
                        radius: 6,
                        themeService: themeService,
                      ),
                      const SizedBox(height: 6),
                      // Category
                      _buildShimmerBox(
                        width: 100,
                        height: 12,
                        radius: 4,
                        themeService: themeService,
                      ),
                    ],
                  ),
                ),
                // Status chip
                _buildShimmerBox(
                  width: 60,
                  height: 24,
                  radius: 20,
                  themeService: themeService,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Info row: Duration + Price
            Row(
              children: [
                _buildShimmerBox(
                  width: 80,
                  height: 12,
                  radius: 4,
                  themeService: themeService,
                ),
                const SizedBox(width: 16),
                _buildShimmerBox(
                  width: 70,
                  height: 12,
                  radius: 4,
                  themeService: themeService,
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Category row
            _buildShimmerBox(
              width: 120,
              height: 12,
              radius: 4,
              themeService: themeService,
            ),
            
            const SizedBox(height: 12),
            
            // Description box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeService.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBox(
                    width: double.infinity,
                    height: 10,
                    radius: 4,
                    themeService: themeService,
                  ),
                  const SizedBox(height: 6),
                  _buildShimmerBox(
                    width: 200,
                    height: 10,
                    radius: 4,
                    themeService: themeService,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons row
            Row(
              children: [
                // Edit button (primary - wider)
                Expanded(
                  child: _buildShimmerBox(
                    width: double.infinity,
                    height: 40,
                    radius: 100,
                    themeService: themeService,
                  ),
                ),
                const SizedBox(width: 8),
                // Icon button 1
                _buildShimmerCircle(
                  radius: 20,
                  themeService: themeService,
                ),
                const SizedBox(width: 8),
                // Icon button 2
                _buildShimmerCircle(
                  radius: 20,
                  themeService: themeService,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    required double radius,
    required ThemeService themeService,
  }) {
    return _ShimmerWidget(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: themeService.isDarkMode()
              ? Colors.grey[800]!
              : Colors.grey[200]!,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  Widget _buildShimmerCircle({
    required double radius,
    required ThemeService themeService,
  }) {
    return _ShimmerWidget(
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: themeService.isDarkMode()
              ? Colors.grey[800]!
              : Colors.grey[200]!,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Beautiful shimmer animation widget
/// Same as discovery page - smooth gradient sweep
class _ShimmerWidget extends StatefulWidget {
  final Widget child;

  const _ShimmerWidget({required this.child});

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + (_controller.value * 2), 0),
              end: Alignment(1.0 + (_controller.value * 2), 0),
              colors: themeService.isDarkMode()
                  ? [
                      Colors.grey[800]!,
                      Colors.grey[700]!,
                      Colors.grey[800]!,
                    ]
                  : [
                      Colors.grey[200]!,
                      Colors.grey[50]!,
                      Colors.grey[200]!,
                    ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

