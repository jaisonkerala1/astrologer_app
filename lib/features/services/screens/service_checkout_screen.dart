import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../services_exports.dart';
import 'service_confirmation_screen.dart';

class ServiceCheckoutScreen extends StatefulWidget {
  final ServiceModel service;
  final BookingModel booking;

  const ServiceCheckoutScreen({
    super.key,
    required this.service,
    required this.booking,
  });

  @override
  State<ServiceCheckoutScreen> createState() => _ServiceCheckoutScreenState();
}

class _ServiceCheckoutScreenState extends State<ServiceCheckoutScreen> {
  final _promoController = TextEditingController();
  bool _isPromoApplied = false;
  bool _termsAccepted = false;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _validatePromo(ThemeService themeService) {
    if (_promoController.text.trim().isEmpty) return;

    HapticFeedback.mediumImpact();
    context.read<ServiceBloc>().add(
          ValidatePromoCodeEvent(
            promoCode: _promoController.text.trim(),
            orderAmount: widget.booking.totalAmount,
          ),
        );
  }

  void _checkout(ThemeService themeService) {
    if (!_termsAccepted) {
      _showSnackBar('Please accept terms and conditions', themeService, isError: true);
      return;
    }

    HapticFeedback.mediumImpact();

    // TODO: Integrate Razorpay payment
    // For now, simulate successful payment
    final mockPaymentId = 'pay_mock_${DateTime.now().millisecondsSinceEpoch}';

    context.read<OrderBloc>().add(
          CreateOrderEvent(
            booking: widget.booking,
            paymentId: mockPaymentId,
            paymentMethod: 'Mock Payment',
          ),
        );
  }

  void _showSnackBar(String message, ThemeService themeService, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : themeService.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      backgroundColor: themeService.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: themeService.backgroundColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeService.surfaceColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: themeService.borderColor,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: themeService.textPrimary,
              size: 20,
            ),
          ),
        ),
        title: Text(
          'Checkout',
          style: TextStyle(
            color: themeService.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<ServiceBloc, ServiceState>(
            listener: (context, state) {
              if (state is PromoCodeValidated) {
                if (state.isValid) {
                  setState(() {
                    _isPromoApplied = true;
                  });
                  context.read<BookingBloc>().add(
                        ApplyPromoCodeEvent(
                          promoCode: _promoController.text.trim(),
                          discount: state.discount,
                        ),
                      );
                  _showSnackBar(state.message, themeService);
                } else {
                  _showSnackBar(state.message, themeService, isError: true);
                }
              }
            },
          ),
          BlocListener<OrderBloc, OrderState>(
            listener: (context, state) {
              if (state is OrderCreated) {
                // Navigate to confirmation screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceConfirmationScreen(
                      order: state.order,
                    ),
                  ),
                );
              } else if (state is OrderError) {
                _showSnackBar(state.message, themeService, isError: true);
              }
            },
          ),
        ],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBookingSummary(themeService),
              const SizedBox(height: 24),
              _buildPromoCode(themeService),
              const SizedBox(height: 24),
              _buildPriceSummary(themeService),
              const SizedBox(height: 24),
              _buildTermsAndConditions(themeService),
              const SizedBox(height: 100), // Space for button
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildPayButton(themeService),
    );
  }

  Widget _buildBookingSummary(ThemeService themeService) {
    return Container(
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
          Text(
            'Booking Summary',
            style: TextStyle(
              color: themeService.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),

          // Service
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeService.primaryColor.withOpacity(0.1),
                      themeService.primaryColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: themeService.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  widget.service.icon,
                  size: 24,
                  color: themeService.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.service.name,
                      style: TextStyle(
                        color: themeService.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.service.durationDisplay,
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
          ),
          const SizedBox(height: 16),
          Divider(color: themeService.borderColor),
          const SizedBox(height: 16),

          // Date & Time
          _buildInfoRow(
            Icons.calendar_today_rounded,
            'Date & Time',
            '${DateFormat('MMM d, yyyy').format(widget.booking.timeSlot.startTime)} • ${widget.booking.timeSlot.shortTime}',
            themeService,
          ),
          const SizedBox(height: 12),

          // Delivery Method
          _buildInfoRow(
            _getDeliveryMethodIcon(widget.booking.deliveryMethod),
            'Delivery',
            _getDeliveryMethodLabel(widget.booking.deliveryMethod),
            themeService,
          ),

          // Add-ons
          if (widget.booking.selectedAddOns.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.add_circle_outline_rounded,
              'Add-ons',
              '${widget.booking.selectedAddOns.length} selected',
              themeService,
            ),
          ],
        ],
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
        Text(
          value,
          style: TextStyle(
            color: themeService.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPromoCode(ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Promo Code',
          style: TextStyle(
            color: themeService.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: themeService.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isPromoApplied
                        ? themeService.primaryColor
                        : themeService.borderColor,
                    width: _isPromoApplied ? 2 : 1,
                  ),
                ),
                child: TextField(
                  controller: _promoController,
                  enabled: !_isPromoApplied,
                  decoration: InputDecoration(
                    hintText: 'Enter promo code',
                    hintStyle: TextStyle(
                      color: themeService.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: TextStyle(
                    color: themeService.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isPromoApplied
                  ? () {
                      setState(() {
                        _isPromoApplied = false;
                        _promoController.clear();
                      });
                      context.read<BookingBloc>().add(const RemovePromoCodeEvent());
                    }
                  : () => _validatePromo(themeService),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: _isPromoApplied
                      ? Colors.red
                      : themeService.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (_isPromoApplied ? Colors.red : themeService.primaryColor)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _isPromoApplied ? 'Remove' : 'Apply',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceSummary(ThemeService themeService) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        if (state is! BookingInProgress) {
          return const SizedBox.shrink();
        }

        final booking = state.booking;

        return Container(
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
              Text(
                'Price Breakdown',
                style: TextStyle(
                  color: themeService.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              _buildPriceRow(
                'Service Price',
                booking.servicePrice,
                themeService,
              ),
              if (booking.addOnsPrice > 0) ...[
                const SizedBox(height: 8),
                _buildPriceRow(
                  'Add-ons',
                  booking.addOnsPrice,
                  themeService,
                ),
              ],
              if (booking.platformFee > 0) ...[
                const SizedBox(height: 8),
                _buildPriceRow(
                  'Platform Fee',
                  booking.platformFee,
                  themeService,
                ),
              ],
              if (booking.discount > 0) ...[
                const SizedBox(height: 8),
                _buildPriceRow(
                  'Discount',
                  -booking.discount,
                  themeService,
                  isDiscount: true,
                ),
              ],
              const SizedBox(height: 12),
              Divider(color: themeService.borderColor),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      color: themeService.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '₹${booking.totalAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: themeService.primaryColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount,
    ThemeService themeService, {
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: themeService.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '${amount < 0 ? '-' : ''}₹${amount.abs().toStringAsFixed(0)}',
          style: TextStyle(
            color: isDiscount
                ? Colors.green
                : themeService.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsAndConditions(ThemeService themeService) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _termsAccepted = !_termsAccepted;
        });
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _termsAccepted
                  ? themeService.primaryColor
                  : themeService.surfaceColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _termsAccepted
                    ? themeService.primaryColor
                    : themeService.borderColor,
                width: 2,
              ),
            ),
            child: _termsAccepted
                ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: themeService.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms and Conditions',
                    style: TextStyle(
                      color: themeService.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Refund Policy',
                    style: TextStyle(
                      color: themeService.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' (7-day refund window)'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(ThemeService themeService) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        final isLoading = state is OrderCreating;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: themeService.backgroundColor,
            border: Border(
              top: BorderSide(
                color: themeService.borderColor,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: GestureDetector(
              onTap: isLoading ? null : () => _checkout(themeService),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _termsAccepted && !isLoading ? 1.0 : 0.5,
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
                    boxShadow: _termsAccepted && !isLoading
                        ? [
                            BoxShadow(
                              color:
                                  themeService.primaryColor.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Proceed to Payment',
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
            ),
          ),
        );
      },
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

