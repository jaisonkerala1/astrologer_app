import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/service_model.dart';
import '../widgets/category_icon_widget.dart';

/// Service Detail Screen - View service details in read-only mode
class ServiceDetailScreen extends StatelessWidget {
  final ServiceModel service;

  const ServiceDetailScreen({
    super.key,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final category = _getCategoryInfo(service.category);

    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          appBar: AppBar(
            title: const Text('Service Details'),
            backgroundColor: themeService.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: themeService.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Category icon
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(category.color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: CategoryIconWidget(
                                category: category,
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.name,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: themeService.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  category.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: themeService.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Status badge
                          _buildStatusBadge(themeService, l10n),
                        ],
                      ),
                    ],
                  ),
                ),

                // Pricing & Duration Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: themeService.cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price',
                              style: TextStyle(
                                fontSize: 12,
                                color: themeService.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${service.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: themeService.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: themeService.borderColor,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Duration',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: themeService.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                service.duration,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: themeService.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Description Section
                _buildSection(
                  title: 'Description',
                  content: service.description,
                  themeService: themeService,
                ),

                // Requirements Section
                if (service.requirements.isNotEmpty)
                  _buildSection(
                    title: 'Requirements',
                    content: service.requirements,
                    themeService: themeService,
                  ),

                // Benefits Section
                if (service.benefits.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Benefits',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: themeService.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeService.cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: service.benefits.map((benefit) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: themeService.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            benefit,
                            style: TextStyle(
                              fontSize: 13,
                              color: themeService.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required ThemeService themeService,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: themeService.textPrimary,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeService.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: themeService.textPrimary,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStatusBadge(ThemeService themeService, AppLocalizations l10n) {
    final isActive = service.isActive;
    final color = isActive ? const Color(0xFF10B981) : const Color(0xFF6B7280);

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
            isActive ? Icons.check_circle : Icons.pause_circle,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? l10n.active : l10n.inactive,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
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

  Color _getCategoryColor(String colorHex) {
    return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
  }
}

