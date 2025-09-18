import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../dashboard/bloc/dashboard_bloc.dart';
import '../../profile/bloc/profile_bloc.dart';

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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Verify OTP'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textColor,
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // OTP Icon
                  const Icon(
                    Icons.message,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  
                  // Title and Description
                  Text(
                    'Enter Verification Code',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a 6-digit code to\n${widget.phoneNumber}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // OTP Input
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: AppConstants.otpLength,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      letterSpacing: 8,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Enter OTP',
                      hintText: '000000',
                      counterText: '',
                    ),
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
                  const SizedBox(height: 24),
                  
                  // Verify Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Verify OTP'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Resend OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive the code? ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (_canResend)
                        TextButton(
                          onPressed: _resendOtp,
                          child: const Text('Resend'),
                        )
                      else
                        Text(
                          'Resend in ${_resendTimer}s',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textColor.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
}
