import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';

class OutgoingCallScreen extends StatefulWidget {
  final String phoneNumber;

  const OutgoingCallScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  bool _isConnecting = true;
  bool _isConnected = false;
  bool _isEnded = false;
  int _callDuration = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startCallSequence();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  void _startCallSequence() {
    // Simulate call progression
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _isConnected = true;
        });
        _startCallTimer();
      }
    });
  }

  void _startCallTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _isConnected && !_isEnded) {
        setState(() {
          _callDuration++;
        });
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
          children: [
            // Status bar
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    _isConnecting
                        ? 'Connecting...'
                        : _isConnected
                            ? 'Connected'
                            : 'Call Ended',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),
            
            // Main content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Contact avatar
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isConnecting ? _pulseAnimation.value : 1.0,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: themeService.primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: themeService.primaryColor.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 100,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Contact name/number
                  Text(
                    _getContactName(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    widget.phoneNumber,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 18,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Call status
                  if (_isConnecting) ...[
                    AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value * 2 * 3.14159,
                          child: const Icon(
                            Icons.phone,
                            color: Colors.white,
                            size: 32,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Calling...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ] else if (_isConnected) ...[
                    Icon(
                      Icons.phone,
                      color: themeService.successColor,
                      size: 32,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _formatDuration(_callDuration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.call_end,
                      color: themeService.errorColor,
                      size: 32,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Call Ended',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Call controls
            if (_isConnected) _buildCallControls(themeService),
          ],
        ),
      ),
        );
      },
    );
  }

  Widget _buildCallControls(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildControlButton(
            icon: Icons.mic_off,
            color: themeService.surfaceColor,
            onTap: () {
              HapticFeedback.lightImpact();
              // TODO: Implement mute functionality
            },
          ),
          
          // Speaker button
          _buildControlButton(
            icon: Icons.volume_up,
            color: themeService.surfaceColor,
            onTap: () {
              HapticFeedback.lightImpact();
              // TODO: Implement speaker functionality
            },
          ),
          
          // Keypad button
          _buildControlButton(
            icon: Icons.dialpad,
            color: themeService.surfaceColor,
            onTap: () {
              HapticFeedback.lightImpact();
              // TODO: Implement keypad functionality
            },
          ),
          
          // End call button
          _buildControlButton(
            icon: Icons.call_end,
            color: themeService.errorColor,
            onTap: () {
              HapticFeedback.lightImpact();
              _endCall();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  String _getContactName() {
    // Mock contact names based on phone number
    if (widget.phoneNumber.contains('+1')) {
      return 'John Doe';
    } else if (widget.phoneNumber.contains('+91')) {
      return 'Raj Kumar';
    } else if (widget.phoneNumber.contains('+44')) {
      return 'Sarah Miller';
    } else {
      return 'Unknown Contact';
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _endCall() {
    setState(() {
      _isConnected = false;
      _isEnded = true;
    });
    
    // Close screen after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }
}





