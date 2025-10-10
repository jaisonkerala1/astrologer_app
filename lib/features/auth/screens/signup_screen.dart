import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/country_code_selector.dart';
import '../../../core/constants/platform_config.dart';
import '../../settings/screens/terms_privacy_screen.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'otp_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  final _awardsController = TextEditingController();
  final _certificatesController = TextEditingController();
  bool _isLoading = false;
  String _fullPhoneNumber = '';
  String _countryCode = '+91';
  String _phoneNumber = '';
  String? _phoneError;
  File? _selectedImage;
  bool _termsAccepted = false;
  bool _showTermsError = false;

  List<String> _selectedSpecializations = [];
  List<String> _selectedLanguages = [];

  final List<String> _specializations = [
    'Vedic Astrology',
    'Western Astrology',
    'Tarot Reading',
    'Numerology',
    'Palmistry',
    'Vastu Shastra',
    'Feng Shui',
    'Crystal Healing',
  ];

  final List<String> _languages = [
    'English',
    'Hindi',
    'Tamil',
    'Telugu',
    'Bengali',
    'Marathi',
    'Gujarati',
    'Kannada',
    'Malayalam',
    'Punjabi',
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _awardsController.dispose();
    _certificatesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _takePicture();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) {
            // Only listen to new state changes, not re-evaluations
            return previous.runtimeType != current.runtimeType;
          },
          listener: (context, state) async {
            if (state is OtpSentState) {
              setState(() {
                _isLoading = false;
              });
              
              // Check if signup screen is the current route to prevent duplicate navigation
              final currentRoute = ModalRoute.of(context);
              if (currentRoute?.isCurrent == true) {
                // Get device info before navigation
                final deviceInfo = await _getDeviceInfo();
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OtpVerificationScreen(
                      phoneNumber: _fullPhoneNumber,
                      otpId: state.otpId,
                      isSignup: true,
                      signupData: {
                        'name': _nameController.text,
                        'email': _emailController.text,
                        'experience': int.tryParse(_experienceController.text) ?? 0,
                        'specializations': _selectedSpecializations,
                        'languages': _selectedLanguages,
                        'bio': _bioController.text,
                        'awards': _awardsController.text,
                        'certificates': _certificatesController.text,
                        'profilePicture': _selectedImage,
                        'termsAccepted': _termsAccepted,
                        'termsAcceptedAt': DateTime.now().toIso8601String(),
                        'acceptedTermsVersion': PlatformConfig.CURRENT_TERMS_VERSION,
                        'acceptanceDeviceInfo': deviceInfo,
                      },
                    ),
                  ),
                );
              }
            } else if (state is AuthErrorState) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: themeService.errorColor,
                ),
              );
            }
          },
          child: Scaffold(
            backgroundColor: themeService.backgroundColor,
        appBar: AppBar(
          backgroundColor: themeService.cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: themeService.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Create Account',
            style: TextStyle(
              color: themeService.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Color(0xFFF8FAFC),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.star,
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Join Our Platform',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: AppTheme.textColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Start your astrology consulting journey',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Personal Information Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Information',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Name Field
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.person,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                              LengthLimitingTextInputFormatter(50),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your full name';
                              }
                              if (value.trim().length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                                return 'Name can only contain letters and spaces';
                              }
                              if (value.trim() != value) {
                                return 'Name cannot start or end with spaces';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Profile Picture Field
                          _buildProfilePictureField(themeService),
                          const SizedBox(height: 16),

                          // Email Field
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

                          // Phone Field with Country Selector - Responsive
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Phone Number',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              PhoneInputField(
                                initialCountryCode: _countryCode,
                                initialPhoneNumber: _phoneNumber,
                                onPhoneChanged: (fullPhone, countryCode, phoneNumber) {
                                  setState(() {
                                    _fullPhoneNumber = fullPhone;
                                    _countryCode = countryCode;
                                    _phoneNumber = phoneNumber;
                                    // Clear error when user types
                                    if (_phoneError != null) {
                                      _phoneError = null;
                                    }
                                  });
                                },
                                hintText: 'Enter your phone number',
                              ),
                              // Show validation error below phone field
                              if (_phoneError != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8, left: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 16,
                                        color: AppTheme.errorColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _phoneError!,
                                          style: TextStyle(
                                            color: AppTheme.errorColor,
                                            fontSize: 12,
                                            height: 1.4,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Experience Field
                          _buildTextField(
                            controller: _experienceController,
                            label: 'Years of Experience',
                            icon: Icons.timeline,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your years of experience';
                              }
                              final experience = int.tryParse(value);
                              if (experience == null || experience < 0) {
                                return 'Please enter a valid number of years';
                              }
                              if (experience > 99) {
                                return 'Experience cannot exceed 99 years';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Specializations Card
                    Container(
                      constraints: const BoxConstraints(
                        minHeight: 220, // Fixed minimum height for stability
                      ),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildMultiSelectSection(
                        title: 'Specializations',
                        subtitle: 'Select your areas of expertise',
                        options: _specializations,
                        selectedOptions: _selectedSpecializations,
                        onChanged: (selected) {
                          setState(() {
                            _selectedSpecializations = selected;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Languages Card
                    Container(
                      constraints: const BoxConstraints(
                        minHeight: 220, // Fixed minimum height for stability
                      ),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildMultiSelectSection(
                        title: 'Languages',
                        subtitle: 'Select languages you can consult in',
                        options: _languages,
                        selectedOptions: _selectedLanguages,
                        onChanged: (selected) {
                          setState(() {
                            _selectedLanguages = selected;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Bio Information Card - Google Material Design
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tell Us About Yourself',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: AppTheme.textColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Help clients understand your expertise',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Bio Field (Mandatory)
                          _buildBioTextField(
                            controller: _bioController,
                            label: 'Bio *',
                            icon: Icons.description,
                            maxLines: 3,
                            maxLength: 1000,
                            hintText: 'Describe your experience, specializations, and what makes you unique as an astrologer...',
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s,.!?\-()&:;]+'))
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Bio is required to help clients understand your expertise';
                              }
                              if (value.trim().length < 50) {
                                return 'Please write at least 50 characters to describe yourself';
                              }
                              if (value.length > 1000) {
                                return 'Bio cannot exceed 1000 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Awards Field (Optional)
                          _buildBioTextField(
                            controller: _awardsController,
                            label: 'Awards & Recognition (Optional)',
                            icon: Icons.emoji_events,
                            maxLines: 1,
                            maxLength: 500,
                            hintText: 'List any awards, recognitions, or achievements...',
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s,.\-()&]')),
                            ],
                            validator: (value) {
                              if (value != null && value.length > 500) {
                                return 'Awards description cannot exceed 500 characters';
                              }
                              if (value != null && value.isNotEmpty) {
                                if (!RegExp(r'^[a-zA-Z0-9\s,.\-()&]+$').hasMatch(value)) {
                                  return 'Awards can only contain letters, numbers, and basic punctuation';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Certificates Field (Optional)
                          _buildBioTextField(
                            controller: _certificatesController,
                            label: 'Certifications (Optional)',
                            icon: Icons.school,
                            maxLines: 1,
                            maxLength: 500,
                            hintText: 'List your certifications, degrees, or qualifications...',
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s,.\-()&]')),
                            ],
                            validator: (value) {
                              if (value != null && value.length > 500) {
                                return 'Certificates description cannot exceed 500 characters';
                              }
                              if (value != null && value.isNotEmpty) {
                                if (!RegExp(r'^[a-zA-Z0-9\s,.\-()&]+$').hasMatch(value)) {
                                  return 'Certificates can only contain letters, numbers, and basic punctuation';
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Terms & Conditions Acceptance - Google Material Design 3
                    _buildTermsAcceptanceCard(themeService),
                    const SizedBox(height: 24),

                    // Signup Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, Color(0xFF1E3A8A)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.star, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Create Account & Send OTP',
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
                    const SizedBox(height: 24),

                    // Login Link
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Login',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
        );
      },
    );
  }

  Widget _buildBioTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    int? maxLines = 1,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      maxLength: maxLength,
      style: const TextStyle(color: AppTheme.textColor, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
        labelStyle: TextStyle(
          color: Colors.grey[600], 
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        // Improved error text styling for responsive layout
        errorStyle: const TextStyle(
          color: AppTheme.errorColor,
          fontSize: 12,
          height: 1.4,
        ),
        errorMaxLines: 2,
        isDense: true,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        counterText: maxLength != null ? null : '',
      ),
    );
  }

  Widget _buildProfilePictureField(ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Picture',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showImagePicker,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedImage != null ? themeService.primaryColor : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add profile picture',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Required for signup',
                        style: TextStyle(
                          color: themeService.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: AppTheme.textColor, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        // Improved error text styling
        errorStyle: const TextStyle(
          color: AppTheme.errorColor,
          fontSize: 12,
          height: 1.4,
        ),
        errorMaxLines: 2,
        isDense: true,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildMultiSelectSection({
    required String title,
    required String subtitle,
    required List<String> options,
    required List<String> selectedOptions,
    required Function(List<String>) onChanged,
  }) {
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
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        // Add minimum height constraint to prevent card resizing
        ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 120, // Minimum height to accommodate at least 3 rows of chips
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = selectedOptions.contains(option);
              return FilterChip(
                label: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  List<String> newSelection = List.from(selectedOptions);
                  if (selected) {
                    newSelection.add(option);
                  } else {
                    newSelection.remove(option);
                  }
                  onChanged(newSelection);
                },
                backgroundColor: Colors.grey[100],
                selectedColor: AppTheme.primaryColor,
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Get device information for terms acceptance tracking
  Future<String> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return 'Android ${androidInfo.version.release} - ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return 'iOS ${iosInfo.systemVersion} - ${iosInfo.model}';
      }
      return 'Unknown Device';
    } catch (e) {
      return 'Device Info Unavailable';
    }
  }

  void _handleSignup() async {
    // Validate form first to show all field errors
    final formValid = _formKey.currentState!.validate();
    
    // Validate phone number (not in form)
    bool phoneValid = true;
    if (_fullPhoneNumber.isEmpty || _phoneNumber.isEmpty) {
      setState(() {
        _phoneError = 'Please enter a valid phone number';
      });
      phoneValid = false;
    } else if (_phoneNumber.length < 10) {
      setState(() {
        _phoneError = 'Phone number must be at least 10 digits';
      });
      phoneValid = false;
    } else if (_phoneNumber.length > 15) {
      setState(() {
        _phoneError = 'Phone number cannot exceed 15 digits';
      });
      phoneValid = false;
    } else {
      setState(() {
        _phoneError = null;
      });
    }
    
    // If form or phone validation failed, stop here
    if (!formValid || !phoneValid) {
      return;
    }
    
    // All validations passed, continue with other checks
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile picture is required for signup'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    if (_selectedSpecializations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one specialization'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    if (_selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one language'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    if (_bioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please write a bio to help clients understand your expertise'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    if (_bioController.text.trim().length < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please write at least 50 characters in your bio'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    
    // Check terms acceptance
    if (!_termsAccepted) {
      setState(() {
        _showTermsError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You must accept the Terms of Service to continue'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    
    // Get device info for tracking
    final deviceInfo = await _getDeviceInfo();

    // Send OTP for signup with terms acceptance data
    context.read<AuthBloc>().add(SendOtpEvent(_fullPhoneNumber.trim()));
    
    // Store terms acceptance info in signup data for later
    // This will be sent to backend after OTP verification
  }

  // Google Material Design 3 - Beautiful Terms Acceptance Card
  Widget _buildTermsAcceptanceCard(ThemeService themeService) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _showTermsError
                ? Colors.red.shade50
                : AppTheme.primaryColor.withOpacity(0.05),
            _showTermsError
                ? Colors.red.shade50.withOpacity(0.3)
                : AppTheme.primaryColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _showTermsError
              ? Colors.red.shade400
              : _termsAccepted
                  ? AppTheme.primaryColor.withOpacity(0.5)
                  : Colors.grey[300]!,
          width: _showTermsError || _termsAccepted ? 2 : 1,
        ),
        boxShadow: [
          if (_showTermsError)
            BoxShadow(
              color: Colors.red.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          else if (_termsAccepted)
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _showTermsError
                          ? Colors.red.withOpacity(0.1)
                          : _termsAccepted
                              ? Colors.green.withOpacity(0.1)
                              : AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _showTermsError
                          ? Icons.error_outline
                          : _termsAccepted
                              ? Icons.check_circle_outline
                              : Icons.policy_outlined,
                      color: _showTermsError
                          ? Colors.red.shade700
                          : _termsAccepted
                              ? Colors.green.shade700
                              : AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Legal Agreement',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: _showTermsError
                                ? Colors.red.shade900
                                : AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Please review and accept our terms',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Divider
              Divider(
                color: Colors.grey[300],
                thickness: 1,
              ),
              const SizedBox(height: 16),

              // Terms checkbox with formatted text
              InkWell(
                onTap: () {
                  setState(() {
                    _termsAccepted = !_termsAccepted;
                    if (_termsAccepted) {
                      _showTermsError = false;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Custom animated checkbox
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _termsAccepted
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          border: Border.all(
                            color: _termsAccepted
                                ? AppTheme.primaryColor
                                : _showTermsError
                                    ? Colors.red.shade400
                                    : Colors.grey[400]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: _termsAccepted
                            ? const Icon(
                                Icons.check,
                                size: 18,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      
                      // Terms text with clickable links
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: AppTheme.textColor,
                            ),
                            children: [
                              const TextSpan(
                                text: 'I acknowledge that I am an ',
                              ),
                              TextSpan(
                                text: 'independent contractor',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const TextSpan(
                                text: ', accept ',
                              ),
                              TextSpan(
                                text: 'full professional liability',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const TextSpan(
                                text: ', and agree to the ',
                              ),
                              TextSpan(
                                text: 'Terms of Service',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppTheme.primaryColor,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    _showTermsDialog(showTerms: true);
                                  },
                              ),
                              const TextSpan(
                                text: ' and ',
                              ),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppTheme.primaryColor,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    _showTermsDialog(showTerms: false);
                                  },
                              ),
                              const TextSpan(
                                text: '.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Error message
              if (_showTermsError)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error,
                        size: 16,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You must accept the terms to continue',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Info badge
              if (!_showTermsError)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tap on highlighted text to view full details',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
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
  }

  // Show Terms/Privacy Dialog - Material Design 3
  void _showTermsDialog({required bool showTerms}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TermsPrivacyScreen(),
      ),
    );
  }
}
