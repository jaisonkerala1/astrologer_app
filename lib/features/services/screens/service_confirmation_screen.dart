import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../services_exports.dart';

class ServiceConfirmationScreen extends StatefulWidget {
  final OrderModel order;

  const ServiceConfirmationScreen({
    super.key,
    required this.order,
  });

  @override
  State<ServiceConfirmationScreen> createState() =>
      _ServiceConfirmationScreenState();
}

class _ServiceConfirmationScreenState extends State<ServiceConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      backgroundColor: themeService.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildSuccessAnimation(themeService),
              const SizedBox(height: 32),
              _buildOrderDetails(themeService),
              const SizedBox(height: 24),
              _buildNextSteps(themeService),
              const SizedBox(height: 24),
              _buildActions(themeService),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessAnimation(ThemeService themeService) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Column(
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      themeService.primaryColor,
                      themeService.secondaryColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeService.primaryColor.withOpacity(0.4),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    'Booking Confirmed!',
                    style: TextStyle(
                      color: themeService.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your consultation has been scheduled',
                    style: TextStyle(
                      color: themeService.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrderDetails(ThemeService themeService) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: themeService.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: themeService.borderColor,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Number
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Number',
                  style: TextStyle(
                    color: themeService.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: themeService.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.order.orderNumber,
                    style: TextStyle(
                      color: themeService.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: themeService.borderColor),
            const SizedBox(height: 16),

            // Service Name
            Text(
              widget.order.serviceName,
              style: TextStyle(
                color: themeService.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),

            // Date & Time
            _buildInfoRow(
              Icons.calendar_today_rounded,
              'Date & Time',
              '${DateFormat('MMM d, yyyy').format(widget.order.booking.timeSlot.startTime)} at ${widget.order.booking.timeSlot.shortTime}',
              themeService,
            ),
            const SizedBox(height: 12),

            // Delivery Method
            _buildInfoRow(
              _getDeliveryMethodIcon(widget.order.booking.deliveryMethod),
              'Method',
              _getDeliveryMethodLabel(widget.order.booking.deliveryMethod),
              themeService,
            ),
            const SizedBox(height: 12),

            // Amount Paid
            _buildInfoRow(
              Icons.payment_rounded,
              'Amount Paid',
              '₹${widget.order.booking.totalAmount.toStringAsFixed(0)}',
              themeService,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ThemeService themeService,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: themeService.primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: themeService.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: themeService.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildNextSteps(ThemeService themeService) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              themeService.primaryColor.withOpacity(0.1),
              themeService.primaryColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: themeService.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: themeService.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'What\'s Next?',
                  style: TextStyle(
                    color: themeService.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildNextStepItem(
              '📧',
              'Confirmation email sent',
              'Check your email for booking details',
              themeService,
            ),
            const SizedBox(height: 12),
            _buildNextStepItem(
              '🔔',
              'We\'ll remind you',
              'You\'ll get a reminder 1 hour before',
              themeService,
            ),
            const SizedBox(height: 12),
            _buildNextStepItem(
              '💬',
              'Join on time',
              'Access your consultation from "My Orders"',
              themeService,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextStepItem(
    String emoji,
    String title,
    String subtitle,
    ThemeService themeService,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: themeService.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: themeService.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(ThemeService themeService) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // View My Orders button
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              // TODO: Navigate to My Orders screen
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeService.primaryColor,
                    themeService.secondaryColor,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: themeService.primaryColor.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'View My Orders',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Back to Home button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: themeService.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: themeService.borderColor,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  'Back to Home',
                  style: TextStyle(
                    color: themeService.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDeliveryMethodIcon(DeliveryMethod method) {
    switch (method) {
      case DeliveryMethod.videoCall:
        return Icons.videocam_rounded;
      case DeliveryMethod.audioCall:
        return Icons.call_rounded;
      case DeliveryMethod.chat:
        return Icons.chat_rounded;
      case DeliveryMethod.report:
        return Icons.description_rounded;
    }
  }

  String _getDeliveryMethodLabel(DeliveryMethod method) {
    switch (method) {
      case DeliveryMethod.videoCall:
        return 'Video Call';
      case DeliveryMethod.audioCall:
        return 'Audio Call';
      case DeliveryMethod.chat:
        return 'Chat';
      case DeliveryMethod.report:
        return 'Report';
    }
  }
}

