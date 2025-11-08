import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';

class CompleteConsultationBottomSheet extends StatefulWidget {
  final String clientName;
  final VoidCallback onComplete;

  const CompleteConsultationBottomSheet({
    super.key,
    required this.clientName,
    required this.onComplete,
  });

  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    required String clientName,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CompleteConsultationBottomSheet(
        clientName: clientName,
        onComplete: () {},
      ),
    );
  }

  @override
  State<CompleteConsultationBottomSheet> createState() =>
      _CompleteConsultationBottomSheetState();
}

class _CompleteConsultationBottomSheetState
    extends State<CompleteConsultationBottomSheet> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _notesController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
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
                              'Complete Consultation',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: themeService.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'with ${widget.clientName}',
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

                        // Notes Section
                        Text(
                          'Consultation Notes',
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
                              hintText: 'Key points, remedies suggested, predictions...',
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
                          'Your thoughts about this session (only you can see)',
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
                              hintText: 'Client engagement, challenges, observations...',
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
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              Navigator.pop(context, {
                                'notes': _notesController.text.trim(),
                                'review': _reviewController.text.trim(),
                                'rating': _rating,
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Complete Consultation',
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
        );
      },
    );
  }
}

