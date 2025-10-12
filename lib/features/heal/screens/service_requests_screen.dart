import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../core/constants/app_constants.dart';
import '../models/service_request_model.dart';
import '../widgets/service_request_card_widget.dart';

class ServiceRequestsScreen extends StatefulWidget {
  const ServiceRequestsScreen({super.key});

  @override
  State<ServiceRequestsScreen> createState() => _ServiceRequestsScreenState();
}

class _ServiceRequestsScreenState extends State<ServiceRequestsScreen> {
  final List<ServiceRequest> _requests = [];
  String _selectedFilter = 'all';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSampleRequests();
  }

  void _loadSampleRequests() {
    setState(() {
      _requests.addAll([
        ServiceRequest(
          id: '1',
          customerName: 'Priya Sharma',
          customerPhone: '+91 98765 43210',
          serviceName: 'Ganpati Pooja',
          serviceCategory: 'E-Pooja',
          requestedDate: DateTime.now().add(const Duration(days: 2)),
          requestedTime: '10:00 AM',
          status: RequestStatus.pending,
          price: 1500.0,
          specialInstructions: 'Please perform the pooja in the morning. I have all the required items ready.',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        ServiceRequest(
          id: '2',
          customerName: 'Rajesh Kumar',
          customerPhone: '+91 87654 32109',
          serviceName: 'Reiki Level 1 Healing',
          serviceCategory: 'Reiki Healing',
          requestedDate: DateTime.now().add(const Duration(days: 1)),
          requestedTime: '3:00 PM',
          status: RequestStatus.confirmed,
          price: 2500.0,
          specialInstructions: 'First time trying Reiki. Please explain the process.',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        ServiceRequest(
          id: '3',
          customerName: 'Sneha Patel',
          customerPhone: '+91 76543 21098',
          serviceName: 'Evil Eye Protection',
          serviceCategory: 'Evil Eye Removal',
          requestedDate: DateTime.now(),
          requestedTime: '11:00 AM',
          status: RequestStatus.inProgress,
          price: 800.0,
          specialInstructions: 'Urgent - feeling very negative energy lately.',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        ServiceRequest(
          id: '4',
          customerName: 'Amit Singh',
          customerPhone: '+91 65432 10987',
          serviceName: 'Home Vastu Consultation',
          serviceCategory: 'Vastu Shastra',
          requestedDate: DateTime.now().add(const Duration(days: 3)),
          requestedTime: '2:00 PM',
          status: RequestStatus.completed,
          price: 5000.0,
          specialInstructions: 'New house, need complete Vastu analysis.',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        ServiceRequest(
          id: '5',
          customerName: 'Meera Joshi',
          customerPhone: '+91 54321 09876',
          serviceName: 'Ruby Gemstone Consultation',
          serviceCategory: 'Gemstone Consultation',
          requestedDate: DateTime.now().add(const Duration(days: 5)),
          requestedTime: '4:00 PM',
          status: RequestStatus.cancelled,
          price: 3000.0,
          specialInstructions: 'Looking for career growth gemstone.',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          body: Column(
            children: [
              // Filter Chips
              _buildFilterChips(l10n, themeService),
              
              // Requests List
              Expanded(
                child: _buildRequestsList(l10n, themeService),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChips(AppLocalizations l10n, ThemeService themeService) {
    final filters = [
      {'key': 'all', 'label': 'All', 'count': _requests.length},
      {'key': 'pending', 'label': 'Pending', 'count': _requests.where((r) => r.status == RequestStatus.pending).length},
      {'key': 'confirmed', 'label': 'Confirmed', 'count': _requests.where((r) => r.status == RequestStatus.confirmed).length},
      {'key': 'in_progress', 'label': 'In Progress', 'count': _requests.where((r) => r.status == RequestStatus.inProgress).length},
      {'key': 'completed', 'label': 'Completed', 'count': _requests.where((r) => r.status == RequestStatus.completed).length},
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

  Widget _buildRequestsList(AppLocalizations l10n, ThemeService themeService) {
    final filteredRequests = _getFilteredRequests();

    if (filteredRequests.isEmpty) {
      return _buildEmptyState(l10n, themeService);
    }

    return ListView.builder(
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
        );
      },
    );
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

  List<ServiceRequest> _getFilteredRequests() {
    if (_selectedFilter == 'all') {
      return _requests;
    }
    
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
    
    return _requests.where((request) => request.status == status).toList();
  }

  void _updateRequestStatus(ServiceRequest request, RequestStatus newStatus) {
    setState(() {
      final index = _requests.indexWhere((r) => r.id == request.id);
      if (index != -1) {
        _requests[index] = request.copyWith(status: newStatus);
      }
    });
  }
}


























