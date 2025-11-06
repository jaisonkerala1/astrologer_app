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
        final Size screenSize = MediaQuery.of(context).size;
        return Container(
          height: screenSize.height * 0.95,
          decoration: BoxDecoration(
            color: themeService.cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
      child: SafeArea(
        top: false,
        child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: themeService.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

                  const double spacing = 6;
                  const int columns = 3;
                  const int rows = 4;
                  final double cellWidth = (constraints.maxWidth - (columns - 1) * spacing) / columns;
                  final double cellHeight = (constraints.maxHeight - (rows - 1) * spacing) / rows;
                  final double aspect = (cellWidth / cellHeight).clamp(1.05, 1.4);

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: aspect,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _phoneNumber.isNotEmpty ? _makeCall : null,
                    child: Container(
                      height: 48,
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
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
        );
      },
    );
  }

  Widget _buildDialButton(String number, String letters, ThemeService themeService) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double diameter = math.min(constraints.maxWidth, constraints.maxHeight) * 0.74;
        final double numberFontSize = diameter * 0.40;
        final double lettersFontSize = diameter * 0.14;
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
    HapticFeedback.selectionClick();
  }

  void _clearNumber() {
    setState(() {
      if (_phoneNumber.isNotEmpty) {
        _phoneNumber = _phoneNumber.substring(0, _phoneNumber.length - 1);
      }
    });
    HapticFeedback.selectionClick();
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
