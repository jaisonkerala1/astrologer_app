import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'otp_verification_screen.dart';
import 'signup_screen.dart';

/// Modern, world-class login screen design
/// Following 2024-2025 UI/UX trends
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String _fullPhoneNumber = '';
  String _countryCode = '+91';
  String _phoneNumber = '';
  String? _errorMessage;
  Country _selectedCountry = Country.parse('IN');
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) => previous.runtimeType != current.runtimeType,
            listener: _handleAuthStateChange,
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
                          const SizedBox(height: 60),
                          
                          // Cosmic Icon/Animation
                          _buildCosmicHeader(themeService),
                          
                          const SizedBox(height: 48),
                          
                          // Welcome Text
                          _buildWelcomeText(themeService),
                          
                          const SizedBox(height: 40),
                          
                          // Phone Input (Floating Card)
                          _buildPhoneInput(themeService),
                          
                          const SizedBox(height: 24),
                          
                          // Continue Button
                          _buildContinueButton(themeService),
                          
                          const SizedBox(height: 80),
                          
                          // Sign Up Link
                          _buildSignupLink(themeService),
                          
                          const SizedBox(height: 16),
                          
                          // Trust Indicator
                          _buildTrustIndicator(themeService),
                          
                          const SizedBox(height: 24),
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
          Icons.auto_awesome,
          size: 50,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildWelcomeText(ThemeService themeService) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.welcomeBack,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: themeService.textPrimary,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.enterPhoneSubtitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: themeService.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInput(ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: _errorMessage != null
                ? Border.all(color: Colors.red.shade300, width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // Country Code Selector (Minimalist)
                GestureDetector(
                  onTap: () {
                    setState(() => _errorMessage = null);
                    _showCountryPicker();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedCountry.flagEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '+${_selectedCountry.phoneCode}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: themeService.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down,
                          color: themeService.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Divider
                Container(
                  width: 1,
                  height: 32,
                  color: themeService.borderColor.withOpacity(0.3),
                ),
                
                const SizedBox(width: 12),
                
                // Phone Number Input
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: themeService.textPrimary,
                      letterSpacing: 0.3,
                      height: 1.2,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(15),
                    ],
                    decoration: InputDecoration(
                      hintText: '00000 00000',
                      hintStyle: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: themeService.textHint.withOpacity(0.4),
                        letterSpacing: 0.3,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 0),
                      isDense: true,
                    ),
                    onChanged: (value) {
            setState(() {
                        _phoneNumber = value;
                        _fullPhoneNumber = '+${_selectedCountry.phoneCode}$value';
                        _errorMessage = null; // Clear error on typing
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Error Message
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: Colors.red.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildContinueButton(ThemeService themeService) {
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
          onTap: !_isLoading ? _sendOtp : null,
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
                        AppLocalizations.of(context)!.continueButton,
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

  Widget _buildSignupLink(ThemeService themeService) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
            MaterialPageRoute(builder: (context) => const SignupScreen()),
          );
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: RichText(
          text: TextSpan(
            text: l10n.newHere,
            style: TextStyle(
              fontSize: 15,
              color: themeService.textSecondary,
              fontWeight: FontWeight.w400,
            ),
            children: [
              TextSpan(
                text: l10n.createAccount,
                style: TextStyle(
                  fontSize: 15,
                  color: themeService.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustIndicator(ThemeService themeService) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 16,
            color: themeService.textHint,
          ),
          const SizedBox(width: 8),
          Text(
            l10n.securedByOtp,
            style: TextStyle(
              fontSize: 13,
              color: themeService.textHint,
              fontWeight: FontWeight.w500,
            ),
                    ),
                  ],
                ),
              );
            }

  void _showCountryPicker() {
    final l10n = AppLocalizations.of(context)!;
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country country) {
            setState(() {
          _selectedCountry = country;
          _countryCode = '+${country.phoneCode}';
          _fullPhoneNumber = '+${country.phoneCode}$_phoneNumber';
        });
      },
      countryListTheme: CountryListThemeData(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        inputDecoration: InputDecoration(
          labelText: l10n.search,
          hintText: l10n.startTypingToSearch,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
        ),
      ),
    );
  }

  void _sendOtp() {
    final l10n = AppLocalizations.of(context)!;
    // Validation
    if (_phoneNumber.isEmpty) {
      setState(() {
        _errorMessage = l10n.pleaseEnterPhone;
      });
      HapticFeedback.selectionClick();
      return;
    }
    
    if (_phoneNumber.length < 7) {
      setState(() {
        _errorMessage = l10n.phoneTooShort;
      });
      HapticFeedback.selectionClick();
      return;
    }
    
    if (_phoneNumber.length > 15) {
      setState(() {
        _errorMessage = l10n.phoneTooLong;
      });
      HapticFeedback.selectionClick();
      return;
    }
    
    // Clear error and proceed
    setState(() {
      _errorMessage = null;
    });
    
    HapticFeedback.selectionClick();
    context.read<AuthBloc>().add(CheckPhoneExistsEvent(_fullPhoneNumber.trim()));
  }

  void _handleAuthStateChange(BuildContext context, AuthState state) {
    if (state is AuthLoading) {
      setState(() => _isLoading = true);
    } else if (state is PhoneCheckedState) {
      setState(() => _isLoading = false);
      
      if (state.exists) {
        context.read<AuthBloc>().add(SendOtpEvent(state.phoneNumber));
      } else {
        _showAccountNotFoundDialog(state.message);
      }
    } else if (state is OtpSentState) {
      setState(() => _isLoading = false);
      
            final currentRoute = ModalRoute.of(context);
            if (currentRoute?.isCurrent == true) {
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
            }
          } else if (state is AuthSuspendedState) {
      setState(() => _isLoading = false);
      _showSuspendedDialog(state.reason, state.suspendedAt);
    } else if (state is AuthErrorState) {
      setState(() => _isLoading = false);
      _showErrorSnackbar(state.message);
    }
  }

  void _showAccountNotFoundDialog(String message) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
          l10n.noAccountMessage,
          style: TextStyle(
            color: themeService.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
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
                  Navigator.pop(dialogContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignupScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    l10n.signUp,
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

  void _showErrorSnackbar(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.red,
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
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: themeService.textSecondary,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
