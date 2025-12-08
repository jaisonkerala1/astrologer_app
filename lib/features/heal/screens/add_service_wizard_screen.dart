import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../shared/theme/services/theme_service.dart';
import '../models/service_model.dart';
import '../widgets/category_icon_widget.dart';

/// Premium Service Creation Wizard
/// Inspired by verification flows - immersive, step-by-step experience
class AddServiceWizardScreen extends StatefulWidget {
  final ServiceModel? existingService;
  final Function(ServiceModel) onServiceCreated;

  const AddServiceWizardScreen({
    super.key,
    this.existingService,
    required this.onServiceCreated,
  });

  @override
  State<AddServiceWizardScreen> createState() => _AddServiceWizardScreenState();
}

class _AddServiceWizardScreenState extends State<AddServiceWizardScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Form data
  ServiceCategory? _selectedCategory;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _selectedDurationMinutes = 60;
  final _priceController = TextEditingController();
  final _requirementsController = TextEditingController();
  List<String> _selectedBenefits = [];
  
  // Animation controllers
  late AnimationController _progressController;
  late AnimationController _cardController;
  
  final List<ServiceCategory> _categories = [
    ...ServiceCategory.getDefaultCategories(),
    ServiceCategory(
      id: 'custom',
      name: 'Custom Service',
      description: 'Create your unique offering',
      icon: '⭐',
      color: '#6B7280',
    ),
  ];

  final List<int> _durationOptions = [30, 45, 60, 90, 120, 180];
  
  final Map<String, List<String>> _categoryBenefits = {
    'e_pooja': ['Divine blessings', 'Spiritual cleansing', 'Positive energy', 'Peace of mind', 'Prosperity'],
    'reiki_healing': ['Stress relief', 'Energy balancing', 'Chakra alignment', 'Deep relaxation', 'Emotional healing'],
    'evil_eye_removal': ['Protection', 'Negative energy removal', 'Aura cleansing', 'Mental clarity', 'Good fortune'],
    'vastu_shastra': ['Harmonious living', 'Prosperity flow', 'Health improvement', 'Career growth', 'Relationship harmony'],
    'gemstone_consultation': ['Planetary remedies', 'Life enhancement', 'Fortune improvement', 'Health benefits', 'Career boost'],
    'yantra': ['Divine protection', 'Wealth attraction', 'Success enhancement', 'Spiritual growth', 'Obstacle removal'],
    'custom': ['Custom benefit 1', 'Custom benefit 2', 'Custom benefit 3'],
  };

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    if (widget.existingService != null) {
      _populateExistingData();
    }
  }

  void _populateExistingData() {
    final service = widget.existingService!;
    _selectedCategory = _categories.firstWhere(
      (c) => c.id == service.category,
      orElse: () => _categories.last,
    );
    _nameController.text = service.name;
    _descriptionController.text = service.description;
    _priceController.text = service.price.toStringAsFixed(0);
    _requirementsController.text = service.requirements;
    _selectedBenefits = List.from(service.benefits);
    
    // Parse duration
    final durationMatch = RegExp(r'(\d+)').firstMatch(service.duration);
    if (durationMatch != null) {
      _selectedDurationMinutes = int.tryParse(durationMatch.group(1)!) ?? 60;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _cardController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedCategory != null;
      case 1:
        return _nameController.text.trim().isNotEmpty &&
            _descriptionController.text.trim().isNotEmpty;
      case 2:
        return _priceController.text.isNotEmpty &&
            double.tryParse(_priceController.text) != null;
      default:
        return true;
    }
  }

  void _publishService() {
    HapticFeedback.heavyImpact();
    
    final service = ServiceModel(
      id: widget.existingService?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory!.id,
      price: double.parse(_priceController.text),
      duration: _formatDuration(_selectedDurationMinutes),
      requirements: _requirementsController.text.trim(),
      benefits: _selectedBenefits,
      isActive: true,
      imageUrl: widget.existingService?.imageUrl ?? '',
      createdAt: widget.existingService?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    widget.onServiceCreated(service);
    
    // Show success and close
    _showSuccessAnimation();
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SuccessDialog(
        serviceName: _nameController.text.trim(),
        onDone: () {
          Navigator.pop(context); // Close dialog
          Navigator.pop(context); // Close wizard
        },
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours hr';
    return '$hours hr $mins min';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // Header with back and progress
                _buildHeader(themeService),
                
                // Progress indicator
                _buildProgressIndicator(themeService),
                
                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1CategorySelection(themeService),
                      _buildStep2ServiceDetails(themeService),
                      _buildStep3PricingDuration(themeService),
                      _buildStep4Preview(themeService),
                    ],
                  ),
                ),
                
                // Bottom action button
                _buildBottomAction(themeService),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeService themeService) {
    final titles = [
      'Choose Category',
      'Service Details',
      'Set Your Terms',
      'Preview & Publish',
    ];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: _previousStep,
            icon: Icon(
              _currentStep == 0 ? Icons.close : Icons.arrow_back_ios_new,
              color: themeService.textPrimary,
              size: 22,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  titles[_currentStep],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: themeService.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Step ${_currentStep + 1} of 4',
                  style: TextStyle(
                    fontSize: 12,
                    color: themeService.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: List.generate(4, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isCompleted || isCurrent
                    ? themeService.primaryColor
                    : themeService.borderColor,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STEP 1: Category Selection
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStep1CategorySelection(ThemeService themeService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeService.primaryColor.withOpacity(0.1),
                    themeService.primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '🙏',
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'What sacred service will you offer?',
            style: TextStyle(
              fontSize: 15,
              color: themeService.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Category Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory?.id == category.id;
              final categoryColor = Color(
                int.parse(category.color.substring(1), radix: 16) + 0xFF000000,
              );
              
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCategory = category);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? categoryColor.withOpacity(0.15)
                        : themeService.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? categoryColor : themeService.borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: categoryColor.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      // Selection checkmark
                      if (isSelected)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: categoryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CategoryIconWidget(
                              category: category,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: themeService.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STEP 2: Service Details
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStep2ServiceDetails(ThemeService themeService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected category badge
          if (_selectedCategory != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: themeService.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedCategory!.icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    _selectedCategory!.name,
                    style: TextStyle(
                      color: themeService.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Service Name
          _buildInputField(
            themeService: themeService,
            label: 'Service Name',
            hint: 'e.g., Satyanarayan Katha, Distance Reiki...',
            controller: _nameController,
            maxLength: 50,
          ),
          
          const SizedBox(height: 20),
          
          // Description
          _buildInputField(
            themeService: themeService,
            label: 'Description',
            hint: 'Describe what this service includes and how it helps...',
            controller: _descriptionController,
            maxLines: 4,
            maxLength: 500,
          ),
          
          const SizedBox(height: 20),
          
          // Requirements (optional)
          _buildInputField(
            themeService: themeService,
            label: 'Requirements (Optional)',
            hint: 'What should the client prepare?',
            controller: _requirementsController,
            maxLines: 2,
            isOptional: true,
          ),
          
          const SizedBox(height: 20),
          
          // Benefits selection
          Text(
            'Key Benefits',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select benefits that apply to your service',
            style: TextStyle(
              fontSize: 12,
              color: themeService.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (_categoryBenefits[_selectedCategory?.id] ?? []).map((benefit) {
              final isSelected = _selectedBenefits.contains(benefit);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isSelected) {
                      _selectedBenefits.remove(benefit);
                    } else {
                      _selectedBenefits.add(benefit);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? themeService.primaryColor.withOpacity(0.1)
                        : themeService.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? themeService.primaryColor
                          : themeService.borderColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: themeService.primaryColor,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        benefit,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? themeService.primaryColor
                              : themeService.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STEP 3: Pricing & Duration
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStep3PricingDuration(ThemeService themeService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Duration Selection
          Text(
            'Session Duration',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _durationOptions.map((duration) {
                final isSelected = _selectedDurationMinutes == duration;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedDurationMinutes = duration);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? themeService.primaryColor
                            : themeService.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? themeService.primaryColor
                              : themeService.borderColor,
                        ),
                      ),
                      child: Text(
                        _formatDuration(duration),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : themeService.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Price Input
          Text(
            'Your Price (Dakshina)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          
          Container(
            decoration: BoxDecoration(
              color: themeService.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: themeService.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: themeService.primaryColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                  ),
                  child: Text(
                    '₹',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: themeService.primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: themeService.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        color: themeService.textHint,
                        fontWeight: FontWeight.normal,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Price breakdown
          if (_priceController.text.isNotEmpty &&
              double.tryParse(_priceController.text) != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeService.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildPriceRow(
                    themeService,
                    'Service Price',
                    '₹${_priceController.text}',
                  ),
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    themeService,
                    'Platform Fee (10%)',
                    '-₹${(double.parse(_priceController.text) * 0.1).toStringAsFixed(0)}',
                    isDeduction: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: themeService.borderColor),
                  ),
                  _buildPriceRow(
                    themeService,
                    'You Receive',
                    '₹${(double.parse(_priceController.text) * 0.9).toStringAsFixed(0)}',
                    isBold: true,
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Market insight (mock)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.insights, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Market Insight',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                      Text(
                        'Similar services: ₹500 - ₹5,000',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    ThemeService themeService,
    String label,
    String value, {
    bool isDeduction = false,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDeduction ? themeService.textSecondary : themeService.textPrimary,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: isDeduction
                ? Colors.red.shade400
                : isBold
                    ? themeService.primaryColor
                    : themeService.textPrimary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STEP 4: Preview
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStep4Preview(ThemeService themeService) {
    final categoryColor = _selectedCategory != null
        ? Color(int.parse(_selectedCategory!.color.substring(1), radix: 16) + 0xFF000000)
        : themeService.primaryColor;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Heading
          Text(
            '🎉 Almost There!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Here\'s how clients will see your service',
            style: TextStyle(
              fontSize: 14,
              color: themeService.textSecondary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Preview Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: themeService.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedCategory?.icon ?? '✨',
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedCategory?.name.toUpperCase() ?? 'SERVICE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: categoryColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Service Details
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        _nameController.text.isEmpty
                            ? 'Service Name'
                            : _nameController.text,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: themeService.textPrimary,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Meta
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '⭐ New',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.schedule, size: 14, color: themeService.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(_selectedDurationMinutes),
                            style: TextStyle(
                              fontSize: 12,
                              color: themeService.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Description
                      Text(
                        _descriptionController.text.isEmpty
                            ? 'Service description will appear here...'
                            : _descriptionController.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: themeService.textSecondary,
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      if (_selectedBenefits.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _selectedBenefits.take(3).map((benefit) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: themeService.surfaceColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '✓ $benefit',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: themeService.textSecondary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      
                      const SizedBox(height: 20),
                      
                      // CTA Button Preview
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: themeService.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Book Now - ₹${_priceController.text.isEmpty ? '0' : _priceController.text}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Edit sections hint
          Text(
            'Tap "Publish" to make this service live',
            style: TextStyle(
              fontSize: 13,
              color: themeService.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required ThemeService themeService,
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    int? maxLength,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: themeService.textPrimary,
              ),
            ),
            if (isOptional) ...[
              const SizedBox(width: 6),
              Text(
                '(Optional)',
                style: TextStyle(
                  fontSize: 12,
                  color: themeService.textHint,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          style: TextStyle(
            fontSize: 15,
            color: themeService.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: themeService.textHint,
              fontSize: 14,
            ),
            filled: true,
            fillColor: themeService.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: themeService.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: themeService.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: themeService.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
            counterStyle: TextStyle(color: themeService.textSecondary),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildBottomAction(ThemeService themeService) {
    final isLastStep = _currentStep == 3;
    final canProceed = _canProceed();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: canProceed
                ? (isLastStep ? _publishService : _nextStep)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeService.primaryColor,
              disabledBackgroundColor: themeService.borderColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLastStep) ...[
                  const Text('🙏', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                ],
                Text(
                  isLastStep ? 'Publish Service' : 'Continue',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isLastStep) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Success Dialog with Animation
// ═══════════════════════════════════════════════════════════════
class _SuccessDialog extends StatefulWidget {
  final String serviceName;
  final VoidCallback onDone;

  const _SuccessDialog({
    required this.serviceName,
    required this.onDone,
  });

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _controller.forward();
    
    // Auto close after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: themeService.cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success icon with glow
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('🪔', style: TextStyle(fontSize: 40)),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      'Service Published!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: themeService.textPrimary,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Text(
                      '"${widget.serviceName}" is now live.\nMay it bring blessings to many! 🙏',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeService.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onDone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeService.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


