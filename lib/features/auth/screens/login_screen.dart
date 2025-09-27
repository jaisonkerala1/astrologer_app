import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:country_picker/country_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/country_code_selector.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'otp_verification_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String _fullPhoneNumber = '';
  String _countryCode = '+91';
  String _phoneNumber = '';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoading) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is OtpSentState) {
            setState(() {
              _isLoading = false;
            });
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: context.read<AuthBloc>(),
                  child: OtpVerificationScreen(
                    phoneNumber: _fullPhoneNumber,
                    otpId: state.otpId,
                  ),
                ),
              ),
            );
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and Title
                  Icon(
                    Icons.star,
                    size: 80,
                    color: themeService.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${l10n.welcome}\n${l10n.appTitle}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: themeService.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to manage your astrology practice',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: themeService.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Phone Number Input with Country Selector
                  PhoneInputField(
                    initialCountryCode: _countryCode,
                    initialPhoneNumber: _phoneNumber,
                    onPhoneChanged: (fullPhone, countryCode, phoneNumber) {
                      setState(() {
                        _fullPhoneNumber = fullPhone;
                        _countryCode = countryCode;
                        _phoneNumber = phoneNumber;
                      });
                    },
                    hintText: 'Enter your phone number',
                  ),
                  const SizedBox(height: 24),
                  
                  // Send OTP Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(l10n.sendOtp),
                  ),
                  const SizedBox(height: 16),
                  
                  // Signup Link
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: 'New to our platform? ',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: themeService.textSecondary,
                          ),
                          children: [
                            TextSpan(
                              text: l10n.signup,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: themeService.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Terms and Privacy
                  Text(
                    'By continuing, you agree to our Terms of Service and Privacy Policy',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: themeService.textHint,
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

  void _sendOtp() {
    if (_fullPhoneNumber.isNotEmpty && _phoneNumber.isNotEmpty) {
      context.read<AuthBloc>().add(SendOtpEvent(_fullPhoneNumber.trim()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid phone number'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
