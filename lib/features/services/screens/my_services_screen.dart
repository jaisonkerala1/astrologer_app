import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../services_exports.dart';

class MyServicesScreen extends StatefulWidget {
  const MyServicesScreen({super.key});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedFilter;

  final List<Map<String, dynamic>> _filterTabs = [
    {'label': 'All', 'value': null},
    {'label': 'Upcoming', 'value': 'confirmed'},
    {'label': 'Completed', 'value': 'completed'},
    {'label': 'Cancelled', 'value': 'cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filterTabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Load orders on init
    context.read<OrderBloc>().add(const LoadMyOrdersEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final value = _filterTabs[_tabController.index]['value'];
      if (value != _selectedFilter) {
        setState(() {
          _selectedFilter = value;
        });
        _applyFilter();
      }
    }
  }

  void _applyFilter() {
    context.read<OrderBloc>().add(
          LoadMyOrdersEvent(status: _selectedFilter),
        );
  }

  Future<void> _onRefresh() async {
    context.read<OrderBloc>().add(
          LoadMyOrdersEvent(status: _selectedFilter),
        );
    // Wait for loading to complete
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      backgroundColor: themeService.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(themeService),
            _buildFilterTabs(themeService),
            Expanded(
              child: _buildOrdersList(themeService),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Orders',
                  style: TextStyle(
                    color: themeService.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Track your consultations',
                  style: TextStyle(
                    color: themeService.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
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
                Icons.close_rounded,
                color: themeService.textPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(ThemeService themeService) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filterTabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = _filterTabs[index];
          final isSelected = _tabController.index == index;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _tabController.animateTo(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? themeService.primaryColor
                    : themeService.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? themeService.primaryColor
                      : themeService.borderColor,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        // Outer glow
                        BoxShadow(
                          color: themeService.primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        // Subtle shadow for unselected chips
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Center(
                child: Text(
                  tab['label'],
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : themeService.textPrimary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersList(ThemeService themeService) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: themeService.primaryColor,
            ),
          );
        }

        if (state is OrderError) {
          return _buildEmptyState(
            Icons.error_outline_rounded,
            'Error',
            state.message,
            themeService,
          );
        }

        if (state is OrdersLoaded) {
          final orders = state.orders;

          if (orders.isEmpty) {
            return _buildEmptyState(
              Icons.shopping_bag_outlined,
              'No Orders Yet',
              'Book your first consultation to get started',
              themeService,
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: themeService.primaryColor,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildOrderCard(orders[index], themeService);
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildOrderCard(OrderModel order, ThemeService themeService) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // TODO: Navigate to order details
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeService.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: themeService.borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Order number + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderNumber,
                  style: TextStyle(
                    color: themeService.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                _buildStatusBadge(order.status, themeService),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: themeService.borderColor),
            const SizedBox(height: 12),

            // Service Name
            Text(
              order.serviceName,
              style: TextStyle(
                color: themeService.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            // Date & Time
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: themeService.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${DateFormat('MMM d, yyyy').format(order.booking.timeSlot.startTime)} at ${order.booking.timeSlot.shortTime}',
                  style: TextStyle(
                    color: themeService.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Amount
            Row(
              children: [
                Icon(
                  Icons.payment_rounded,
                  size: 14,
                  color: themeService.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '₹${order.booking.totalAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: themeService.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            // Actions for certain statuses
            if (order.status == OrderStatus.confirmed) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Cancel',
                      Icons.close_rounded,
                      Colors.red,
                      () => _cancelOrder(order, themeService),
                      themeService,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      'Reschedule',
                      Icons.edit_calendar_rounded,
                      themeService.primaryColor,
                      () {
                        // TODO: Implement reschedule
                      },
                      themeService,
                    ),
                  ),
                ],
              ),
            ] else if (order.status == OrderStatus.completed &&
                order.canRequestRefund) ...[
              const SizedBox(height: 12),
              _buildActionButton(
                'Request Refund (${order.refundDaysRemaining} days left)',
                Icons.sync_rounded,
                themeService.primaryColor,
                () => _requestRefund(order, themeService),
                themeService,
                fullWidth: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status, ThemeService themeService) {
    Color badgeColor;
    String label;

    switch (status) {
      case OrderStatus.pending:
        badgeColor = Colors.orange;
        label = 'Pending';
        break;
      case OrderStatus.confirmed:
        badgeColor = Colors.blue;
        label = 'Confirmed';
        break;
      case OrderStatus.inProgress:
        badgeColor = themeService.primaryColor;
        label = 'In Progress';
        break;
      case OrderStatus.completed:
        badgeColor = Colors.green;
        label = 'Completed';
        break;
      case OrderStatus.cancelled:
        badgeColor = Colors.red;
        label = 'Cancelled';
        break;
      case OrderStatus.refunded:
        badgeColor = Colors.purple;
        label = 'Refunded';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
    ThemeService themeService, {
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    IconData icon,
    String title,
    String subtitle,
    ThemeService themeService,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: themeService.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: themeService.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _cancelOrder(OrderModel order, ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<OrderBloc>().add(
                    CancelOrderEvent(
                      orderId: order.id,
                      reason: 'User cancelled',
                    ),
                  );
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _requestRefund(OrderModel order, ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Refund'),
        content: Text(
          'You have ${order.refundDaysRemaining} days left to request a refund. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<OrderBloc>().add(
                    RequestRefundEvent(order.id),
                  );
            },
            child: const Text('Request Refund'),
          ),
        ],
      ),
    );
  }
}

