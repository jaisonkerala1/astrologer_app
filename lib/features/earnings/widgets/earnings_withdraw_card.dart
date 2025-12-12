import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/app_theme.dart';

/// Bank account model for withdrawal
class BankAccountInfo {
  final String id;
  final String bankName;
  final String accountNumber;
  final String holderName;
  final String? bankLogo;
  final bool isPrimary;

  const BankAccountInfo({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.holderName,
    this.bankLogo,
    this.isPrimary = false,
  });

  /// Get masked account number (last 4 digits visible)
  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    final lastFour = accountNumber.substring(accountNumber.length - 4);
    return '●●●● ●●●● ●●●● $lastFour';
  }
}

/// Credit card style bank account display for withdrawals
class EarningsWithdrawCard extends StatefulWidget {
  final BankAccountInfo bankAccount;
  final bool isSelected;
  final VoidCallback? onTap;

  const EarningsWithdrawCard({
    super.key,
    required this.bankAccount,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<EarningsWithdrawCard> createState() => _EarningsWithdrawCardState();
}

class _EarningsWithdrawCardState extends State<EarningsWithdrawCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  // Gradient colors for card
  static const List<List<Color>> _gradientOptions = [
    [Color(0xFF667EEA), Color(0xFF764BA2)], // Purple blend
    [Color(0xFF11998E), Color(0xFF38EF7D)], // Green blend
    [Color(0xFFFC466B), Color(0xFF3F5EFB)], // Pink to blue
    [Color(0xFFF093FB), Color(0xFFF5576C)], // Pink blend
  ];

  List<Color> get _gradient {
    final index = widget.bankAccount.bankName.hashCode.abs() % _gradientOptions.length;
    return _gradientOptions[index];
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Build bank logo based on bank name
  Widget _buildBankLogo(String bankName) {
    // Bank colors and initial mapping
    final bankData = _getBankData(bankName);
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bank colored dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: bankData['color'] as Color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          // Bank initials
          Text(
            bankData['initial'] as String,
            style: TextStyle(
              color: bankData['color'] as Color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getBankData(String bankName) {
    final name = bankName.toUpperCase();
    
    // Popular Indian banks
    if (name.contains('HDFC')) {
      return {'initial': 'H', 'color': const Color(0xFF004C8F)};
    } else if (name.contains('ICICI')) {
      return {'initial': 'I', 'color': const Color(0xFFFF6F00)};
    } else if (name.contains('SBI') || name.contains('STATE BANK')) {
      return {'initial': 'S', 'color': const Color(0xFF22409A)};
    } else if (name.contains('AXIS')) {
      return {'initial': 'A', 'color': const Color(0xFF800000)};
    } else if (name.contains('KOTAK')) {
      return {'initial': 'K', 'color': const Color(0xFFED232A)};
    } else if (name.contains('PNB') || name.contains('PUNJAB')) {
      return {'initial': 'P', 'color': const Color(0xFF071E5F)};
    } else if (name.contains('BOB') || name.contains('BARODA')) {
      return {'initial': 'B', 'color': const Color(0xFFEC6A37)};
    } else if (name.contains('CANARA')) {
      return {'initial': 'C', 'color': const Color(0xFFD32F2F)};
    } else if (name.contains('UNION')) {
      return {'initial': 'U', 'color': const Color(0xFF1A237E)};
    } else if (name.contains('IDBI')) {
      return {'initial': 'ID', 'color': const Color(0xFF006633)};
    } else if (name.contains('YES')) {
      return {'initial': 'Y', 'color': const Color(0xFF003DA5)};
    } else if (name.contains('INDIAN')) {
      return {'initial': 'IN', 'color': const Color(0xFF1976D2)};
    } else {
      // Default for unknown banks
      return {'initial': bankName.substring(0, 1).toUpperCase(), 'color': AppTheme.primaryColor};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: 180,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _gradient,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _gradient[0].withOpacity(_isPressed ? 0.5 : 0.4),
                    blurRadius: _isPressed ? 25 : 15,
                    offset: Offset(0, _isPressed ? 12 : 8),
                  ),
                ],
                border: widget.isSelected
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              child: Stack(
                children: [
                  // Decorative pattern
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    left: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: Bank logo & Selection indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Bank logo
                            _buildBankLogo(widget.bankAccount.bankName),
                            
                            // Bank name & primary badge
                            Row(
                              children: [
                                if (widget.bankAccount.isPrimary)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Primary',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                if (widget.isSelected)
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check_rounded,
                                      color: _gradient[0],
                                      size: 16,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        
                        const Spacer(),
                        
                        // Card number (masked)
                        Text(
                          widget.bankAccount.maskedAccountNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Bottom row: Holder name & Bank name
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Holder name
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Account Holder',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.bankAccount.holderName.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Bank name
                            Text(
                              widget.bankAccount.bankName,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Compact bank card for list view
class EarningsWithdrawCardCompact extends StatelessWidget {
  final BankAccountInfo bankAccount;
  final bool isSelected;
  final VoidCallback? onTap;

  const EarningsWithdrawCardCompact({
    super.key,
    required this.bankAccount,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Bank logo
            _buildCompactBankLogo(bankAccount.bankName),
            const SizedBox(width: 12),
            
            // Bank details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        bankAccount.bankName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.textColor,
                        ),
                      ),
                      if (bankAccount.isPrimary) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Primary',
                            style: TextStyle(
                              color: AppTheme.successColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bankAccount.maskedAccountNumber,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            
            // Selection indicator
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build compact bank logo
  static Widget _buildCompactBankLogo(String bankName) {
    final bankData = _getCompactBankData(bankName);
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: (bankData['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (bankData['color'] as Color).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          bankData['initial'] as String,
          style: TextStyle(
            color: bankData['color'] as Color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  static Map<String, dynamic> _getCompactBankData(String bankName) {
    final name = bankName.toUpperCase();
    
    if (name.contains('HDFC')) {
      return {'initial': 'H', 'color': const Color(0xFF004C8F)};
    } else if (name.contains('ICICI')) {
      return {'initial': 'I', 'color': const Color(0xFFFF6F00)};
    } else if (name.contains('SBI') || name.contains('STATE BANK')) {
      return {'initial': 'S', 'color': const Color(0xFF22409A)};
    } else if (name.contains('AXIS')) {
      return {'initial': 'A', 'color': const Color(0xFF800000)};
    } else if (name.contains('KOTAK')) {
      return {'initial': 'K', 'color': const Color(0xFFED232A)};
    } else if (name.contains('PNB') || name.contains('PUNJAB')) {
      return {'initial': 'P', 'color': const Color(0xFF071E5F)};
    } else if (name.contains('BOB') || name.contains('BARODA')) {
      return {'initial': 'B', 'color': const Color(0xFFEC6A37)};
    } else if (name.contains('CANARA')) {
      return {'initial': 'C', 'color': const Color(0xFFD32F2F)};
    } else if (name.contains('UNION')) {
      return {'initial': 'U', 'color': const Color(0xFF1A237E)};
    } else if (name.contains('IDBI')) {
      return {'initial': 'ID', 'color': const Color(0xFF006633)};
    } else if (name.contains('YES')) {
      return {'initial': 'Y', 'color': const Color(0xFF003DA5)};
    } else if (name.contains('INDIAN')) {
      return {'initial': 'IN', 'color': const Color(0xFF1976D2)};
    } else {
      return {'initial': bankName.substring(0, 1).toUpperCase(), 'color': AppTheme.primaryColor};
    }
  }
}


