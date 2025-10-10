import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import 'outgoing_call_screen.dart';
import 'dart:math' as math;

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
          
          // Dial pad (responsive grid)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final List<(String, String)> keys = <(String, String)>[
                    ('1', ''), ('2', 'ABC'), ('3', 'DEF'),
                    ('4', 'GHI'), ('5', 'JKL'), ('6', 'MNO'),
                    ('7', 'PQRS'), ('8', 'TUV'), ('9', 'WXYZ'),
                    ('*', ''), ('0', '+'), ('#', ''),
                  ];

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1, // square cells
                    ),
                    itemCount: keys.length,
                    itemBuilder: (context, index) {
                      final (String, String) item = keys[index];
                      return _buildDialButton(item.$1, item.$2, themeService);
                    },
                  );
                },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final double diameter = math.min(constraints.maxWidth, constraints.maxHeight) * 0.82;
        final double numberFontSize = diameter * 0.42;
        final double lettersFontSize = diameter * 0.16;
        return Center(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _addNumber(number),
              borderRadius: BorderRadius.circular(diameter / 2),
              child: Container
              (
                width: diameter,
                height: diameter,
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
                        fontSize: numberFontSize,
                        fontWeight: FontWeight.w500,
                        color: themeService.textPrimary,
                      ),
                    ),
                    if (letters.isNotEmpty)
                      Text(
                        letters,
                        style: TextStyle(
                          fontSize: lettersFontSize,
                          color: themeService.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
