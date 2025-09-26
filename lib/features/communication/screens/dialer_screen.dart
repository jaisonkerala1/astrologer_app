import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import 'outgoing_call_screen.dart';

class DialerScreen extends StatefulWidget {
  const DialerScreen({super.key});

  @override
  State<DialerScreen> createState() => _DialerScreenState();
}

class _DialerScreenState extends State<DialerScreen> {
  String _phoneNumber = '';
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: themeService.cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: themeService.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: themeService.textSecondary),
                ),
                Text(
                  'Dialer',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: themeService.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_phoneNumber.isNotEmpty)
                  IconButton(
                    onPressed: _clearNumber,
                    icon: Icon(Icons.backspace, color: themeService.textSecondary),
                  ),
              ],
            ),
          ),
          
          // Phone number display
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: themeService.surfaceColor,
              borderRadius: themeService.borderRadius,
              border: Border.all(color: themeService.borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.phone, color: themeService.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _phoneNumber.isEmpty ? 'Enter phone number' : _phoneNumber,
                    style: TextStyle(
                      fontSize: 18,
                      color: _phoneNumber.isEmpty ? themeService.textHint : themeService.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Dial pad
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  // Row 1: 1, 2, 3
                  Expanded(
                    child: Row(
                      children: [
                        _buildDialButton('1', '', themeService),
                        _buildDialButton('2', 'ABC', themeService),
                        _buildDialButton('3', 'DEF', themeService),
                      ],
                    ),
                  ),
                  // Row 2: 4, 5, 6
                  Expanded(
                    child: Row(
                      children: [
                        _buildDialButton('4', 'GHI', themeService),
                        _buildDialButton('5', 'JKL', themeService),
                        _buildDialButton('6', 'MNO', themeService),
                      ],
                    ),
                  ),
                  // Row 3: 7, 8, 9
                  Expanded(
                    child: Row(
                      children: [
                        _buildDialButton('7', 'PQRS', themeService),
                        _buildDialButton('8', 'TUV', themeService),
                        _buildDialButton('9', 'WXYZ', themeService),
                      ],
                    ),
                  ),
                  // Row 4: *, 0, #
                  Expanded(
                    child: Row(
                      children: [
                        _buildDialButton('*', '', themeService),
                        _buildDialButton('0', '+', themeService),
                        _buildDialButton('#', '', themeService),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Call button
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _phoneNumber.isNotEmpty ? _makeCall : null,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: _phoneNumber.isNotEmpty ? themeService.successColor : themeService.surfaceColor,
                        shape: BoxShape.circle,
                        boxShadow: _phoneNumber.isNotEmpty
                            ? [
                                BoxShadow(
                                  color: themeService.successColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        Icons.call,
                        color: _phoneNumber.isNotEmpty ? Colors.white : themeService.textSecondary,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildDialButton(String number, String letters, ThemeService themeService) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _addNumber(number),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: themeService.surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: themeService.borderColor),
                boxShadow: [themeService.cardShadow],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    number,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      color: themeService.textPrimary,
                    ),
                  ),
                  if (letters.isNotEmpty)
                    Text(
                      letters,
                      style: TextStyle(
                        fontSize: 12,
                        color: themeService.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _addNumber(String number) {
    setState(() {
      if (number == '0' && _phoneNumber.isEmpty) {
        _phoneNumber += '+';
      } else {
        _phoneNumber += number;
      }
    });
    HapticFeedback.lightImpact();
  }

  void _clearNumber() {
    setState(() {
      if (_phoneNumber.isNotEmpty) {
        _phoneNumber = _phoneNumber.substring(0, _phoneNumber.length - 1);
      }
    });
    HapticFeedback.lightImpact();
  }

  void _makeCall() {
    if (_phoneNumber.isNotEmpty) {
      Navigator.pop(context); // Close dialer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OutgoingCallScreen(phoneNumber: _phoneNumber),
        ),
      );
    }
  }
}
