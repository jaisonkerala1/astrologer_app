import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';

class LiveStreamSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isSearching;

  const LiveStreamSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.isSearching,
  });

  @override
  State<LiveStreamSearchBar> createState() => _LiveStreamSearchBarState();
}

class _LiveStreamSearchBarState extends State<LiveStreamSearchBar> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: themeService.surfaceColor,
            borderRadius: BorderRadius.circular(25), // Fully rounded
            border: Border.all(
              color: themeService.borderColor,
              width: 1,
            ),
          ),
          child: Row(
              children: [
                // Search icon
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Icon(
                    Icons.search,
                    size: 20,
                    color: themeService.textSecondary,
                  ),
                ),
                
                // Search field
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    onChanged: widget.onChanged,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: themeService.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search live streams...',
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: themeService.textSecondary,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                
                // Clear button (only when searching)
                if (widget.isSearching)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () {
                        widget.onClear();
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: themeService.borderColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: themeService.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        );
      },
    );
  }
}
