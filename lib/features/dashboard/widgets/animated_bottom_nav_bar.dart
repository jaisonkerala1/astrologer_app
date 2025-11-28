import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Modern animated bottom navigation bar with pill-style selection
/// Inspired by iOS tab bar and modern design trends
class AnimatedBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final List<NavItem> items;
  final Color backgroundColor;
  final Color pillColor;
  final Color selectedIconColor;
  final Color unselectedIconColor;
  final double height;
  final bool showBorder;
  final Color borderColor;

  const AnimatedBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor = Colors.white,
    this.pillColor = const Color(0xFF8B5CF6), // Beautiful purple
    this.selectedIconColor = Colors.white,
    this.unselectedIconColor = const Color(0xFF9CA3AF),
    this.height = 70,
    this.showBorder = true,
    this.borderColor = const Color(0xFFE5E7EB),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: showBorder
            ? Border(
                top: BorderSide(
                  color: borderColor,
                  width: 0.5,
                ),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (index) {
              return _AnimatedNavItem(
                item: items[index],
                isSelected: selectedIndex == index,
                pillColor: pillColor,
                selectedIconColor: selectedIconColor,
                unselectedIconColor: unselectedIconColor,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap(index);
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _AnimatedNavItem extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final Color pillColor;
  final Color selectedIconColor;
  final Color unselectedIconColor;
  final VoidCallback onTap;

  const _AnimatedNavItem({
    required this.item,
    required this.isSelected,
    required this.pillColor,
    required this.selectedIconColor,
    required this.unselectedIconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? pillColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: pillColor.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            _buildIcon(),
            
            // Animated label
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: isSelected ? 1.0 : 0.0,
                child: isSelected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: selectedIconColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final iconColor = isSelected ? selectedIconColor : unselectedIconColor;
    final iconSize = isSelected ? 22.0 : 24.0;

    if (item.svgAsset != null) {
      return SvgPicture.asset(
        item.svgAsset!,
        width: iconSize,
        height: iconSize,
        color: iconColor,
      );
    } else {
      return Icon(
        item.icon,
        size: iconSize,
        color: iconColor,
      );
    }
  }
}

/// Data class for navigation items
class NavItem {
  final String label;
  final IconData? icon;
  final String? svgAsset;

  const NavItem({
    required this.label,
    this.icon,
    this.svgAsset,
  }) : assert(icon != null || svgAsset != null, 'Either icon or svgAsset must be provided');
}

