import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/models/astrologer_model.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/animated_card.dart';
import '../../../shared/widgets/animated_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  final AstrologerModel? currentUser;
  final VoidCallback onProfileUpdated;

  const EditProfileScreen({
    super.key,
    required this.currentUser,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _experienceController = TextEditingController();
  final _rateController = TextEditingController();
  
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedImage;
  List<String> _selectedSpecializations = [];
  List<String> _selectedLanguages = [];
  
  bool _isLoading = false;

  final List<String> _availableSpecializations = [
    'Vedic Astrology',
    'Tarot Reading',
    'Numerology',
    'Palmistry',
    'Vastu Shastra',
    'Gemstone Consultation',
    'Horoscope Analysis',
    'Feng Shui',
  ];

  final List<String> _availableLanguages = [
    'English',
    'Hindi',
    'Tamil',
    'Telugu',
    'Kannada',
    'Bengali',
    'Gujarati',
    'Marathi',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.currentUser != null) {
      _nameController.text = widget.currentUser!.name;
      _emailController.text = widget.currentUser!.email;
      _phoneController.text = widget.currentUser!.phone;
      _experienceController.text = widget.currentUser!.experience.toString();
      _rateController.text = widget.currentUser!.ratePerMinute.toString();
      _selectedSpecializations = List.from(widget.currentUser!.specializations);
      _selectedLanguages = List.from(widget.currentUser!.languages);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textColor,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? Colors.grey : AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo Section
              _buildProfilePhotoSection(),
              const SizedBox(height: 32),
              
              // Personal Information
              _buildSectionTitle('Personal Information'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                enabled: false, // Phone number cannot be changed
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Professional Information
              _buildSectionTitle('Professional Information'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _experienceController,
                label: 'Years of Experience',
                icon: Icons.work,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your experience';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                    return 'Please enter a valid number for experience';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _rateController,
                label: 'Rate per Minute (₹)',
                icon: Icons.currency_rupee,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your rate';
                  }
                  if (double.tryParse(value) == null || double.parse(value) < 0) {
                    return 'Please enter a valid rate';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Specializations
              _buildSectionTitle('Specializations'),
              const SizedBox(height: 16),
              _buildMultiSelectChip(
                'Select your specializations',
                _availableSpecializations,
                _selectedSpecializations,
                (selected) {
                  setState(() {
                    _selectedSpecializations = selected;
                  });
                },
              ),
              const SizedBox(height: 32),
              
              // Languages
              _buildSectionTitle('Languages'),
              const SizedBox(height: 16),
              _buildMultiSelectChip(
                'Select languages you speak',
                _availableLanguages,
                _selectedLanguages,
                (selected) {
                  setState(() {
                    _selectedLanguages = selected;
                  });
                },
              ),
              const SizedBox(height: 32),
              
              // Save Button
              AnimatedButton(
                text: 'Save Changes',
                width: double.infinity,
                height: 56,
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _saveProfile,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    return Center(
      child: Column(
        children: [
          AnimatedAvatar(
            imagePath: _selectedImage?.path,
            radius: 60,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            textColor: AppTheme.primaryColor,
            showEditIcon: true,
            onTap: _pickImage,
          ),
          const SizedBox(height: 16),
          Text(
            'Tap to change photo',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: AppTheme.textColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.textColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.textColor.withOpacity(0.2)),
        ),
        filled: !enabled,
        fillColor: enabled ? null : AppTheme.textColor.withOpacity(0.05),
      ),
    );
  }

  Widget _buildMultiSelectChip(
    String title,
    List<String> options,
    List<String> selectedOptions,
    Function(List<String>) onSelectionChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: options.map((option) {
            final isSelected = selectedOptions.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedOptions.add(option);
                  } else {
                    selectedOptions.remove(option);
                  }
                  onSelectionChanged(selectedOptions);
                });
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.8),
              checkmarkColor: Colors.white,
              labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : AppTheme.textColor,
              ),
              backgroundColor: AppTheme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textColor.withOpacity(0.3),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSpecializations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one specialization'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one language'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get auth token
      final token = await _storageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Set auth token for API calls
      _apiService.setAuthToken(token);

      // Prepare update data
      final updateData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'specializations': _selectedSpecializations,
        'languages': _selectedLanguages,
        'experience': int.parse(_experienceController.text.trim()),
        'ratePerMinute': double.parse(_rateController.text.trim()),
        'profilePicture': _selectedImage?.path, // Store image path
      };

      print('Updating profile with data: $updateData');

      // Call API to update profile
      final response = await _apiService.put(ApiConstants.updateProfile, updateData);
      
      if (response.statusCode == 200) {
        // Parse the updated user data from API response
        final updatedUserData = response.data['data'];
        final updatedUser = AstrologerModel.fromJson(updatedUserData);

        // Save to local storage
        await _storageService.setUserData(jsonEncode(updatedUser.toJson()));

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Callback to refresh parent screen
        widget.onProfileUpdated();

        // Navigate back
        Navigator.pop(context);
      } else {
        throw Exception('Failed to update profile: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
