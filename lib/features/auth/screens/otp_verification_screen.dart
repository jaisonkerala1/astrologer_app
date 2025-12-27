import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/otp_helper.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../dashboard/bloc/dashboard_bloc.dart';
import '../../profile/bloc/profile_bloc.dart';
import 'signup_screen.dart';
import 'approval_waiting_screen.dart';

/// Modern, world-class OTP verification screen
/// Following 2024-2025 UI/UX trends
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

class _OtpVerificationScreenState extends State<OtpVerificationScreen> 
    with SingleTickerProviderStateMixin, CodeAutoFill {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  int _resendTimer = 30;
  bool _canResend = false;
  String? _otpCode;
  bool _isOtpDetected = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _startListeningForOTP();
    _printAppHash(); // Print app hash for backend configuration
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }
  
  /// Print app hash signature for backend configuration
  void _printAppHash() async {
    try {
      await OTPHelper.printAppSignature();
    } catch (e) {
      print('❌ Error printing app hash: $e');
    }
  }
  
  /// Start listening for OTP SMS (works on both Android & iOS)
  void _startListeningForOTP() async {
    try {
      // Android: Uses SMS Retriever API (zero permission)
      // iOS: Uses native autofill (built-in)
      listenForCode();
      print('🔔 Started listening for OTP');
    } catch (e) {
      print('❌ Error starting OTP listener: $e');
    }
  }
  
  @override
  void codeUpdated() {
    // Called automatically when OTP is detected
    if (code != null && code!.length >= 6) {
      setState(() {
        _otpCode = code!.substring(0, 6);
        _otpController.text = _otpCode!;
        _isOtpDetected = true;
      });
      
      print('✅ OTP Auto-detected: $_otpCode');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.codeDetectedAuto),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Optional: Auto-verify after 1 second
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _otpCode != null && _otpCode!.length == 6) {
          _verifyOtp();
        }
      });
    }
  }

  @override
  void dispose() {
    SmsAutoFill().unregisterListener();
    _otpController.dispose();
    _animationController.dispose();
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
          body: BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) => previous.runtimeType != current.runtimeType,
            listener: (context, state) {
              if (state is AuthLoading) {
                setState(() => _isLoading = true);
              } else if (state is OtpSentState) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.otpSentSuccess),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              } else if (state is AuthWaitingForApproval) {
                setState(() => _isLoading = false);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ApprovalWaitingScreen(astrologer: state.astrologer),
                  ),
                  (route) => false,
                );
              } else if (state is AuthSuccessState) {
                setState(() => _isLoading = false);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardScreen()),
                  (route) => false,
                );
              } else if (state is AuthSuspendedState) {
                setState(() => _isLoading = false);
                _showSuspendedDialog(state.reason, state.suspendedAt);
              } else if (state is AuthErrorState) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: themeService.errorColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
                if (state.message.contains('Account not found') || state.message.contains('Please sign up first')) {
                  _showSignupDialog();
                }
              }
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    themeService.primaryColor.withOpacity(0.05),
                    Colors.white,
                    themeService.accentColor.withOpacity(0.03),
                  ],
                ),
              ),
              child: SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          
                          // Back Button
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.arrow_back, color: themeService.textPrimary),
                            style: IconButton.styleFrom(
                              backgroundColor: themeService.cardColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Cosmic Icon/Animation
                          _buildCosmicHeader(themeService),
                          
                          const SizedBox(height: 32),
                          
                          // Verification Text
                          _buildVerificationText(themeService),
                          
                          const SizedBox(height: 32),
                          
                          // OTP Input (Floating Card)
                          _buildOtpInput(themeService),
                          
                          const SizedBox(height: 24),
                          
                          // Verify Button
                          _buildVerifyButton(themeService),
                          
                          const SizedBox(height: 24),
                          
                          // Resend Section
                          _buildResendSection(themeService),
                          
                          const SizedBox(height: 60),
                        ],
                      ),
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

  Widget _buildCosmicHeader(ThemeService themeService) {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeService.primaryColor,
              themeService.accentColor,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: themeService.primaryColor.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(
          Icons.lock_outline,
          size: 50,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildVerificationText(ThemeService themeService) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.verificationCode,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: themeService.textPrimary,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: themeService.textSecondary,
              height: 1.5,
            ),
            children: [
              TextSpan(text: l10n.sentCodeTo),
              TextSpan(
                text: widget.phoneNumber,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: themeService.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInput(ThemeService themeService) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: AppConstants.otpLength,
          textAlign: TextAlign.center,
          autofocus: false,
          autofillHints: const [AutofillHints.oneTimeCode],
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: themeService.primaryColor,
            letterSpacing: 12,
            height: 1.3,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: InputDecoration(
            hintText: '• • • • • •',
            hintStyle: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: themeService.textHint.withOpacity(0.3),
              letterSpacing: 12,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          onChanged: (value) {
            if (value.length == AppConstants.otpLength) {
              HapticFeedback.selectionClick();
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  _verifyOtp();
                }
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildVerifyButton(ThemeService themeService) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [themeService.primaryColor, themeService.accentColor],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeService.primaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: !_isLoading ? _verifyOtp : null,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.verify,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildResendSection(ThemeService themeService) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.didntReceiveCode,
            style: TextStyle(
              fontSize: 15,
              color: themeService.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (_canResend)
            TextButton(
              onPressed: _resendOtp,
              style: TextButton.styleFrom(
                foregroundColor: themeService.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.resend,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Text(
              l10n.resendIn(_resendTimer),
              style: TextStyle(
                fontSize: 15,
                color: themeService.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  void _verifyOtp() {
    final l10n = AppLocalizations.of(context)!;
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != AppConstants.otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enterValid6DigitOtp),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (widget.isSignup && widget.signupData != null) {
      // Handle signup
      context.read<AuthBloc>().add(SignupEvent(
        phoneNumber: widget.phoneNumber,
        otp: otp,
        otpId: widget.otpId,
        name: widget.signupData!['name'],
        email: widget.signupData!['email'],
        experience: widget.signupData!['experience'],
        specializations: List<String>.from(widget.signupData!['specializations']),
        languages: List<String>.from(widget.signupData!['languages']),
        bio: widget.signupData!['bio'] ?? '',
        awards: widget.signupData!['awards'] ?? '',
        certificates: widget.signupData!['certificates'] ?? '',
        profilePicture: widget.signupData!['profilePicture'] as File,
      ));
    } else {
      // Handle login
      context.read<AuthBloc>().add(VerifyOtpEvent(
        phoneNumber: widget.phoneNumber,
        otp: otp,
        otpId: widget.otpId,
      ));
    }
  }

  void _resendOtp() {
    context.read<AuthBloc>().add(SendOtpEvent(widget.phoneNumber));
    _startResendTimer();
  }

  void _showSignupDialog() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeService.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.accountNotFound,
          style: TextStyle(
            color: themeService.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          l10n.noAccountFoundMessage,
          style: TextStyle(
            color: themeService.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: themeService.textSecondary,
            ),
            child: Text(l10n.cancel),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [themeService.primaryColor, themeService.accentColor],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: themeService.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to login screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignupScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    l10n.createAccount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuspendedDialog(String reason, DateTime? suspendedAt) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: themeService.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.block, color: Colors.red.shade600, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Account Suspended',
                style: TextStyle(
                  color: themeService.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your account has been suspended and you cannot access the app at this time.',
              style: TextStyle(
                color: themeService.textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reason:',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (suspendedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Suspended on: ${_formatDate(suspendedAt)}',
                style: TextStyle(
                  color: themeService.textHint,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Please contact support if you believe this is an error or if you have any questions.',
              style: TextStyle(
                color: themeService.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to login screen
            },
            style: TextButton.styleFrom(
              foregroundColor: themeService.textSecondary,
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
