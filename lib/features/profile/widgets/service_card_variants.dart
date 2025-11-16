import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/services/theme_service.dart';

/// Swiggy-Style Service Card
/// Inspired by Swiggy's food item cards with clean split layout

class ServiceCardV2SwiggyStyle extends StatelessWidget {
  final Map<String, dynamic> service;
  final ThemeService themeService;
  final VoidCallback onTap;
  final VoidCallback onBookNow;

  const ServiceCardV2SwiggyStyle({
    super.key,
    required this.service,
    required this.themeService,
    required this.onTap,
    required this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeService.borderColor.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top section with icon and info
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Circular icon with green border (Swiggy style)
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: themeService.primaryColor,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: themeService.primaryColor.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          service['icon'],
                          color: themeService.primaryColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name
                            Text(
                              service['name'],
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: themeService.textPrimary,
                                letterSpacing: -0.4,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            
                            // Description (Swiggy shows short descriptions)
                            Text(
                              service['description'],
                              style: TextStyle(
                                fontSize: 12,
                                color: themeService.textSecondary,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            
                            // Time badge (like Swiggy's delivery time)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: themeService.surfaceColor,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: themeService.borderColor.withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 12,
                                    color: themeService.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${service['duration']} mins',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: themeService.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Divider
                Divider(
                  color: themeService.borderColor.withOpacity(0.3),
                  height: 1,
                  thickness: 1,
                ),
                
                // Bottom action bar (Swiggy style)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price (bold like Swiggy)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${service['price']}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: themeService.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      
                      // BOOK button (Swiggy's signature green button - pill shaped)
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF1ca672),
                              Color(0xFF1fb67d),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20), // Pill shape
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1ca672).withOpacity(0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              onBookNow(); // Direct to booking screen
                            },
                            borderRadius: BorderRadius.circular(20), // Pill shape
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'BOOK',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.add_circle_outline_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
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
        ),
      ),
    );
  }
}
