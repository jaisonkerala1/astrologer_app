import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../services_exports.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String serviceId;
  final String? heroTag; // For hero animation

  const ServiceDetailScreen({
    super.key,
    required this.serviceId,
    this.heroTag,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  DeliveryMethod? _selectedDeliveryMethod;

  @override
  void initState() {
    super.initState();
    // Load service details - the repository will handle both mock services and profile services
    context.read<ServiceBloc>().add(LoadServiceDetailEvent(widget.serviceId));
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      backgroundColor: themeService.backgroundColor,
      body: BlocBuilder<ServiceBloc, ServiceState>(
        builder: (context, state) {
          if (state is ServiceLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: themeService.primaryColor,
              ),
            );
          }

          if (state is ServiceError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: themeService.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: TextStyle(
                      color: themeService.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is! ServiceDetailLoaded) {
            return const SizedBox.shrink();
          }

          final service = state.service;

          // Set default delivery method if not set
          if (_selectedDeliveryMethod == null &&
              service.availableDeliveryMethods.isNotEmpty) {
            _selectedDeliveryMethod = service.availableDeliveryMethods.first;
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(themeService),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroSection(service, themeService),
                    _buildDeliveryMethods(service, themeService),
                    _buildWhatsIncluded(service, themeService),
                    _buildHowItWorks(service, themeService),
                    if (service.totalBookings > 0)
                      _buildStats(service, themeService),
                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<ServiceBloc, ServiceState>(
        builder: (context, state) {
          if (state is! ServiceDetailLoaded) return const SizedBox.shrink();
          return _buildBookNowButton(state.service, themeService);
        },
      ),
    );
  }

  Widget _buildAppBar(ThemeService themeService) {
    return SliverAppBar(
      pinned: true,
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
      actions: [
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            // TODO: Add to favorites
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
              Icons.favorite_border_rounded,
              color: themeService.textPrimary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildHeroSection(ServiceModel service, ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon with gradient background
          Hero(
            tag: widget.heroTag ?? 'service_${service.id}',
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeService.primaryColor.withOpacity(0.1),
                    themeService.primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: themeService.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                service.icon,
                size: 36,
                color: themeService.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Service name
          Text(
            service.name,
            style: TextStyle(
              color: themeService.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            service.description,
            style: TextStyle(
              color: themeService.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Price and duration
          Row(
            children: [
              // Price
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: themeService.surfaceColor,
                  borderRadius: BorderRadius.circular(24), // Pill shape
                  border: Border.all(
                    color: themeService.borderColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.currency_rupee,
                      size: 18,
                      color: themeService.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      service.formattedPrice.replaceAll('₹', ''),
                      style: TextStyle(
                        color: themeService.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Duration
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: themeService.surfaceColor,
                  borderRadius: BorderRadius.circular(24), // Pill shape
                  border: Border.all(
                    color: themeService.borderColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 18,
                      color: themeService.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      service.durationDisplay,
                      style: TextStyle(
                        color: themeService.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryMethods(
      ServiceModel service, ThemeService themeService) {
    if (service.availableDeliveryMethods.isEmpty) {
      return const SizedBox.shrink();
    }

    const greenColor = Color(0xFF1ca672); // Match Book Now button

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Method',
            style: TextStyle(
              color: themeService.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Add all available delivery methods
              ...service.availableDeliveryMethods.map((method) {
                final isSelected = _selectedDeliveryMethod == method;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedDeliveryMethod = method;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? greenColor
                          : themeService.surfaceColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected
                            ? greenColor
                            : themeService.borderColor.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: greenColor.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getDeliveryMethodIcon(method),
                          size: 17,
                          color: isSelected
                              ? Colors.white
                              : themeService.textSecondary,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          _getDeliveryMethodLabel(method),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : themeService.textPrimary,
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              // Always show Report option for visual effect (even if not in availableDeliveryMethods)
              if (!service.availableDeliveryMethods.contains(DeliveryMethod.report))
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedDeliveryMethod = DeliveryMethod.report;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedDeliveryMethod == DeliveryMethod.report
                          ? greenColor
                          : themeService.surfaceColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: _selectedDeliveryMethod == DeliveryMethod.report
                            ? greenColor
                            : themeService.borderColor.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: _selectedDeliveryMethod == DeliveryMethod.report ? [
                        BoxShadow(
                          color: greenColor.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.description_rounded,
                          size: 17,
                          color: _selectedDeliveryMethod == DeliveryMethod.report
                              ? Colors.white
                              : themeService.textSecondary,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Report',
                          style: TextStyle(
                            color: _selectedDeliveryMethod == DeliveryMethod.report
                                ? Colors.white
                                : themeService.textPrimary,
                            fontSize: 14,
                            fontWeight: _selectedDeliveryMethod == DeliveryMethod.report ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsIncluded(ServiceModel service, ThemeService themeService) {
    if (service.whatsIncluded.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s Included',
            style: TextStyle(
              color: themeService.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
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
              children: service.whatsIncluded.asMap().entries.map((entry) {
                final isLast = entry.key == service.whatsIncluded.length - 1;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: themeService.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: themeService.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: themeService.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(ServiceModel service, ThemeService themeService) {
    if (service.howItWorks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How It Works',
            style: TextStyle(
              color: themeService.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...service.howItWorks.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == service.howItWorks.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: themeService.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: themeService.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: themeService.borderColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 6,
                      bottom: isLast ? 0 : 0,
                    ),
                    child: Text(
                      step,
                      style: TextStyle(
                        color: themeService.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStats(ServiceModel service, ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              Icons.people_rounded,
              service.totalBookings.toString(),
              'Bookings',
              themeService,
            ),
            Container(
              width: 1,
              height: 40,
              color: themeService.borderColor,
            ),
            _buildStatItem(
              Icons.star_rounded,
              service.averageRating.toStringAsFixed(1),
              'Rating',
              themeService,
            ),
            Container(
              width: 1,
              height: 40,
              color: themeService.borderColor,
            ),
            _buildStatItem(
              Icons.rate_review_rounded,
              service.reviewCount.toString(),
              'Reviews',
              themeService,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    ThemeService themeService,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: themeService.primaryColor,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: themeService.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: themeService.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBookNowButton(
      ServiceModel service, ThemeService themeService) {
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
          onTap: () {
            HapticFeedback.mediumImpact();
            
            // Ensure delivery method is selected
            if (_selectedDeliveryMethod == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Please select a delivery method'),
                  backgroundColor: Colors.red.shade600,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            
            // Navigate to booking screen with fresh BLoCs sharing the same repository
            final serviceBloc = context.read<ServiceBloc>();
            final repository = serviceBloc.repository;

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
                  child: ServiceBookingScreen(
                    service: service,
                    astrologerId: service.astrologerId,
                    userId: 'user_123', // TODO: Get from auth service
                  ),
                ),
              ),
            );
          },
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
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1ca672).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'Book Now',
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

