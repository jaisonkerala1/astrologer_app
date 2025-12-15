import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/country_code_selector.dart';
import '../models/service_request_model.dart';
import '../models/service_model.dart';

class AddServiceRequestForm extends StatefulWidget {
  final Function(ServiceRequest) onSubmit;
  final VoidCallback onCancel;
  final List<ServiceModel>? availableServices;

  const AddServiceRequestForm({
    super.key,
    required this.onSubmit,
    required this.onCancel,
    this.availableServices,
  });

  @override
  State<AddServiceRequestForm> createState() => _AddServiceRequestFormState();
}

class _AddServiceRequestFormState extends State<AddServiceRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _serviceNameController = TextEditingController();
  final _priceController = TextEditingController(text: '1000');
  final _instructionsController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  Country _selectedCountry = Country.parse('IN');
  String _selectedCategory = 'E-Pooja';
  ServiceModel? _selectedService;

  final List<String> _categories = [
    'E-Pooja',
    'Reiki Healing',
    'Evil Eye Removal',
    'Vastu Shastra',
    'Gemstone Consultation',
    'Yantra',
    'Astrology',
    'Numerology',
    'Tarot Reading',
    'Other',
  ];

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _serviceNameController.dispose();
    _priceController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: themeService.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: themeService.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.add_circle_outline,
                          color: themeService.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Add Service Request',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: themeService.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: widget.onCancel,
                        icon: const Icon(Icons.close),
                        color: themeService.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Customer Name
                  _buildTextField(
                    controller: _customerNameController,
                    label: 'Customer Name',
                    hint: 'Enter customer name',
                    prefixIcon: Icons.person_outline,
                    themeService: themeService,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Customer name is required';
                      }
                      if (value.trim().length > 100) {
                        return 'Name must be less than 100 characters';
                      }
                      return null;
                    },
                  ),

                  // Customer Phone
                  _buildPhoneField(themeService),

                  // Service Selection (if services available)
                  if (widget.availableServices != null && widget.availableServices!.isNotEmpty) ...[
                    _buildServiceSelector(themeService),
                  ] else ...[
                    // Manual service entry
                    _buildTextField(
                      controller: _serviceNameController,
                      label: 'Service Name',
                      hint: 'e.g., Ganesh Pooja',
                      prefixIcon: Icons.spa_outlined,
                      themeService: themeService,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Service name is required';
                        }
                        return null;
                      },
                    ),
                  ],

                  // Category Selector
                  _buildCategorySelector(themeService),

                  // Date and Time
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTimeField(
                          label: 'Date',
                          value: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          icon: Icons.calendar_today,
                          onTap: _selectDate,
                          themeService: themeService,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateTimeField(
                          label: 'Time',
                          value: _selectedTime.format(context),
                          icon: Icons.access_time,
                          onTap: _selectTime,
                          themeService: themeService,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Price
                  _buildTextField(
                    controller: _priceController,
                    label: 'Price (₹)',
                    hint: 'Enter amount',
                    prefixIcon: Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                    themeService: themeService,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Price is required';
                      }
                      final price = double.tryParse(value.trim());
                      if (price == null || price <= 0) {
                        return 'Enter a valid price';
                      }
                      return null;
                    },
                  ),

                  // Special Instructions
                  _buildTextField(
                    controller: _instructionsController,
                    label: 'Special Instructions (Optional)',
                    hint: 'Any specific requirements...',
                    prefixIcon: Icons.note_alt_outlined,
                    maxLines: 3,
                    themeService: themeService,
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeService.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Create Service Request',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required ThemeService themeService,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: themeService.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            style: TextStyle(color: themeService.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: themeService.textSecondary.withOpacity(0.5)),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: themeService.textSecondary, size: 20)
                  : null,
              filled: true,
              fillColor: themeService.backgroundColor,
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
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: themeService.errorColor),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField(ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phone Number',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: themeService.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CountryCodeSelector(
                selectedCountry: _selectedCountry,
                onCountryChanged: (country) {
                  setState(() {
                    _selectedCountry = country;
                  });
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _customerPhoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                  style: TextStyle(color: themeService.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Phone number',
                    hintStyle: TextStyle(color: themeService.textSecondary.withOpacity(0.5)),
                    filled: true,
                    fillColor: themeService.backgroundColor,
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Phone is required';
                    }
                    if (value.trim().length < 10) {
                      return 'Invalid phone number';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Category',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: themeService.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: themeService.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: themeService.borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                dropdownColor: themeService.cardColor,
                style: TextStyle(color: themeService.textPrimary),
                icon: Icon(Icons.keyboard_arrow_down, color: themeService.textSecondary),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSelector(ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Service',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: themeService.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: themeService.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: themeService.borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ServiceModel>(
                value: _selectedService,
                isExpanded: true,
                hint: Text(
                  'Choose a service...',
                  style: TextStyle(color: themeService.textSecondary.withOpacity(0.5)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                dropdownColor: themeService.cardColor,
                style: TextStyle(color: themeService.textPrimary),
                icon: Icon(Icons.keyboard_arrow_down, color: themeService.textSecondary),
                items: widget.availableServices!.map((service) {
                  return DropdownMenuItem(
                    value: service,
                    child: Text('${service.name} - ₹${service.price.toStringAsFixed(0)}'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedService = value;
                      _serviceNameController.text = value.name;
                      _priceController.text = value.price.toStringAsFixed(0);
                      _selectedCategory = _getCategoryDisplay(value.category);
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required ThemeService themeService,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: themeService.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: themeService.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: themeService.borderColor),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: themeService.textSecondary),
                const SizedBox(width: 12),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: themeService.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getCategoryDisplay(String category) {
    final map = {
      'e_pooja': 'E-Pooja',
      'reiki_healing': 'Reiki Healing',
      'evil_eye_removal': 'Evil Eye Removal',
      'vastu_shastra': 'Vastu Shastra',
      'gemstone_consultation': 'Gemstone Consultation',
      'yantra': 'Yantra',
      'astrology': 'Astrology',
      'numerology': 'Numerology',
      'tarot': 'Tarot Reading',
      'other': 'Other',
    };
    return map[category] ?? category;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Combine date and time
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Format phone with country code
      final phoneNumber = '+${_selectedCountry.phoneCode} ${_customerPhoneController.text.trim()}';
      
      // Get service name
      final serviceName = _selectedService?.name ?? _serviceNameController.text.trim();

      final request = ServiceRequest(
        id: '', // Will be assigned by backend/repository
        customerName: _customerNameController.text.trim(),
        customerPhone: phoneNumber,
        serviceName: serviceName,
        serviceCategory: _selectedCategory,
        requestedDate: scheduledDateTime,
        requestedTime: _selectedTime.format(context),
        status: RequestStatus.pending,
        price: double.parse(_priceController.text.trim()),
        specialInstructions: _instructionsController.text.trim(),
        createdAt: DateTime.now(),
      );

      widget.onSubmit(request);
    }
  }
}

