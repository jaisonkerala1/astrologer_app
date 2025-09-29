import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../dashboard/bloc/dashboard_bloc.dart';
import '../../profile/bloc/profile_bloc.dart';
import 'signup_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String? otpId;
  final bool isSignup;
  final Map<String, dynamic>? signupData;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.otpId,
    this.isSignup = false,
    this.signupData,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  int _resendTimer = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 30;
      _canResend = false;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendTimer--;
          if (_resendTimer <= 0) {
            _canResend = true;
          }
        });
        return _resendTimer > 0;
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          appBar: AppBar(
            title: const Text('Verify OTP'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: themeService.textPrimary,
          ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoading) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is AuthSuccessState) {
            setState(() {
              _isLoading = false;
            });
            // Navigate to dashboard - clear all previous routes
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboardScreen(),
              ),
              (route) => false,
            );
          } else if (state is AuthErrorState) {
            setState(() {
              _isLoading = false;
            });
            
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: themeService.errorColor,
                duration: const Duration(seconds: 4),
              ),
            );
            
            // If account not found, show dialog with sign up option
            if (state.message.contains('Account not found') || state.message.contains('Please sign up first')) {
              _showSignupDialog();
            }
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Top section with icon and title
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        // OTP Icon
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.message,
                            size: 60,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Title and Description
                        Text(
                          'Enter Verification Code',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'We sent a 6-digit code to',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.phoneNumber,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Middle section with OTP input
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // OTP Input - Professional Design
                        Container(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: AppConstants.otpLength,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              letterSpacing: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Enter 6-digit OTP',
                              hintText: '000000',
                              counterText: '',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                              ),
                              filled: true,
                              fillColor: Colors.grey.withOpacity(0.05),
                              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                            ),
                            onChanged: (value) {
                              if (value.length == AppConstants.otpLength) {
                                // Auto-verify when OTP is complete
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  if (mounted) {
                                    _verifyOtp();
                                  }
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the OTP';
                              }
                              if (value.length != AppConstants.otpLength) {
                                return 'Please enter a valid 6-digit OTP';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Bottom section with buttons - Always visible
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                        // Verify Button - Professional Design
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Verify OTP',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Resend OTP - Professional Design
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Didn't receive the code? ",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textColor.withOpacity(0.7),
                              ),
                            ),
                            if (_canResend)
                              TextButton(
                                onPressed: _resendOtp,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                child: const Text(
                                  'Resend',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              )
                            else
                              Text(
                                'Resend in ${_resendTimer}s',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textColor.withOpacity(0.5),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
        );
      },
    );
  }

  void _verifyOtp() {
    if (_formKey.currentState!.validate()) {
      if (widget.isSignup && widget.signupData != null) {
        // Handle signup
        context.read<AuthBloc>().add(SignupEvent(
          phoneNumber: widget.phoneNumber,
          otp: _otpController.text.trim(),
          otpId: widget.otpId,
          name: widget.signupData!['name'],
          email: widget.signupData!['email'],
          experience: widget.signupData!['experience'],
          specializations: List<String>.from(widget.signupData!['specializations']),
          languages: List<String>.from(widget.signupData!['languages']),
        ));
      } else {
        // Handle login
        context.read<AuthBloc>().add(VerifyOtpEvent(
          phoneNumber: widget.phoneNumber,
          otp: _otpController.text.trim(),
          otpId: widget.otpId,
        ));
      }
    }
  }

  void _resendOtp() {
    context.read<AuthBloc>().add(SendOtpEvent(widget.phoneNumber));
    _startResendTimer();
  }

  void _showSignupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Not Found'),
        content: const Text(
          'No account found with this phone number. Would you like to create a new account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to login screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SignupScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }
}
