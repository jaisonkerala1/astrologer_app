import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/service_model.dart';
import '../screens/service_detail_screen.dart';
import 'category_icon_widget.dart';

/// Service card widget inspired by consultation card design
/// Clean, minimal with strong visual hierarchy
class ServiceCardWidget extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const ServiceCardWidget({
    super.key,
    required this.service,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final category = _getCategoryInfo(service.category);
    
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: themeService.cardColor,
            borderRadius: themeService.borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: themeService.borderRadius,
            child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              // Tap on card goes to detail screen (read-only)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceDetailScreen(
                    service: service,
                  ),
                ),
              );
            },
            splashColor: themeService.primaryColor.withOpacity(0.1), // Purple ripple
            highlightColor: themeService.primaryColor.withOpacity(0.05), // Purple highlight
            borderRadius: themeService.borderRadius,
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Service name + Status chip
                    Row(
                      children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                              color: themeService.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category.name,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: themeService.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(themeService, l10n),
                  ],
                ),
                    
                    const SizedBox(height: 16),
                    
                    // Info row 1: Duration + Price
                    Row(
                      children: [
                        _buildInfoItem(
                          Icons.schedule,
                          service.duration,
                          themeService,
                        ),
                        const SizedBox(width: 16),
                        _buildInfoItem(
                          Icons.currency_rupee,
                          '₹${service.price.toStringAsFixed(0)}',
                          themeService,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Info row 2: Category with icon
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 16,
                          color: themeService.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        CategoryIconWidget(
                          category: category,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: themeService.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    
                    // Description if available (compact)
                    if (service.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                          color: themeService.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                            ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.note_outlined,
                              size: 16,
                              color: themeService.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                            child: Text(
                                service.description,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: themeService.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Action buttons (consultation style)
                    _buildActionButtons(themeService, l10n),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(ThemeService themeService, AppLocalizations l10n) {
    final isActive = service.isActive;
    
    // Color scheme based on status
    final Color color;
    final IconData icon;
    final String statusText;
    
    if (isActive) {
      color = const Color(0xFF10B981); // Green for active
      icon = Icons.check_circle;
      statusText = l10n.active;
    } else {
      color = const Color(0xFFF59E0B); // Orange for pending approval
      icon = Icons.hourglass_empty;
      statusText = 'Pending Approval';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, ThemeService themeService) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: themeService.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: themeService.textSecondary,
                  ),
                ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeService themeService, AppLocalizations l10n) {
    return Row(
                  children: [
        // Edit button - Primary action (prominent)
                    Expanded(
                      child: Container(
            height: 40,
                        decoration: BoxDecoration(
                          color: themeService.primaryColor,
              borderRadius: BorderRadius.circular(100),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onEdit();
                            },
                borderRadius: BorderRadius.circular(100),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.edit, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                                  Text(
                                    l10n.edit,
                                    style: const TextStyle(
                                      color: Colors.white,
                          fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
        
                    const SizedBox(width: 8),
        
        // Pause/Activate button - Icon only
        Container(
          width: 40,
          height: 40,
                        decoration: BoxDecoration(
                          color: service.isActive
                ? const Color(0xFFF59E0B).withOpacity(0.1)
                : const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(100),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onToggleStatus();
                            },
              borderRadius: BorderRadius.circular(100),
                            child: Center(
                child: Icon(
                                    service.isActive ? Icons.pause : Icons.play_arrow,
                  size: 20,
                  color: service.isActive 
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ),
                      ),
        
                    const SizedBox(width: 8),
        
        // Delete button - Icon only
                    Container(
          width: 40,
          height: 40,
                      decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.1),
            borderRadius: BorderRadius.circular(100),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onDelete();
                          },
              borderRadius: BorderRadius.circular(100),
                          child: const Center(
                            child: Icon(
                              Icons.delete_outline,
                  size: 20,
                  color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
    );
  }

  ServiceCategory _getCategoryInfo(String categoryId) {
    final categories = ServiceCategory.getDefaultCategories();
    return categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => ServiceCategory(
        id: 'unknown',
        name: 'Unknown',
        description: 'Unknown category',
        icon: '❓',
        color: '#6B7280',
      ),
    );
  }
}
