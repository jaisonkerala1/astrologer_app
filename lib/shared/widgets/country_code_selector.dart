import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import '../../shared/theme/services/theme_service.dart';

class CountryCodeSelector extends StatelessWidget {
  final Country selectedCountry;
  final Function(Country) onCountryChanged;
  final bool enabled;

  const CountryCodeSelector({
    super.key,
    required this.selectedCountry,
    required this.onCountryChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();
    
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(
          color: themeService.borderColor,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: themeService.cardColor,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? () => _showCountryPicker(context) : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Country Flag
                Text(
                  selectedCountry.flagEmoji,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                
                // Country Code
                Text(
                  '+${selectedCountry.phoneCode}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: enabled ? themeService.textPrimary : themeService.textSecondary,
                  ),
                ),
                
                const SizedBox(width: 4),
                
                // Dropdown Arrow
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: enabled 
                    ? themeService.textSecondary 
                    : themeService.textSecondary.withOpacity(0.5),
                  size: 16,
                ),
                
                // Divider
                Container(
                  height: 20,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: themeService.borderColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      showSearch: false, // Removed search functionality
      onSelect: onCountryChanged,
      countryListTheme: CountryListThemeData(
        flagSize: 20,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        textStyle: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 14,
        ),
        bottomSheetHeight: MediaQuery.of(context).size.height * 0.7,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      favorite: ['IN', 'US', 'GB', 'AU', 'CA', 'AE', 'SG', 'MY'], // Common countries for astrologers
      exclude: <String>[], // No countries excluded
    );
  }
}

// Helper widget for phone input with country selector
class PhoneInputField extends StatefulWidget {
  final String initialCountryCode;
  final String initialPhoneNumber;
  final Function(String fullPhoneNumber, String countryCode, String phoneNumber) onPhoneChanged;
  final bool enabled;
  final String? hintText;

  const PhoneInputField({
    super.key,
    this.initialCountryCode = '+91',
    this.initialPhoneNumber = '',
    required this.onPhoneChanged,
    this.enabled = true,
    this.hintText,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late Country _selectedCountry;
  late TextEditingController _phoneController;
  final themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    
    // Default to India (+91) if no initial country code provided
    if (widget.initialCountryCode == '+91' || widget.initialCountryCode.isEmpty) {
      _selectedCountry = Country(
        phoneCode: '91',
        countryCode: 'IN',
        e164Key: '91-IN-0',
        e164Sc: 0,
        geographic: true,
        level: 1,
        name: 'India',
        example: '9999999999',
        displayName: 'India',
        displayNameNoCountryCode: 'India',
      );
    } else {
      // Try to parse the provided country code
      _selectedCountry = Country.tryParse(widget.initialCountryCode) ?? 
                       Country(
                         phoneCode: '91',
                         countryCode: 'IN',
                         e164Key: '91-IN-0',
                         e164Sc: 0,
                         geographic: true,
                         level: 1,
                         name: 'India',
                         example: '9999999999',
                         displayName: 'India',
                         displayNameNoCountryCode: 'India',
                       );
    }
    
    _phoneController = TextEditingController(text: widget.initialPhoneNumber);
    
    // Initial callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePhoneNumber();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _updatePhoneNumber() {
    final fullPhoneNumber = '+${_selectedCountry.phoneCode}${_phoneController.text}';
    widget.onPhoneChanged(
      fullPhoneNumber,
      '+${_selectedCountry.phoneCode}',
      _phoneController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Country Code Selector
        CountryCodeSelector(
          selectedCountry: _selectedCountry,
          onCountryChanged: (country) {
            setState(() {
              _selectedCountry = country;
            });
            _updatePhoneNumber();
          },
          enabled: widget.enabled,
        ),
        
        const SizedBox(width: 12),
        
        // Phone Number Input
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(
                color: themeService.borderColor,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
              color: themeService.cardColor,
            ),
            child: TextFormField(
              controller: _phoneController,
              enabled: widget.enabled,
              keyboardType: TextInputType.phone,
              style: TextStyle(
                fontSize: 16,
                color: themeService.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Enter phone number',
                hintStyle: TextStyle(
                  color: themeService.textSecondary,
                  fontSize: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                _updatePhoneNumber();
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (value.length < 10) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }
}
