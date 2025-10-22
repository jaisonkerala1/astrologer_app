import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

/// Earnings dashboard mockup for onboarding
class EarningsDashboardMockup extends StatefulWidget {
  const EarningsDashboardMockup({super.key});

  @override
  State<EarningsDashboardMockup> createState() => _EarningsDashboardMockupState();
}

class _EarningsDashboardMockupState extends State<EarningsDashboardMockup> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _todayEarningsAnimation;
  late Animation<double> _totalEarningsAnimation;
  late Animation<double> _callsAnimation;
  late Animation<double> _ratingAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Today's earnings: 0 → 2450
    _todayEarningsAnimation = Tween<double>(
      begin: 0,
      end: 2450,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
    ));

    // Total earnings: 0 → 45670
    _totalEarningsAnimation = Tween<double>(
      begin: 0,
      end: 45670,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    ));

    // Calls: 0 → 24
    _callsAnimation = Tween<double>(
      begin: 0,
      end: 24,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
    ));

    // Rating: 0 → 4.8
    _ratingAnimation = Tween<double>(
      begin: 0,
      end: 4.8,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
    ));

    // Start animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat('#,##,###', 'en_IN');
    return '₹${formatter.format(value.round())}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Dr. Sharma',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2, end: 0),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF89B4F8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 18),
          
          // Earnings Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF34A853),
                  Color(0xFF1E8E3E),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Earnings',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedBuilder(
                  animation: _todayEarningsAnimation,
                  builder: (context, child) {
                    return Text(
                      _formatCurrency(_todayEarningsAnimation.value),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Earnings',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _totalEarningsAnimation,
                      builder: (context, child) {
                        return Text(
                          _formatCurrency(_totalEarningsAnimation.value),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
          
          const SizedBox(height: 12),
          
          // Stats cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            color: Color(0xFF89B4F8),
                            size: 16,
                          ).animate(delay: 500.ms).scale(
                            duration: 400.ms,
                            curve: Curves.elasticOut,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Calls',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      AnimatedBuilder(
                        animation: _callsAnimation,
                        builder: (context, child) {
                          return Text(
                            _callsAnimation.value.round().toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.2, end: 0),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Color(0xFFFBBC05),
                            size: 16,
                          ).animate(delay: 600.ms).scale(
                            duration: 400.ms,
                            curve: Curves.elasticOut,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Rating',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      AnimatedBuilder(
                        animation: _ratingAnimation,
                        builder: (context, child) {
                          return Text(
                            _ratingAnimation.value.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 500.ms).slideY(begin: 0.2, end: 0),
              ),
            ],
          ),
          
          const Spacer(),
        ],
      ),
    );
  }
}




