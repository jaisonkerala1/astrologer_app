import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/simple_touch_feedback.dart';
import '../models/service_model.dart';
import '../widgets/service_card_widget.dart';
import '../widgets/add_service_dialog.dart';
import '../widgets/service_category_filter.dart';
import '../bloc/heal_bloc.dart';
import '../bloc/heal_event.dart';
import '../bloc/heal_state.dart';
import 'add_service_wizard_screen.dart';

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({super.key});

  @override
  State<ServiceManagementScreen> createState() => _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  final List<ServiceCategory> _categories = ServiceCategory.getDefaultCategories();
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    // Load services via BLoC
    context.read<HealBloc>().add(LoadServicesEvent(category: _selectedCategory));
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    // Reload services with new category
    context.read<HealBloc>().add(LoadServicesEvent(category: category));
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return BlocConsumer<HealBloc, HealState>(
          listener: (context, state) {
            // Show success messages
            if (state is HealLoadedState && state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            
            // Show errors
            if (state is HealErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            print('📘 [ServiceManagement] State: ${state.runtimeType}');
            
            return Scaffold(
              backgroundColor: themeService.backgroundColor,
              appBar: AppBar(
                title: Text(l10n.services),
                backgroundColor: themeService.primaryColor,
                foregroundColor: themeService.textPrimary,
                elevation: 0,
                actions: [
                  if (state is ServiceUpdating)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    )
                  else
                    IconButton(
                      onPressed: () => _showAddServiceDialog(context, themeService),
                      icon: const Icon(Icons.add, color: Colors.white),
                      tooltip: l10n.addService,
                    ),
                ],
              ),
              body: Column(
                children: [
                  // Category Filter
                  ServiceCategoryFilter(
                    categories: _categories,
                    selectedCategory: _selectedCategory,
                    onCategorySelected: _onCategoryChanged,
                  ),
                  
                  // Services List
                  Expanded(
                    child: _buildServicesList(state, l10n, themeService),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildServicesList(HealState state, AppLocalizations l10n, ThemeService themeService) {
    // Loading state
    if (state is HealLoading && state.isInitialLoad) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: themeService.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Loading services...',
              style: TextStyle(color: themeService.textSecondary),
            ),
          ],
        ),
      );
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
                'Error loading services',
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
                  context.read<HealBloc>().add(LoadServicesEvent(category: _selectedCategory));
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
      final services = state.services;
      
      // Apply category filter
      final filteredServices = _selectedCategory == 'all'
          ? services
          : services.where((service) => service.category == _selectedCategory).toList();

      print('📘 [ServiceManagement] Showing ${filteredServices.length} services (category: $_selectedCategory)');

      if (filteredServices.isEmpty) {
        return _buildEmptyState(l10n, themeService);
      }

      return RefreshIndicator(
        onRefresh: () async {
          context.read<HealBloc>().add(LoadServicesEvent(category: _selectedCategory));
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          itemCount: filteredServices.length,
          itemBuilder: (context, index) {
            final service = filteredServices[index];
            return ServiceCardWidget(
              service: service,
              onEdit: () => _editService(service),
              onToggleStatus: () => _toggleServiceStatus(service),
              onDelete: () => _deleteService(service),
            );
          },
        ),
      );
    }

    // Default empty
    return _buildEmptyState(l10n, themeService);
  }

  Widget _buildEmptyState(AppLocalizations l10n, ThemeService themeService) {
    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.spa_outlined,
                size: 64,
                color: themeService.textHint,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noServicesFound,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeService.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedCategory == 'all'
                    ? l10n.addYourFirstService
                    : l10n.noServicesInCategory,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: themeService.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showAddServiceDialog(context, themeService),
                icon: const Icon(Icons.add),
                label: Text(l10n.addService),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeService.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: themeService.borderRadius,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddServiceDialog(BuildContext context, ThemeService themeService) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddServiceWizardScreen(
          onServiceCreated: (service) {
            // Use BLoC to create service
            context.read<HealBloc>().add(CreateServiceEvent(service));
          },
        ),
      ),
    );
  }

  void _editService(ServiceModel service) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddServiceWizardScreen(
          existingService: service,
          onServiceCreated: (updatedService) {
            // Use BLoC to update service
            context.read<HealBloc>().add(UpdateServiceEvent(service.id, updatedService));
          },
        ),
      ),
    );
  }

  void _toggleServiceStatus(ServiceModel service) {
    // Use BLoC to toggle service status
    context.read<HealBloc>().add(ToggleServiceStatusEvent(service.id, !service.isActive));
  }

  void _deleteService(ServiceModel service) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteService),
        content: Text(l10n.deleteServiceConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              // Use BLoC to delete service
              context.read<HealBloc>().add(DeleteServiceEvent(service.id));
              Navigator.pop(dialogContext);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
