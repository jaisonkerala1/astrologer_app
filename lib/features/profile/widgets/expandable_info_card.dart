import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/services/theme_service.dart';

class ExpandableInfoCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final ThemeService themeService;
  final bool initiallyExpanded;

  const ExpandableInfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    required this.themeService,
    this.initiallyExpanded = false,
  });

  @override
  State<ExpandableInfoCard> createState() => _ExpandableInfoCardState();
}

class _ExpandableInfoCardState extends State<ExpandableInfoCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: _isExpanded ? 1.0 : 0.0,
    );
    _iconRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: widget.themeService.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.themeService.borderColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleExpanded,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: widget.themeService.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.icon,
                          size: 20,
                          color: widget.themeService.primaryColor,
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Title
                      Expanded(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: widget.themeService.textPrimary,
                          ),
                        ),
                      ),

                      // Expand/Collapse Icon
                      RotationTransition(
                        turns: _iconRotation,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: widget.themeService.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Expandable Content
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    Divider(
                      color: widget.themeService.borderColor.withOpacity(0.3),
                      height: 1,
                    ),
                    const SizedBox(height: 16),
                    ...widget.children,
                  ],
                ),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }
}

