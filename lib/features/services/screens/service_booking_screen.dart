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

  @override
  void initState() {
    super.initState();
    // Initialize booking
    context.read<BookingBloc>().add(
          InitializeBookingEvent(
            serviceId: widget.service.id,
            astrologerId: widget.astrologerId,
            userId: widget.userId,
            servicePrice: widget.service.price,
          ),
        );

    // Load slots for default date
    _loadSlots();

    // Load add-ons
    context.read<ServiceBloc>().add(LoadServiceAddOnsEvent(widget.service.id));
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
              if (_availableAddOns.isNotEmpty) ...[
                _buildAddOns(themeService),
                const SizedBox(height: 24),
              ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeService.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themeService.primaryColor.withOpacity(0.1),
                  themeService.primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: themeService.primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              widget.service.icon,
              size: 28,
              color: themeService.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.service.name,
                  style: TextStyle(
                    color: themeService.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.service.formattedPrice} • ${widget.service.durationDisplay}',
                  style: TextStyle(
                    color: themeService.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
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
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                    color: themeService.primaryColor,
                  ),
                ),
              );
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

            return const SizedBox.shrink();
          },
        ),
      ],
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
                          ? themeService.primaryColor
                          : themeService.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: !isAvailable
                        ? themeService.borderColor.withOpacity(0.5)
                        : isSelected
                            ? themeService.primaryColor
                            : themeService.borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: themeService.primaryColor.withOpacity(0.3),
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
                    gradient: LinearGradient(
                      colors: [
                        themeService.primaryColor,
                        themeService.secondaryColor,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isValid
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

