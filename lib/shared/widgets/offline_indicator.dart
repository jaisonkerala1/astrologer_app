import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/connectivity_service.dart';
import 'network_tower_illustration.dart';

/// Beautiful full-screen offline indicator
/// Shows when user is offline with elegant design
class OfflineIndicator extends StatefulWidget {
  final Widget child;
  
  const OfflineIndicator({
    super.key,
    required this.child,
  });

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isRetrying = false;

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
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showOverlay() {
    _animationController.forward();
  }

  void _hideOverlay() {
    _animationController.reverse();
  }

  Future<void> _handleRetry(ConnectivityService connectivity) async {
    setState(() => _isRetrying = true);
    await connectivity.refresh();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, child) {
        // Show full-screen overlay when offline
        if (!connectivity.isOnline) {
          _showOverlay();
        } else {
          _hideOverlay();
        }

        return Stack(
          children: [
            // Main content (blurred when offline)
            child!,
            
            // Full-screen offline overlay
            if (!connectivity.isOnline)
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildFullScreenOverlay(context, connectivity),
              ),
          ],
        );
      },
      child: widget.child,
    );
  }

  Widget _buildFullScreenOverlay(BuildContext context, ConnectivityService connectivity) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: SafeArea(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Illustration/Icon
              _buildIllustration(),
              
              const SizedBox(height: 40),
              
              // Title
              const Text(
                'No Internet Connection',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  connectivity.hasConnection
                      ? 'Please check your internet connection\nand try again'
                      : 'Please check your WiFi or mobile data\nand try again',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Retry Button
              _buildRetryButton(connectivity),
              
              const Spacer(flex: 3),
              
              // Footer hint
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'You\'ll automatically reconnect when back online',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    // Custom painted network tower with animations
    return const NetworkTowerIllustration(
      size: 200,
    );
  }

  Widget _buildRetryButton(ConnectivityService connectivity) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isRetrying ? null : () => _handleRetry(connectivity),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade500,
                Colors.orange.shade600,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isRetrying)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              const SizedBox(width: 10),
              Text(
                _isRetrying ? 'Checking...' : 'Try Again',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal offline indicator for bottom of screen
class MinimalOfflineIndicator extends StatelessWidget {
  const MinimalOfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, child) {
        if (connectivity.isOnline) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.orange.shade100,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 14,
                color: Colors.orange.shade800,
              ),
              const SizedBox(width: 6),
              Text(
                'Offline mode',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange.shade800,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => connectivity.refresh(),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

