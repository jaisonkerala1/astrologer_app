import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../services_exports.dart';

class ServiceBookingScreen extends StatefulWidget {
  final ServiceModel service;
  final String astrologerId;
  final String userId;

  const ServiceBookingScreen({
    super.key,
    required this.service,
    required this.astrologerId,
    required this.userId,
  });

  @override
  State<ServiceBookingScreen> createState() => _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends State<ServiceBookingScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeSlotModel? _selectedSlot;
  final List<AddOnModel> _availableAddOns = [];
  final Set<String> _selectedAddOnIds = {};
  bool _addOnsLoaded = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize booking first
    context.read<BookingBloc>().add(
          InitializeBookingEvent(
            serviceId: widget.service.id,
            astrologerId: widget.astrologerId,
            userId: widget.userId,
            servicePrice: widget.service.price,
          ),
        );

    // Load add-ons
    context.read<ServiceBloc>().add(LoadServiceAddOnsEvent(widget.service.id));
    
    // Load slots for default date - use addPostFrameCallback to ensure BLoC is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSlots();
    });
  }

  void _loadSlots() {
    context.read<ServiceBloc>().add(
          LoadAvailableSlotsEvent(
            astrologerId: widget.astrologerId,
            date: _selectedDate,
            durationInMinutes: widget.service.durationInMinutes,
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
          'Book Service',
          style: TextStyle(
            color: themeService.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocListener<ServiceBloc, ServiceState>(
        listener: (context, state) {
          if (state is ServiceAddOnsLoaded) {
            setState(() {
              _addOnsLoaded = true;
              _availableAddOns.clear();
              _availableAddOns.addAll(state.addOns);
            });
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildServiceInfo(themeService),
              const SizedBox(height: 24),
              _buildDateSelector(themeService),
              const SizedBox(height: 24),
              _buildTimeSlots(themeService),
              const SizedBox(height: 24),
              _buildAddOnsSection(themeService),
              const SizedBox(height: 24),
              _buildPriceSummary(themeService),
              const SizedBox(height: 100), // Space for button
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildContinueButton(themeService),
    );
  }

  Widget _buildServiceInfo(ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeService.borderColor.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            // Get the current repository from BookingBloc
            final bookingBloc = context.read<BookingBloc>();
            final repository = bookingBloc.repository;

            // Navigate to service detail screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MultiBlocProvider(
                  providers: [
                    BlocProvider<ServiceBloc>(
                      create: (_) => ServiceBloc(repository: repository),
                    ),
                    BlocProvider<BookingBloc>(
                      create: (_) => BookingBloc(repository: repository),
                    ),
                    BlocProvider<OrderBloc>(
                      create: (_) => OrderBloc(repository: repository),
                    ),
                  ],
                  child: ServiceDetailScreen(
                    serviceId: widget.service.id,
                    heroTag: 'service_booking_${widget.service.id}',
                  ),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon - flat minimal design
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: themeService.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.service.icon,
                    size: 26,
                    color: themeService.primaryColor,
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.service.name,
                              style: TextStyle(
                                color: themeService.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // "View" chip indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: themeService.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: themeService.primaryColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 10,
                                  color: themeService.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Price and duration
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: themeService.surfaceColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: themeService.borderColor.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.currency_rupee,
                                  size: 12,
                                  color: themeService.textPrimary,
                                ),
                                Text(
                                  widget.service.price.toStringAsFixed(0),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: themeService.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: themeService.surfaceColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: themeService.borderColor.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 11,
                                  color: themeService.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.service.durationDisplay,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: themeService.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: TextStyle(
            color: themeService.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 14, // Next 14 days
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index + 1));
              final isSelected = DateFormat('yyyy-MM-dd').format(date) ==
                  DateFormat('yyyy-MM-dd').format(_selectedDate);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedDate = date;
                    _selectedSlot = null; // Reset slot selection
                  });
                  _loadSlots();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 70,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? themeService.primaryColor
                        : themeService.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? themeService.primaryColor
                          : themeService.borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color:
                                  themeService.primaryColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE').format(date),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : themeService.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('d').format(date),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : themeService.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlots(ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Time Slot',
          style: TextStyle(
            color: themeService.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        BlocBuilder<ServiceBloc, ServiceState>(
          builder: (context, state) {
            if (state is ServiceLoading) {
              return _buildTimeSlotsSkeleton(themeService);
            }

            if (state is ServiceSlotsLoaded) {
              final slots = state.slots;
              if (slots.isEmpty) {
                return _buildEmptyState(
                  'No slots available',
                  'Please select another date',
                  themeService,
                );
              }

              // Group by time of day
              final morningSlots =
                  slots.where((s) => s.startTime.hour < 12).toList();
              final afternoonSlots = slots
                  .where((s) => s.startTime.hour >= 12 && s.startTime.hour < 18)
                  .toList();
              final eveningSlots =
                  slots.where((s) => s.startTime.hour >= 18).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (morningSlots.isNotEmpty)
                    _buildTimeSlotGroup('Morning', morningSlots, themeService),
                  if (afternoonSlots.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildTimeSlotGroup(
                        'Afternoon', afternoonSlots, themeService),
                  ],
                  if (eveningSlots.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildTimeSlotGroup('Evening', eveningSlots, themeService),
                  ],
                ],
              );
            }

            // Initial or unknown state - show skeleton to keep layout stable
            return _buildTimeSlotsSkeleton(themeService);
          },
        ),
      ],
    );
  }

  /// Premium minimal skeleton loader for time slots
  Widget _buildTimeSlotsSkeleton(ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < 3; i++) ...[
          // Group label skeleton (matches \"Morning / Afternoon / Evening\" height)
          Container(
            width: 80,
            height: 14,
            decoration: BoxDecoration(
              color: themeService.surfaceColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          // Row of slot pills skeleton
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(3, (_) => _buildSkeletonSlot(themeService)),
          ),
          if (i < 2) const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildSkeletonSlot(ThemeService themeService) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 90,
            height: 38,
            decoration: BoxDecoration(
              color: themeService.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: themeService.borderColor.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
        );
      },
      onEnd: () {
        // Restart animation for a soft shimmer-like effect
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildTimeSlotGroup(
    String title,
    List<TimeSlotModel> slots,
    ThemeService themeService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: themeService.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final isSelected = _selectedSlot?.id == slot.id;
            final isAvailable = slot.isAvailable;

            return GestureDetector(
              onTap: isAvailable
                  ? () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedSlot = slot;
                      });
                      context
                          .read<BookingBloc>()
                          .add(UpdateTimeSlotEvent(slot));
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: !isAvailable
                      ? themeService.surfaceColor.withOpacity(0.5)
                      : isSelected
                          ? const Color(0xFF1ca672) // Green color
                          : themeService.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: !isAvailable
                        ? themeService.borderColor.withOpacity(0.5)
                        : isSelected
                            ? const Color(0xFF1ca672) // Green color
                            : themeService.borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF1ca672).withOpacity(0.3), // Green shadow
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  slot.shortTime,
                  style: TextStyle(
                    color: !isAvailable
                        ? themeService.textSecondary.withOpacity(0.5)
                        : isSelected
                            ? Colors.white
                            : themeService.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration:
                        !isAvailable ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Wrapper that keeps the Add-ons section in a stable vertical position
  /// while data is loading, loaded, or when there are no add-ons.
  Widget _buildAddOnsSection(ThemeService themeService) {
    // Still loading add-ons -> show skeleton cards in place
    if (!_addOnsLoaded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add-ons (Optional)',
            style: TextStyle(
              color: themeService.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(2, (_) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                height: 64,
                decoration: BoxDecoration(
                  color: themeService.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: themeService.borderColor.withOpacity(0.4),
                    width: 1,
                  ),
                ),
              );
            }),
          ),
        ],
      );
    }

    // Loaded but no add-ons -> keep section, show subtle message
    if (_availableAddOns.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add-ons (Optional)',
            style: TextStyle(
              color: themeService.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No add-ons available for this service',
            style: TextStyle(
              color: themeService.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      );
    }

    // Normal case: show real add-ons
    return _buildAddOns(themeService);
  }

  Widget _buildAddOns(ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add-ons (Optional)',
          style: TextStyle(
            color: themeService.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        ..._availableAddOns.map((addOn) {
          final isSelected = _selectedAddOnIds.contains(addOn.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isSelected) {
                    _selectedAddOnIds.remove(addOn.id);
                  } else {
                    _selectedAddOnIds.add(addOn.id);
                  }
                });
                context.read<BookingBloc>().add(ToggleAddOnEvent(addOn));
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? themeService.primaryColor.withOpacity(0.1)
                      : themeService.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? themeService.primaryColor
                        : themeService.borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? themeService.primaryColor
                            : themeService.surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? themeService.primaryColor
                              : themeService.borderColor,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 20,
                              )
                            : Text(
                                addOn.icon,
                                style: const TextStyle(fontSize: 20),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                addOn.name,
                                style: TextStyle(
                                  color: themeService.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (addOn.isPopular) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: themeService.primaryColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Popular',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            addOn.description,
                            style: TextStyle(
                              color: themeService.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '+₹${addOn.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: themeService.primaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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
                'Price Summary',
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
              const SizedBox(height: 12),
              Divider(color: themeService.borderColor),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
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
    ThemeService themeService,
  ) {
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
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: themeService.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(ThemeService themeService) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        final isValid =
            state is BookingInProgress && state.isValid && _selectedSlot != null;

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
              onTap: isValid
                  ? () {
                      HapticFeedback.mediumImpact();
                      // TODO: Navigate to checkout
                    }
                  : null,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isValid ? 1.0 : 0.5,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1ca672), // Primary green
                        Color(0xFF1fb67d), // Minimal gradient - slightly lighter
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(28), // Pill shape
                    boxShadow: isValid
                        ? [
                            BoxShadow(
                              color: const Color(0xFF1ca672).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: const Center(
                    child: Text(
                      'Continue to Checkout',
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

  Widget _buildEmptyState(
    String title,
    String subtitle,
    ThemeService themeService,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 64,
            color: themeService.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: themeService.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: themeService.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

