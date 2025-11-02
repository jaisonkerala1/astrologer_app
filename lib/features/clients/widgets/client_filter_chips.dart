import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';

/// Filter chips for client categorization
/// Provides smooth selection animations
enum ClientFilter {
  all,
  recent,
  frequent,
  vip,
}

class ClientFilterChips extends StatefulWidget {
  final ClientFilter selectedFilter;
  final Function(ClientFilter) onFilterChanged;

  const ClientFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  State<ClientFilterChips> createState() => _ClientFilterChipsState();
}

class _ClientFilterChipsState extends State<ClientFilterChips>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildFilterChip(
                label: 'All Clients',
                icon: Icons.people,
                filter: ClientFilter.all,
                themeService: themeService,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Recent',
                icon: Icons.access_time,
                filter: ClientFilter.recent,
                themeService: themeService,
                badge: '30d',
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Frequent',
                icon: Icons.repeat,
                filter: ClientFilter.frequent,
                themeService: themeService,
                badge: '5+',
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'VIP',
                icon: Icons.star,
                filter: ClientFilter.vip,
                themeService: themeService,
                isVIP: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required ClientFilter filter,
    required ThemeService themeService,
    String? badge,
    bool isVIP = false,
  }) {
    final isSelected = widget.selectedFilter == filter;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return AnimatedScale(
          scale: isSelected ? 1.0 : 0.95,
          duration: const Duration(milliseconds: 200),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                widget.onFilterChanged(filter);
                // Haptic feedback
                // HapticFeedback.lightImpact();
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isVIP
                          ? const Color(0xFFFFD700).withOpacity(0.15)
                          : themeService.primaryColor.withOpacity(0.15))
                      : themeService.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? (isVIP
                            ? const Color(0xFFFFD700)
                            : themeService.primaryColor)
                        : themeService.borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: (isVIP
                                    ? const Color(0xFFFFD700)
                                    : themeService.primaryColor)
                                .withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected
                          ? (isVIP
                              ? const Color(0xFFFFD700)
                              : themeService.primaryColor)
                          : themeService.textSecondary,
                    ),
                    const SizedBox(width: 6),

                    // Label
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? (isVIP
                                ? const Color(0xFFD97706)
                                : themeService.primaryColor)
                            : themeService.textSecondary,
                      ),
                    ),

                    // Badge
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isVIP
                                  ? const Color(0xFFFFD700).withOpacity(0.3)
                                  : themeService.primaryColor.withOpacity(0.2))
                              : themeService.borderColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? (isVIP
                                    ? const Color(0xFFD97706)
                                    : themeService.primaryColor)
                                : themeService.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

