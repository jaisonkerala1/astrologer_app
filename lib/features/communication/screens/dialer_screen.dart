import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/app_theme.dart';
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
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
              color: Colors.grey[300],
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
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
                const Text(
                  'Dialer',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_phoneNumber.isNotEmpty)
                  IconButton(
                    onPressed: _clearNumber,
                    icon: const Icon(Icons.backspace, color: Colors.grey),
                  ),
              ],
            ),
          ),
          
          // Phone number display
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _phoneNumber.isEmpty ? 'Enter phone number' : _phoneNumber,
                    style: TextStyle(
                      fontSize: 18,
                      color: _phoneNumber.isEmpty ? Colors.grey[500] : Colors.black87,
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
                        _buildDialButton('1', ''),
                        _buildDialButton('2', 'ABC'),
                        _buildDialButton('3', 'DEF'),
                      ],
                    ),
                  ),
                  // Row 2: 4, 5, 6
                  Expanded(
                    child: Row(
                      children: [
                        _buildDialButton('4', 'GHI'),
                        _buildDialButton('5', 'JKL'),
                        _buildDialButton('6', 'MNO'),
                      ],
                    ),
                  ),
                  // Row 3: 7, 8, 9
                  Expanded(
                    child: Row(
                      children: [
                        _buildDialButton('7', 'PQRS'),
                        _buildDialButton('8', 'TUV'),
                        _buildDialButton('9', 'WXYZ'),
                      ],
                    ),
                  ),
                  // Row 4: *, 0, #
                  Expanded(
                    child: Row(
                      children: [
                        _buildDialButton('*', ''),
                        _buildDialButton('0', '+'),
                        _buildDialButton('#', ''),
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
                        color: _phoneNumber.isNotEmpty ? Colors.green : Colors.grey[300],
                        shape: BoxShape.circle,
                        boxShadow: _phoneNumber.isNotEmpty
                            ? [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        Icons.call,
                        color: _phoneNumber.isNotEmpty ? Colors.white : Colors.grey[500],
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
  }

  Widget _buildDialButton(String number, String letters) {
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
                color: Colors.grey[100],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    number,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  if (letters.isNotEmpty)
                    Text(
                      letters,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
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
