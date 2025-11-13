import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/theme/services/theme_service.dart';
import 'service_celebration_animation.dart';

class CompleteServiceBottomSheet extends StatefulWidget {
  final String customerName;
  final String serviceName;
  final double amount;

  const CompleteServiceBottomSheet({
    super.key,
    required this.customerName,
    required this.serviceName,
    required this.amount,
  });

  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    required String customerName,
    required String serviceName,
    required double amount,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // Prevent dismissing during celebration
      enableDrag: false, // Prevent dragging during celebration
      builder: (context) => CompleteServiceBottomSheet(
        customerName: customerName,
        serviceName: serviceName,
        amount: amount,
      ),
    );
  }

  @override
  State<CompleteServiceBottomSheet> createState() =>
      _CompleteServiceBottomSheetState();
}

class _CompleteServiceBottomSheetState
    extends State<CompleteServiceBottomSheet> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  int _rating = 0;
  bool _showingCelebration = false;

  @override
  void dispose() {
    _notesController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  void _handleComplete() {
    HapticFeedback.mediumImpact();
    
    // Show celebration animation
    setState(() {
      _showingCelebration = true;
    });
  }

  void _handleDone() {
    // Close bottom sheet and return data
    Navigator.pop(context, {
      'notes': _notesController.text.trim(),
      'review': _reviewController.text.trim(),
      'rating': _rating,
    });
  }

  void _handleShare() {
    HapticFeedback.lightImpact();
    
    // Share service details
    final shareText = '''
✨ Service Completed ✨

Service: ${widget.serviceName}
Customer: ${widget.customerName}
Amount: ₹${widget.amount.toStringAsFixed(0)}

#AstrologerApp #ServiceSuccess
''';
    
    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: _showingCelebration ? 0 : MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showingCelebration
                ? ServiceCelebrationAnimation(
                    key: const ValueKey('celebration'),
                    customerName: widget.customerName,
                    serviceName: widget.serviceName,
                    amount: widget.amount,
                    onDone: _handleDone,
                    onShare: _handleShare,
                  )
                : Container(
                    key: const ValueKey('form'),
                    decoration: BoxDecoration(
                      color: themeService.cardColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                // Drag Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: themeService.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complete Service',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: themeService.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.serviceName} • ${widget.customerName}',
                              style: TextStyle(
                                fontSize: 14,
                                color: themeService.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          color: themeService.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Self Rating Section
                        Text(
                          'How did it go?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: themeService.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final starIndex = index + 1;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _rating = starIndex;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  _rating >= starIndex
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 40,
                                  color: _rating >= starIndex
                                      ? const Color(0xFFFFA500)
                                      : themeService.borderColor,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),

                        // Service Notes Section
                        Text(
                          'Service Notes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: themeService.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: themeService.backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: themeService.borderColor,
                            ),
                          ),
                          child: TextField(
                            controller: _notesController,
                            maxLines: 4,
                            style: TextStyle(
                              color: themeService.textPrimary,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Services provided, recommendations, follow-ups...',
                              hintStyle: TextStyle(
                                color: themeService.textHint,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Personal Review Section
                        Text(
                          'Personal Review (Private)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: themeService.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your thoughts about this service (only you can see)',
                          style: TextStyle(
                            fontSize: 13,
                            color: themeService.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: themeService.backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: themeService.borderColor,
                            ),
                          ),
                          child: TextField(
                            controller: _reviewController,
                            maxLines: 3,
                            style: TextStyle(
                              color: themeService.textPrimary,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Customer satisfaction, challenges, observations...',
                              hintStyle: TextStyle(
                                color: themeService.textHint,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Complete Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _handleComplete,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Complete Service',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
                  ),
        );
      },
    );
  }
}

