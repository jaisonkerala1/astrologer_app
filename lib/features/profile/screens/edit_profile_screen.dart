import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/models/astrologer_model.dart';
import '../../../shared/widgets/animated_button.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/edit_profile_screen_skeleton.dart';

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
  final _bioController = TextEditingController();
  final _awardsController = TextEditingController();
  final _certificatesController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedImage;
  List<String> _selectedSpecializations = [];
  List<String> _selectedLanguages = [];

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
      _bioController.text = widget.currentUser!.bio;
      _awardsController.text = widget.currentUser!.awards;
      _certificatesController.text = widget.currentUser!.certificates;
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
    _bioController.dispose();
    _awardsController.dispose();
    _certificatesController.dispose();
    super.dispose();
  }

  ImageProvider? _getImageProvider(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://') || imagePath.startsWith('/uploads/')) {
      // Network URL - construct full URL for Railway backend
      if (imagePath.startsWith('/uploads/')) {
        return NetworkImage('https://astrologerapp-production.up.railway.app$imagePath');
      }
      return NetworkImage(imagePath);
    } else {
      // Local file path
      return FileImage(File(imagePath));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoadedState) {
          // Profile updated successfully
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: AppTheme.successColor,
              duration: Duration(seconds: 2),
            ),
          );
          widget.onProfileUpdated();
          Navigator.pop(context);
        } else if (state is ProfileErrorState) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      builder: (context, state) {
        // Show skeleton loader on initial loading
        if (state is ProfileLoading && widget.currentUser == null) {
          return const EditProfileScreenSkeleton();
        }

        // Determine if we're currently updating
        final isUpdating = state is ProfileUpdating;
        
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: Row(
              children: [
                const Text('Edit Profile'),
                if (isUpdating) ...[
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
                ],
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: AppTheme.textColor,
            actions: [
              TextButton(
                onPressed: isUpdating ? null : _saveProfile,
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: isUpdating ? Colors.grey : AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<ProfileBloc>().add(LoadProfileEvent(forceRefresh: true));
              await Future.delayed(const Duration(seconds: 1));
            },
            color: AppTheme.primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
              
              // Bio Information
              _buildSectionTitle('Bio Information'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _bioController,
                label: 'Bio',
                icon: Icons.person_outline,
                maxLines: 4,
                maxLength: 1000,
                hintText: 'Tell us about yourself, your experience, and what makes you unique...',
                validator: (value) {
                  if (value != null && value.length > 1000) {
                    return 'Bio cannot exceed 1000 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _awardsController,
                label: 'Awards & Recognition',
                icon: Icons.emoji_events,
                maxLength: 500,
                hintText: 'List your awards, recognitions, or achievements...',
                validator: (value) {
                  if (value != null && value.length > 500) {
                    return 'Awards description cannot exceed 500 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _certificatesController,
                label: 'Certifications',
                icon: Icons.school,
                maxLength: 500,
                hintText: 'List your certifications, degrees, or qualifications...',
                validator: (value) {
                  if (value != null && value.length > 500) {
                    return 'Certificates description cannot exceed 500 characters';
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
                  // Local UI state only - no setState needed
                  _selectedSpecializations = selected;
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
                  // Local UI state only - no setState needed
                  _selectedLanguages = selected;
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
                isLoading: isUpdating,
                onPressed: isUpdating ? null : _saveProfile,
              ),
              const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfilePhotoSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  backgroundImage: _selectedImage?.path != null
                      ? FileImage(File(_selectedImage!.path))
                      : (widget.currentUser?.profilePicture != null && widget.currentUser!.profilePicture!.isNotEmpty
                          ? _getImageProvider(widget.currentUser!.profilePicture!)
                          : null),
                  child: _selectedImage?.path == null && (widget.currentUser?.profilePicture == null || widget.currentUser!.profilePicture!.isEmpty)
                      ? Icon(
                          Icons.person,
                          size: 60,
                          color: AppTheme.primaryColor,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
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
    int? maxLines = 1,
    int? maxLength,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      validator: validator,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
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
        counterText: maxLength != null ? null : '',
      ),
    );
  }

  Widget _buildMultiSelectChip(
    String title,
    List<String> options,
    List<String> selectedOptions,
    Function(List<String>) onSelectionChanged,
  ) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
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
                    setLocalState(() {
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
      },
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
        // Update local state for UI preview
        _selectedImage = File(image.path);
        // Force rebuild to show the new image
        // ignore: invalid_use_of_protected_member
        (context as Element).markNeedsBuild();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate specializations
    if (_selectedSpecializations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one specialization'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Validate languages
    if (_selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one language'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    print('📝 [EditProfileScreen] Saving profile changes...');

    // Upload image first if selected
    if (_selectedImage != null) {
      print('📸 [EditProfileScreen] Uploading profile image...');
      context.read<ProfileBloc>().add(
        UploadProfileImageEvent(_selectedImage!.path),
      );
      // Wait a moment for the image upload to complete
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Prepare update data
    final updateData = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'specializations': _selectedSpecializations,
      'languages': _selectedLanguages,
      'experience': int.parse(_experienceController.text.trim()),
      'ratePerMinute': double.parse(_rateController.text.trim()),
      'bio': _bioController.text.trim(),
      'awards': _awardsController.text.trim(),
      'certificates': _certificatesController.text.trim(),
    };

    print('📝 [EditProfileScreen] Dispatching UpdateProfileEvent with data: ${updateData.keys}');

    // Dispatch update event to ProfileBloc
    context.read<ProfileBloc>().add(
      UpdateProfileEvent(profileData: updateData),
    );
  }
}
