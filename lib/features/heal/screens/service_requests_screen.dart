import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../core/constants/app_constants.dart';
import '../models/service_request_model.dart';
import '../widgets/service_request_card_widget.dart';
import '../widgets/service_request_list_skeleton.dart';
import '../bloc/heal_bloc.dart';
import '../bloc/heal_event.dart';
import '../bloc/heal_state.dart';

class ServiceRequestsScreen extends StatefulWidget {
  final String searchQuery;
  const ServiceRequestsScreen({super.key, this.searchQuery = ''});

  @override
  State<ServiceRequestsScreen> createState() => _ServiceRequestsScreenState();
}

class _ServiceRequestsScreenState extends State<ServiceRequestsScreen> {
  String _selectedFilter = 'all';
  String? _lastUpdatedRequestId;
  RequestStatus? _lastStatus;

  @override
  void initState() {
    super.initState();
    // Load service requests via BLoC
    context.read<HealBloc>().add(const LoadServiceRequestsEvent());
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return BlocConsumer<HealBloc, HealState>(
          listener: (context, state) {
            // ❌ ONLY show error messages with retry (optimistic UI shows success visually)
            if (state is HealLoadedState && state.errorMessage != null) {
              HapticFeedback.mediumImpact();
              
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red.shade600,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 4),
                  action: _lastUpdatedRequestId != null && _lastStatus != null
                      ? SnackBarAction(
                          label: 'RETRY',
                          textColor: Colors.white,
                          onPressed: () {
                            context.read<HealBloc>().add(
                              UpdateRequestStatusEvent(
                                _lastUpdatedRequestId!,
                                _lastStatus!,
                              ),
                            );
                          },
                        )
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.all(16),
                ),
              );
            }
            
            // Show errors (old error state - fallback)
            if (state is HealErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red.shade600,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            print('📘 [ServiceRequests] State: ${state.runtimeType}');
            
            return Scaffold(
              backgroundColor: themeService.backgroundColor,
              body: Column(
                children: [
                  // Filter Chips
                  _buildFilterChips(state, l10n, themeService),
                  
                  // Requests List
                  Expanded(
                    child: _buildRequestsList(state, l10n, themeService),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChips(HealState state, AppLocalizations l10n, ThemeService themeService) {
    // Get requests from state
    final requests = state is HealLoadedState ? state.serviceRequests : <ServiceRequest>[];
    
    final filters = [
      {'key': 'all', 'label': 'All', 'count': requests.length},
      {'key': 'pending', 'label': 'Pending', 'count': requests.where((r) => r.status == RequestStatus.pending).length},
      {'key': 'confirmed', 'label': 'Confirmed', 'count': requests.where((r) => r.status == RequestStatus.confirmed).length},
      {'key': 'in_progress', 'label': 'In Progress', 'count': requests.where((r) => r.status == RequestStatus.inProgress).length},
      {'key': 'completed', 'label': 'Completed', 'count': requests.where((r) => r.status == RequestStatus.completed).length},
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: themeService.surfaceColor,
        border: Border(
          bottom: BorderSide(color: themeService.borderColor),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['key'];
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter['key'] as String;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? themeService.primaryColor
                      : themeService.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? themeService.primaryColor
                        : themeService.borderColor,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: themeService.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filter['label'] as String,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        letterSpacing: 0.2,
                        color: isSelected
                            ? Colors.white
                            : themeService.textPrimary,
                      ),
                    ),
                    if (filter['count'] as int > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.25)
                              : themeService.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${filter['count']}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : themeService.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestsList(HealState state, AppLocalizations l10n, ThemeService themeService) {
    // Loading state - show skeleton loaders (Instagram/WhatsApp style)
    if (state is HealLoading && state.isInitialLoad) {
      return const ServiceRequestListSkeleton();
    }

    // Error state
    if (state is HealErrorState) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Error loading requests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeService.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: TextStyle(color: themeService.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<HealBloc>().add(const LoadServiceRequestsEvent());
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeService.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Loaded state
    if (state is HealLoadedState) {
      final filteredRequests = _getFilteredRequests(state.serviceRequests);

      print('📘 [ServiceRequests] Showing ${filteredRequests.length} requests (filter: $_selectedFilter)');

      if (filteredRequests.isEmpty) {
        return _buildEmptyState(l10n, themeService);
      }

      return Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              context.read<HealBloc>().add(const RefreshHealEvent());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: themeService.primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              itemCount: filteredRequests.length,
              itemBuilder: (context, index) {
                final request = filteredRequests[index];
                return ServiceRequestCardWidget(
              request: request,
              onAccept: () => _updateRequestStatus(request, RequestStatus.confirmed),
              onReject: () => _updateRequestStatus(request, RequestStatus.cancelled),
              onComplete: () => _updateRequestStatus(request, RequestStatus.completed),
              onStart: () => _updateRequestStatus(request, RequestStatus.inProgress),
              onPause: () => _updateRequestStatus(request, RequestStatus.confirmed), // Pause = back to confirmed state
            );
          },
        ),
      ),
          
          // Subtle refresh indicator at top (Instagram/WhatsApp-style)
          if (state.isRefreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    themeService.primaryColor.withOpacity(0.8),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Default empty
    return _buildEmptyState(l10n, themeService);
  }

  Widget _buildEmptyState(AppLocalizations l10n, ThemeService themeService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: themeService.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'No service requests found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeService.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'all'
                  ? 'No service requests yet'
                  : 'No requests in this category',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: themeService.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ServiceRequest> _getFilteredRequests(List<ServiceRequest> requests) {
    // Start with all requests or filtered by status
    List<ServiceRequest> filtered;
    
    if (_selectedFilter == 'all') {
      filtered = requests;
    } else {
      RequestStatus? status;
      switch (_selectedFilter) {
        case 'pending':
          status = RequestStatus.pending;
          break;
        case 'confirmed':
          status = RequestStatus.confirmed;
          break;
        case 'in_progress':
          status = RequestStatus.inProgress;
          break;
        case 'completed':
          status = RequestStatus.completed;
          break;
      }
      filtered = requests.where((request) => request.status == status).toList();
    }
    
    // Apply search query if provided
    final query = widget.searchQuery.toLowerCase().trim();
    if (query.isNotEmpty) {
      filtered = filtered.where((request) {
        return request.customerName.toLowerCase().contains(query) ||
               request.serviceName.toLowerCase().contains(query) ||
               request.serviceCategory.toLowerCase().contains(query) ||
               request.customerPhone.contains(query);
      }).toList();
    }
    
    return filtered;
  }

  void _updateRequestStatus(ServiceRequest request, RequestStatus newStatus) {
    // Store for undo/retry functionality
    setState(() {
      _lastUpdatedRequestId = request.id;
      _lastStatus = newStatus;
    });
    
    // Subtle haptic feedback on button press (not too aggressive)
    HapticFeedback.lightImpact();
    
    // Use BLoC to update request status (optimistic update happens in BLoC)
    context.read<HealBloc>().add(UpdateRequestStatusEvent(request.id, newStatus));
  }
}


























