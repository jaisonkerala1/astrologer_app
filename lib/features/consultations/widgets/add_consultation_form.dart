import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/consultation_model.dart';

class AddConsultationForm extends StatefulWidget {
  final Function(ConsultationModel) onSubmit;
  final VoidCallback onCancel;

  const AddConsultationForm({
    super.key,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<AddConsultationForm> createState() => _AddConsultationFormState();
}

class _AddConsultationFormState extends State<AddConsultationForm> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _amountController = TextEditingController(text: '500');
  final _notesController = TextEditingController();
  
  ConsultationType _selectedType = ConsultationType.phone;
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _durationController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: themeService.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  // Header
                  Row(
                    children: [
                      Text(
                        'Add Consultation',
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
            const SizedBox(height: 20),

                  // Client Name
                  _buildTextField(
                    controller: _clientNameController,
                    label: 'Client Name',
                    hint: 'Enter client name',
                    themeService: themeService,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Client name is required';
                      }
                      if (value.trim().length > 100) {
                        return 'Client name must be less than 100 characters';
                      }
                      return null;
                    },
                  ),

                  // Client Phone
                  _buildTextField(
                    controller: _clientPhoneController,
                    label: 'Client Phone',
                    hint: 'Enter phone number (e.g., +919876543210)',
                    keyboardType: TextInputType.phone,
                    themeService: themeService,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                      LengthLimitingTextInputFormatter(15),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      final trimmedValue = value.trim();
                      if (trimmedValue.length > 15) {
                        return 'Phone number must be maximum 15 characters';
                      }
                      if (trimmedValue.length < 10) {
                        return 'Phone number must be at least 10 characters';
                      }
                      // Check if it starts with + and contains only digits after that
                      if (trimmedValue.startsWith('+')) {
                        if (!RegExp(r'^\+[0-9]+$').hasMatch(trimmedValue)) {
                          return 'Invalid phone number format';
                        }
                        if (trimmedValue.length < 11) { // +1 + country code + 9 digits minimum
                          return 'Phone number too short';
                        }
                      } else {
                        // If no +, should contain only digits
                        if (!RegExp(r'^[0-9]+$').hasMatch(trimmedValue)) {
                          return 'Phone number must contain only digits or start with +';
                        }
                      }
                      return null;
                    },
                  ),

                  // Consultation Type
                  _buildSectionTitle('Consultation Type', themeService),
                  const SizedBox(height: 8),
                  _buildTypeSelector(themeService),

                  // Date and Time
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTimeField(
                          label: 'Date',
                          value: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          onTap: _selectDate,
                          validator: () => _validateDateTime(),
                          themeService: themeService,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateTimeField(
                          label: 'Time',
                          value: _selectedTime.format(context),
                          onTap: _selectTime,
                          validator: () => _validateDateTime(),
                          themeService: themeService,
                        ),
                      ),
                    ],
                  ),

                  // Duration and Amount
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _durationController,
                          label: 'Duration (minutes)',
                          hint: '15-180 minutes',
                          keyboardType: TextInputType.number,
                          themeService: themeService,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Duration is required';
                            }
                            final duration = int.tryParse(value.trim());
                            if (duration == null) {
                              return 'Duration must be a number';
                            }
                            if (duration < 15) {
                              return 'Minimum duration is 15 minutes';
                            }
                            if (duration > 180) {
                              return 'Maximum duration is 180 minutes (3 hours)';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _amountController,
                          label: 'Amount (₹)',
                          hint: 'Enter amount',
                          keyboardType: TextInputType.number,
                          themeService: themeService,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Amount is required';
                            }
                            final amount = double.tryParse(value.trim());
                            if (amount == null) {
                              return 'Amount must be a valid number';
                            }
                            if (amount <= 0) {
                              return 'Amount must be greater than 0';
                            }
                            if (amount > 100000) {
                              return 'Amount seems too high (max ₹1,00,000)';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  // Notes
                  _buildTextField(
                    controller: _notesController,
                    label: 'Notes (Optional)',
                    hint: 'Add any additional notes',
                    maxLines: 3,
                    themeService: themeService,
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: themeService.borderColor),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: themeService.textPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeService.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Add Consultation',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Add bottom padding for keyboard
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            ),
          );
        },
      );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required ThemeService themeService,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: themeService.textSecondary),
          hintStyle: TextStyle(color: themeService.textHint),
          border: OutlineInputBorder(
            borderRadius: themeService.borderRadius,
            borderSide: BorderSide(color: themeService.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: themeService.borderRadius,
            borderSide: BorderSide(color: themeService.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: themeService.borderRadius,
            borderSide: BorderSide(color: themeService.primaryColor, width: 2),
          ),
          filled: true,
          fillColor: themeService.surfaceColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeService themeService) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: themeService.textPrimary,
      ),
    );
  }

  Widget _buildTypeSelector(ThemeService themeService) {
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ConsultationType.values.length,
        itemBuilder: (context, index) {
          final type = ConsultationType.values[index];
          final isSelected = _selectedType == type;
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedType = type;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? themeService.primaryColor : themeService.cardColor,
                  borderRadius: themeService.borderRadius,
                  border: Border.all(
                    color: isSelected ? themeService.primaryColor : themeService.borderColor,
                  ),
                ),
                child: Text(
                  type.displayName,
                  style: TextStyle(
                    color: isSelected ? Colors.white : themeService.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required String value,
    required VoidCallback onTap,
    required ThemeService themeService,
    String? Function()? validator,
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
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: validator != null && validator() != null 
                    ? themeService.errorColor 
                    : themeService.borderColor
                ),
                borderRadius: themeService.borderRadius,
                color: themeService.surfaceColor,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        color: validator != null && validator() != null 
                          ? themeService.errorColor 
                          : themeService.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: validator != null && validator() != null 
                      ? themeService.errorColor 
                      : themeService.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (validator != null && validator() != null) ...[
            const SizedBox(height: 4),
            Text(
              validator()!,
              style: TextStyle(
                color: themeService.errorColor,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  String? _validateDateTime() {
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    
    final now = DateTime.now();
    if (scheduledDateTime.isBefore(now)) {
      return 'Date and time must be in the future';
    }
    return null;
  }

  void _submitForm() {
    // Validate date/time first
    final dateTimeError = _validateDateTime();
    
    if (dateTimeError != null) {
      // Show error for date/time
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dateTimeError),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validate all form fields
    if (_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final consultation = ConsultationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        clientName: _clientNameController.text.trim(),
        clientPhone: _clientPhoneController.text.trim(),
        scheduledTime: scheduledDateTime,
        duration: int.parse(_durationController.text.trim()),
        amount: double.parse(_amountController.text.trim()),
        status: ConsultationStatus.scheduled,
        type: _selectedType,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      print('Form submitted with consultation: ${consultation.clientName}');
      widget.onSubmit(consultation);
    } else {
      // Form validation failed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors before submitting'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
