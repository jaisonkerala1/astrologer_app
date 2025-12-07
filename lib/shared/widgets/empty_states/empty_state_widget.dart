import 'package:flutter/material.dart';
import '../../theme/services/theme_service.dart';

/// Swiggy-style empty state widget
/// Beautiful, delightful, and theme-aware
/// 
/// Features:
/// - Custom animated illustration
/// - Warm, friendly copy
/// - Optional CTA button
/// - Smooth fade + scale animations
/// - Fully theme-responsive
class EmptyStateWidget extends StatefulWidget {
  final Widget illustration;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final ThemeService themeService;
  
  const EmptyStateWidget({
    super.key,
    required this.illustration,
    required this.title,
    required this.message,
    required this.themeService,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Illustration
                SizedBox(
                  width: 200,
                  height: 200,
                  child: widget.illustration,
                ),
                
                const SizedBox(height: 32),
                
                // Title - Swiggy style (friendly, warm)
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.themeService.textPrimary,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                // Message - contextual, helpful
                Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 15,
                    color: widget.themeService.textSecondary,
                    height: 1.5,
                    letterSpacing: 0.1,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                // Action Button (if provided)
                if (widget.actionLabel != null && widget.onActionPressed != null) ...[
                  const SizedBox(height: 32),
                  _buildActionButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onActionPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.themeService.primaryColor,
                widget.themeService.primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.themeService.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.actionLabel!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

