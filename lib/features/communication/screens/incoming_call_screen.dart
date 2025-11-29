import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';

class IncomingCallScreen extends StatefulWidget {
  final String phoneNumber;
  final String contactName;

  const IncomingCallScreen({
    super.key,
    required this.phoneNumber,
    required this.contactName,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _acceptSwipeController;
  late AnimationController _declineSwipeController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isRinging = true;
  bool _isConnected = false;
  bool _isEnded = false;
  int _callDuration = 0;
  
  // Swipe gesture tracking
  double _acceptSwipeOffset = 0;
  double _declineSwipeOffset = 0;
  static const double _swipeThreshold = -80; // Negative because swipe up

  @override
  void initState() {
    super.initState();
    print('📞 [INCOMING CALL] Screen initialized for ${widget.contactName}');
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _acceptSwipeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _declineSwipeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _pulseController.repeat(reverse: true);
    _slideController.forward();
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
    print('📞 [INCOMING CALL] Screen disposing');
    _pulseController.dispose();
    _slideController.dispose();
    _acceptSwipeController.dispose();
    _declineSwipeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
            children: [
              // Status bar
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Spacer(),
                    Text(
                      _isRinging
                          ? 'Incoming Call'
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
                          scale: _isRinging ? _pulseAnimation.value : 1.0,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: themeService.primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: themeService.primaryColor.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 10,
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
                    
                    // Contact name
                    Text(
                      widget.contactName,
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
                    if (_isRinging) ...[
                      const Icon(
                        Icons.phone_callback,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Incoming call...',
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
              if (_isRinging)
                _buildIncomingCallControls(themeService)
              else if (_isConnected)
                _buildActiveCallControls(themeService),
            ],
          ),
        ),
      ),
        );
      },
    );
  }

  Widget _buildIncomingCallControls(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Accept button (left side) - Tap or Swipe Up
          _buildSwipeableCallButton(
            color: themeService.successColor,
            icon: Icons.call,
            label: 'Accept',
            swipeOffset: _acceptSwipeOffset,
            onTap: () {
              HapticFeedback.selectionClick();
              _acceptCall();
            },
            onSwipeUpdate: (offset) {
              setState(() {
                _acceptSwipeOffset = offset.clamp(-120.0, 0.0);
              });
            },
            onSwipeEnd: () {
              if (_acceptSwipeOffset <= _swipeThreshold) {
                HapticFeedback.heavyImpact();
                _acceptCall();
              } else {
                // Spring back
                setState(() {
                  _acceptSwipeOffset = 0;
                });
              }
            },
          ),
          
          // Message button (center)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _sendMessage();
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.message,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          
          // Decline button (right side) - Tap or Swipe Up
          _buildSwipeableCallButton(
            color: themeService.errorColor,
            icon: Icons.call_end,
            label: 'Decline',
            swipeOffset: _declineSwipeOffset,
            onTap: () {
              HapticFeedback.selectionClick();
              _declineCall();
            },
            onSwipeUpdate: (offset) {
              setState(() {
                _declineSwipeOffset = offset.clamp(-120.0, 0.0);
              });
            },
            onSwipeEnd: () {
              if (_declineSwipeOffset <= _swipeThreshold) {
                HapticFeedback.heavyImpact();
                _declineCall();
              } else {
                // Spring back
                setState(() {
                  _declineSwipeOffset = 0;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeableCallButton({
    required Color color,
    required IconData icon,
    required String label,
    required double swipeOffset,
    required VoidCallback onTap,
    required Function(double) onSwipeUpdate,
    required VoidCallback onSwipeEnd,
  }) {
    // Calculate progress (0 to 1) based on swipe
    final progress = (swipeOffset.abs() / _swipeThreshold.abs()).clamp(0.0, 1.0);
    final scale = 1.0 + (progress * 0.15); // Scale up slightly as you swipe
    final glowIntensity = 0.4 + (progress * 0.4); // Increase glow
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Swipe hint arrow (appears when swiping)
        AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: progress > 0.1 ? progress : 0,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Icon(
              Icons.keyboard_arrow_up,
              color: color.withOpacity(0.8),
              size: 24,
            ),
          ),
        ),
        
        // The button
        GestureDetector(
          onTap: onTap,
          onVerticalDragUpdate: (details) {
            onSwipeUpdate(swipeOffset + details.delta.dy);
          },
          onVerticalDragEnd: (details) {
            onSwipeEnd();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            transform: Matrix4.identity()
              ..translate(0.0, swipeOffset * 0.5) // Move up as you swipe
              ..scale(scale),
            transformAlignment: Alignment.center,
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(glowIntensity),
                  blurRadius: 16 + (progress * 16),
                  spreadRadius: 3 + (progress * 5),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        
        // Label
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveCallControls(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildControlButton(
            icon: Icons.mic_off,
            color: Colors.white.withOpacity(0.2),
            onTap: () {
              HapticFeedback.selectionClick();
              // TODO: Implement mute functionality
            },
          ),
          
          // Speaker button
          _buildControlButton(
            icon: Icons.volume_up,
            color: Colors.white.withOpacity(0.2),
            onTap: () {
              HapticFeedback.selectionClick();
              // TODO: Implement speaker functionality
            },
          ),
          
          // Keypad button
          _buildControlButton(
            icon: Icons.dialpad,
            color: Colors.white.withOpacity(0.2),
            onTap: () {
              HapticFeedback.selectionClick();
              // TODO: Implement keypad functionality
            },
          ),
          
          // End call button
          _buildControlButton(
            icon: Icons.call_end,
            color: themeService.errorColor,
            onTap: () {
              HapticFeedback.selectionClick();
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

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _acceptCall() {
    setState(() {
      _isRinging = false;
      _isConnected = true;
    });
    _pulseController.stop();
    _startCallTimer();
  }

  void _declineCall() {
    print('📞 [INCOMING CALL] Decline button pressed');
    if (_isEnded) {
      print('📞 [INCOMING CALL] Call already ended, ignoring');
      return;
    }
    
    setState(() {
      _isRinging = false;
      _isEnded = true;
    });
    print('📞 [INCOMING CALL] State updated - ringing: $_isRinging, ended: $_isEnded');
    _pulseController.stop();
    print('📞 [INCOMING CALL] Pulse animation stopped');
    
    // Close screen after a shorter delay
    Future.delayed(const Duration(milliseconds: 800), () {
      print('📞 [INCOMING CALL] Delayed navigation starting, mounted: $mounted');
      if (mounted && Navigator.canPop(context)) {
        print('📞 [INCOMING CALL] Navigating back from decline');
        Navigator.pop(context);
        print('📞 [INCOMING CALL] Navigation completed');
      } else {
        print('📞 [INCOMING CALL] Cannot navigate - mounted: $mounted, canPop: ${Navigator.canPop(context)}');
      }
    });
  }

  void _sendMessage() {
    // Decline call and open message screen
    Navigator.pop(context);
    // TODO: Navigate to message screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Message sent to ${widget.contactName}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _endCall() {
    print('📞 [INCOMING CALL] End call button pressed');
    if (_isEnded) {
      print('📞 [INCOMING CALL] Call already ended, ignoring');
      return;
    }
    
    setState(() {
      _isConnected = false;
      _isEnded = true;
    });
    print('📞 [INCOMING CALL] State updated - connected: $_isConnected, ended: $_isEnded');
    
    // Close screen after a delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      print('📞 [INCOMING CALL] Delayed navigation starting for end call, mounted: $mounted');
      if (mounted && Navigator.canPop(context)) {
        print('📞 [INCOMING CALL] Navigating back from end call');
        Navigator.pop(context);
        print('📞 [INCOMING CALL] Navigation completed');
      } else {
        print('📞 [INCOMING CALL] Cannot navigate - mounted: $mounted, canPop: ${Navigator.canPop(context)}');
      }
    });
  }
}
