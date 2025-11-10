import 'package:flutter/material.dart';

/// Minimal celebration animation for service completion
class ServiceCelebrationAnimation extends StatefulWidget {
  final String customerName;
  final String serviceName;
  final double amount;

  const ServiceCelebrationAnimation({
    super.key,
    required this.customerName,
    required this.serviceName,
    required this.amount,
  });

  @override
  State<ServiceCelebrationAnimation> createState() =>
      _ServiceCelebrationAnimationState();
}

class _ServiceCelebrationAnimationState
    extends State<ServiceCelebrationAnimation>
    with TickerProviderStateMixin {
  late AnimationController _checkmarkController;
  late AnimationController _contentController;

  @override
  void initState() {
    super.initState();

    // Checkmark scale animation
    _checkmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Content fade animation
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Start animation sequence
    _startAnimations();
  }

  void _startAnimations() async {
    // Show checkmark immediately
    _checkmarkController.forward();

    // Delay 300ms, then show content
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _contentController.forward();
    }
  }

  @override
  void dispose() {
    _checkmarkController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7, // Take up 70% of screen
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Checkmark Animation
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _checkmarkController,
                curve: Curves.elasticOut,
              ),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 70,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Success Message
            FadeTransition(
              opacity: _contentController,
              child: Column(
                children: [
                  const Text(
                    'Service Completed!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Service Details - Minimal
                  Text(
                    widget.serviceName,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.customerName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${widget.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

