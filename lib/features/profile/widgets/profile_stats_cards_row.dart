import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/services/theme_service.dart';

class ProfileStatsCardsRow extends StatelessWidget {
  final String earningsValue;
  final String earningsLabel;
  final String ratingValue;
  final String ratingLabel;
  final String clientsValue;
  final String clientsLabel;
  final ThemeService themeService;
  final VoidCallback? onEarningsTap;
  final VoidCallback? onRatingTap;
  final VoidCallback? onClientsTap;
  final bool highlightFirst;

  const ProfileStatsCardsRow({
    super.key,
    required this.earningsValue,
    required this.earningsLabel,
    required this.ratingValue,
    required this.ratingLabel,
    required this.clientsValue,
    required this.clientsLabel,
    required this.themeService,
    this.onEarningsTap,
    this.onRatingTap,
    this.onClientsTap,
    this.highlightFirst = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStatCard(
            value: earningsValue,
            label: earningsLabel,
            isHighlighted: highlightFirst,
            onTap: onEarningsTap,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            value: ratingValue,
            label: ratingLabel,
            isHighlighted: false,
            onTap: onRatingTap,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            value: clientsValue,
            label: clientsLabel,
            isHighlighted: false,
            onTap: onClientsTap,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required bool isHighlighted,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap != null
              ? () {
                  HapticFeedback.lightImpact();
                  onTap();
                }
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 90,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isHighlighted
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF9B7FDB),
                        Color(0xFF8B6FCC),
                      ],
                    )
                  : null,
              color: isHighlighted ? null : themeService.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: isHighlighted
                  ? null
                  : Border.all(
                      color: themeService.borderColor.withOpacity(0.3),
                      width: 1,
                    ),
              boxShadow: [
                BoxShadow(
                  color: isHighlighted
                      ? const Color(0xFF9B7FDB).withOpacity(0.3)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: isHighlighted ? 12 : 8,
                  offset: Offset(0, isHighlighted ? 6 : 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isHighlighted ? Colors.white : themeService.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isHighlighted
                        ? Colors.white.withOpacity(0.9)
                        : themeService.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

