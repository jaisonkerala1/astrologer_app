import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Sophisticated error state widget with retry functionality
/// Designed for professional error handling
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final String? retryText;
  final VoidCallback? onRetry;
  final IconData? icon;
  final Color? iconColor;
  final bool showRetryButton;
  final EdgeInsetsGeometry? padding;

  const ErrorStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.retryText,
    this.onRetry,
    this.icon,
    this.iconColor,
    this.showRetryButton = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Container(
          padding: padding ?? const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: (iconColor ?? Colors.red).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? Icons.error_outline,
                  size: 40,
                  color: iconColor ?? Colors.red,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Error title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Error message
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              if (showRetryButton) ...[
                const SizedBox(height: 32),
                _buildRetryButton(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRetryButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onRetry,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.refresh,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              retryText ?? 'Try Again',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Network error state with specific messaging
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const NetworkErrorWidget({
    super.key,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      title: 'Connection Error',
      message: customMessage ?? 
          'Unable to connect to the server. Please check your internet connection and try again.',
      icon: Icons.wifi_off,
      iconColor: Colors.orange,
      onRetry: onRetry,
      retryText: 'Retry Connection',
    );
  }
}

/// Server error state
class ServerErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const ServerErrorWidget({
    super.key,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      title: 'Server Error',
      message: customMessage ?? 
          'Something went wrong on our end. Please try again in a few moments.',
      icon: Icons.cloud_off,
      iconColor: Colors.red,
      onRetry: onRetry,
      retryText: 'Try Again',
    );
  }
}

/// Empty state widget
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final Color? iconColor;
  final String? actionText;
  final VoidCallback? onAction;
  final bool showActionButton;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.iconColor,
    this.actionText,
    this.onAction,
    this.showActionButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Empty state icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: (iconColor ?? Colors.grey).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? Icons.inbox_outlined,
                  size: 40,
                  color: iconColor ?? Colors.grey,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Empty state title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Empty state message
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              if (showActionButton && actionText != null && onAction != null) ...[
                const SizedBox(height: 32),
                _buildActionButton(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          actionText!,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Loading state with progress indicator
class LoadingStateWidget extends StatelessWidget {
  final String message;
  final double? progress;
  final bool showProgress;
  final Color? color;

  const LoadingStateWidget({
    super.key,
    required this.message,
    this.progress,
    this.showProgress = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Loading indicator
              Container(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: showProgress ? progress : null,
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    color ?? AppTheme.primaryColor,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Loading message
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              
              if (showProgress && progress != null) ...[
                const SizedBox(height: 16),
                Text(
                  '${(progress! * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


