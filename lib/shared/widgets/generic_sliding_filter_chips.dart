import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/services/theme_service.dart';

/// A filter item for the sliding filter chips
class FilterItem {
  final String key;
  final String label;
  final int count;
  final String? icon; // Optional emoji icon
  final Color? color; // Optional custom color for this filter

  const FilterItem({
    required this.key,
    required this.label,
    this.count = 0,
    this.icon,
    this.color,
  });
}

/// Generic sliding pill filter chips with smooth animation
/// Can be used across Heal, Consultations, Communication tabs
class GenericSlidingFilterChips extends StatefulWidget {
  final List<FilterItem> filters;
  final String selectedKey;
  final ThemeService themeService;
  final Function(String) onFilterTap;
  final double height;
  final EdgeInsets padding;
  final bool showBorder;
  final Widget? trailing; // Optional trailing widget (like Clear button)

  const GenericSlidingFilterChips({
    super.key,
    required this.filters,
    required this.selectedKey,
    required this.themeService,
    required this.onFilterTap,
    this.height = 60,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.showBorder = true,
    this.trailing,
  });

  @override
  State<GenericSlidingFilterChips> createState() => _GenericSlidingFilterChipsState();
}

class _GenericSlidingFilterChipsState extends State<GenericSlidingFilterChips> {
  final Map<String, GlobalKey> _chipKeys = {};
  final Map<String, double> _chipWidths = {};
  final Map<String, double> _chipPositions = {};
  bool _measured = false;

  @override
  void initState() {
    super.initState();
    _initializeKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureChips();
    });
  }

  @override
  void didUpdateWidget(GenericSlidingFilterChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filters.length != widget.filters.length) {
      _initializeKeys();
      _measured = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureChips();
    });
  }

  void _initializeKeys() {
    _chipKeys.clear();
    _chipWidths.clear();
    _chipPositions.clear();
    for (final filter in widget.filters) {
      _chipKeys[filter.key] = GlobalKey();
    }
  }

  void _measureChips() {
    if (!mounted) return;
    
    double currentPosition = 0;
    bool allMeasured = true;
    
    for (final filter in widget.filters) {
      final key = _chipKeys[filter.key];
      if (key == null) {
        allMeasured = false;
        continue;
      }
      
      final context = key.currentContext;
      if (context == null) {
        allMeasured = false;
        continue;
      }
      
      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) {
        allMeasured = false;
        continue;
      }
      
      _chipWidths[filter.key] = box.size.width;
      _chipPositions[filter.key] = currentPosition;
      currentPosition += box.size.width + 8; // 8 = gap
    }
    
    if (allMeasured && !_measured) {
      setState(() {
        _measured = true;
      });
    } else if (allMeasured) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final pillColor = widget.filters
        .where((f) => f.key == widget.selectedKey)
        .map((f) => f.color)
        .firstOrNull ?? widget.themeService.primaryColor;
    
    final selectedPosition = _chipPositions[widget.selectedKey] ?? 0;
    final selectedWidth = _chipWidths[widget.selectedKey] ?? 0;
    
    return Container(
      height: widget.height,
      padding: widget.padding,
      decoration: widget.showBorder
          ? BoxDecoration(
              color: widget.themeService.surfaceColor,
              border: Border(
                bottom: BorderSide(color: widget.themeService.borderColor),
              ),
            )
          : null,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Sliding pill background
                if (_measured && selectedWidth > 0)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    left: selectedPosition,
                    top: 0,
                    bottom: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      width: selectedWidth,
                      decoration: BoxDecoration(
                        color: pillColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: pillColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Chip labels row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < widget.filters.length; i++) ...[
                      _buildChipLabel(widget.filters[i]),
                      if (i < widget.filters.length - 1)
                        const SizedBox(width: 8),
                    ],
                  ],
                ),
              ],
            ),
            // Trailing widget (like Clear button)
            if (widget.trailing != null) ...[
              const SizedBox(width: 8),
              widget.trailing!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChipLabel(FilterItem filter) {
    final isActive = filter.key == widget.selectedKey;
    
    return GestureDetector(
      key: _chipKeys[filter.key],
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onFilterTap(filter.key);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.transparent : widget.themeService.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? null
              : Border.all(
                  color: widget.themeService.borderColor,
                  width: 1,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Optional icon
            if (filter.icon != null) ...[
              Text(
                filter.icon!,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
            ],
            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isActive ? Colors.white : widget.themeService.textPrimary,
                fontSize: 15,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
              child: Text(filter.label),
            ),
            // Count badge
            if (filter.count > 0) ...[
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withOpacity(0.25)
                      : (filter.color ?? widget.themeService.primaryColor).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : (filter.color ?? widget.themeService.primaryColor),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  child: Text(filter.count.toString()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
