import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/communication_item.dart';

/// Beautiful sliding pill filter chips with smooth animation
/// The pill slides horizontally behind the selected chip
class SlidingFilterChips extends StatefulWidget {
  final CommunicationFilter activeFilter;
  final Map<CommunicationFilter, int> counts;
  final ThemeService themeService;
  final Function(CommunicationFilter) onFilterTap;

  const SlidingFilterChips({
    super.key,
    required this.activeFilter,
    required this.counts,
    required this.themeService,
    required this.onFilterTap,
  });

  @override
  State<SlidingFilterChips> createState() => _SlidingFilterChipsState();
}

class _SlidingFilterChipsState extends State<SlidingFilterChips> {
  // Keys to measure chip positions
  final List<GlobalKey> _chipKeys = List.generate(4, (_) => GlobalKey());
  
  // Chip positions and widths
  final List<double> _chipPositions = [0, 0, 0, 0];
  final List<double> _chipWidths = [0, 0, 0, 0];
  
  // Track if we've measured the chips
  bool _measured = false;

  @override
  void initState() {
    super.initState();
    // Measure after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureChips());
  }

  @override
  void didUpdateWidget(SlidingFilterChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-measure if counts change (chip widths might change)
    if (oldWidget.counts != widget.counts) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureChips());
    }
  }

  void _measureChips() {
    bool allMeasured = true;
    double currentPosition = 0;
    
    for (int i = 0; i < _chipKeys.length; i++) {
      final RenderBox? renderBox = 
          _chipKeys[i].currentContext?.findRenderObject() as RenderBox?;
      
      if (renderBox != null) {
        _chipWidths[i] = renderBox.size.width;
        _chipPositions[i] = currentPosition;
        currentPosition += renderBox.size.width + 8; // 8 = gap between chips
      } else {
        allMeasured = false;
      }
    }
    
    if (allMeasured && mounted) {
      setState(() {
        _measured = true;
      });
    }
  }

  int _getFilterIndex(CommunicationFilter filter) {
    switch (filter) {
      case CommunicationFilter.all:
        return 0;
      case CommunicationFilter.calls:
        return 1;
      case CommunicationFilter.messages:
        return 2;
      case CommunicationFilter.video:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = [
      CommunicationFilter.all,
      CommunicationFilter.calls,
      CommunicationFilter.messages,
      CommunicationFilter.video,
    ];
    
    final activeIndex = _getFilterIndex(widget.activeFilter);
    
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Sliding pill background
            if (_measured)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                left: _chipPositions[activeIndex],
                top: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  width: _chipWidths[activeIndex],
                  decoration: BoxDecoration(
                    color: widget.themeService.primaryColor,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: widget.themeService.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Chip labels (transparent background)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(filters.length, (index) {
                final filter = filters[index];
                final isActive = filter == widget.activeFilter;
                final count = widget.counts[filter] ?? 0;
                
                return Padding(
                  padding: EdgeInsets.only(right: index < filters.length - 1 ? 8 : 0),
                  child: _FilterChipLabel(
                    key: _chipKeys[index],
                    filter: filter,
                    isActive: isActive,
                    count: count,
                    themeService: widget.themeService,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onFilterTap(filter);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual chip label (text only, no background - sliding pill provides that)
class _FilterChipLabel extends StatelessWidget {
  final CommunicationFilter filter;
  final bool isActive;
  final int count;
  final ThemeService themeService;
  final VoidCallback onTap;

  const _FilterChipLabel({
    super.key,
    required this.filter,
    required this.isActive,
    required this.count,
    required this.themeService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          // Inactive chips get a subtle background
          color: isActive 
              ? Colors.transparent // Pill provides background
              : themeService.cardColor,
          borderRadius: BorderRadius.circular(100),
          border: isActive
              ? null
              : Border.all(
                  color: themeService.borderColor.withOpacity(0.3),
                  width: 1,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isActive 
                    ? Colors.white 
                    : themeService.textPrimary,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0,
              ),
              child: Text(filter.label),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive 
                      ? Colors.white.withOpacity(0.25) 
                      : themeService.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: isActive 
                        ? Colors.white 
                        : themeService.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  child: Text(count.toString()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}



