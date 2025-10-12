import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/simple_touch_feedback.dart';
import '../models/service_model.dart';
import '../widgets/service_card_widget.dart';
import '../widgets/add_service_dialog.dart';
import '../widgets/service_category_filter.dart';

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({super.key});

  @override
  State<ServiceManagementScreen> createState() => _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  final List<ServiceModel> _services = [];
  final List<ServiceCategory> _categories = ServiceCategory.getDefaultCategories();
  String _selectedCategory = 'all';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSampleServices();
  }

  void _loadSampleServices() {
    setState(() {
      _services.addAll([
        ServiceModel(
          id: '1',
          name: 'Ganpati Pooja',
          description: 'Complete Ganesh Pooja with all rituals and mantras',
          category: 'e_pooja',
          price: 1500.0,
          duration: '2 hours',
          requirements: 'Clean space, pooja items, fresh flowers',
          benefits: ['Removes obstacles', 'Brings prosperity', 'Success in ventures'],
          isActive: true,
          imageUrl: '',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        ServiceModel(
          id: '2',
          name: 'Reiki Level 1 Healing',
          description: 'Basic Reiki energy healing session for beginners',
          category: 'reiki_healing',
          price: 2500.0,
          duration: '1.5 hours',
          requirements: 'Comfortable clothing, open mind',
          benefits: ['Stress relief', 'Energy balancing', 'Emotional healing'],
          isActive: true,
          imageUrl: '',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now(),
        ),
        ServiceModel(
          id: '3',
          name: 'Evil Eye Protection',
          description: 'Complete protection from negative energies and evil eye',
          category: 'evil_eye_removal',
          price: 800.0,
          duration: '45 minutes',
          requirements: 'Personal items, photo if possible',
          benefits: ['Protection from negativity', 'Mental peace', 'Aura cleansing'],
          isActive: true,
          imageUrl: '',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        ServiceModel(
          id: '4',
          name: 'Home Vastu Consultation',
          description: 'Complete home analysis and Vastu remedies',
          category: 'vastu_shastra',
          price: 5000.0,
          duration: '3 hours',
          requirements: 'House plan, photos of rooms',
          benefits: ['Positive energy flow', 'Better health', 'Financial prosperity'],
          isActive: false,
          imageUrl: '',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        ServiceModel(
          id: '5',
          name: 'Ruby Gemstone Consultation',
          description: 'Personalized gemstone recommendation and charging',
          category: 'gemstone_consultation',
          price: 3000.0,
          duration: '1 hour',
          requirements: 'Birth chart, personal details',
          benefits: ['Career growth', 'Confidence boost', 'Leadership qualities'],
          isActive: true,
          imageUrl: '',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now(),
        ),
        ServiceModel(
          id: '6',
          name: 'Shri Yantra Setup',
          description: 'Sacred geometry Yantra installation and activation',
          category: 'yantra',
          price: 4000.0,
          duration: '2.5 hours',
          requirements: 'Clean space, specific direction',
          benefits: ['Manifestation power', 'Spiritual growth', 'Abundance'],
          isActive: true,
          imageUrl: '',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now(),
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
          appBar: AppBar(
            title: Text(l10n.services),
            backgroundColor: themeService.primaryColor,
            foregroundColor: themeService.textPrimary,
            elevation: 0,
            actions: [
              IconButton(
                onPressed: _showAddServiceDialog,
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
            onCategorySelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
          ),
          
          // Services List
          Expanded(
            child: _buildServicesList(l10n, themeService),
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildServicesList(AppLocalizations l10n, ThemeService themeService) {
    final filteredServices = _selectedCategory == 'all'
        ? _services
        : _services.where((service) => service.category == _selectedCategory).toList();

    if (filteredServices.isEmpty) {
      return _buildEmptyState(l10n, themeService);
    }

    return ListView.builder(
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
              onPressed: _showAddServiceDialog,
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
    );
  }

  void _showAddServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AddServiceDialog(
        categories: _categories,
        onServiceAdded: (service) {
          setState(() {
            _services.insert(0, service);
          });
        },
      ),
    );
  }

  void _editService(ServiceModel service) {
    showDialog(
      context: context,
      builder: (context) => AddServiceDialog(
        categories: _categories,
        service: service,
        onServiceAdded: (updatedService) {
          setState(() {
            final index = _services.indexWhere((s) => s.id == service.id);
            if (index != -1) {
              _services[index] = updatedService;
            }
          });
        },
      ),
    );
  }

  void _toggleServiceStatus(ServiceModel service) {
    setState(() {
      final index = _services.indexWhere((s) => s.id == service.id);
      if (index != -1) {
        _services[index] = service.copyWith(
          isActive: !service.isActive,
          updatedAt: DateTime.now(),
        );
      }
    });
  }

  void _deleteService(ServiceModel service) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteService),
        content: Text(l10n.deleteServiceConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _services.removeWhere((s) => s.id == service.id);
              });
              Navigator.pop(context);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
