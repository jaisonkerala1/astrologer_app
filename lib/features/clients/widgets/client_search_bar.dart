import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import 'dart:async';

/// Modern search bar with debounce functionality
/// Provides smooth search experience with animations
class ClientSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback? onClear;
  final String hintText;

  const ClientSearchBar({
    super.key,
    required this.onSearch,
    this.onClear,
    this.hintText = 'Search by name or phone...',
  });

  @override
  State<ClientSearchBar> createState() => _ClientSearchBarState();
}

class _ClientSearchBarState extends State<ClientSearchBar>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _isSearching = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    setState(() {
      _isSearching = query.isNotEmpty;
    });

    // Debounce: Wait 500ms after user stops typing
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onSearch(query);
    });
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _isSearching = false;
    });
    widget.onClear?.call();
    widget.onSearch('');
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _focusNode.requestFocus();
            },
            child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: themeService.cardColor,
              borderRadius: BorderRadius.circular(30), // More rounded
              border: Border.all(
                color: _focusNode.hasFocus
                    ? themeService.primaryColor.withOpacity(0.5)
                    : themeService.borderColor,
                width: _focusNode.hasFocus ? 2 : 1,
              ),
              boxShadow: _focusNode.hasFocus
                  ? [
                      BoxShadow(
                        color: themeService.primaryColor.withOpacity(0.15),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Search Icon
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 10),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _isSearching ? Icons.search : Icons.search_outlined,
                      key: ValueKey(_isSearching),
                      color: _focusNode.hasFocus
                          ? themeService.primaryColor
                          : themeService.textSecondary,
                      size: 20,
                    ),
                  ),
                ),

                // Text Field
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _onSearchChanged,
                    style: TextStyle(
                      fontSize: 15,
                      color: themeService.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: themeService.textHint,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      isDense: false,
                    ),
                    textAlignVertical: TextAlignVertical.center,
                  ),
                ),

                // Clear Button
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: _isSearching
                      ? Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: IconButton(
                            key: const ValueKey('clear'),
                            icon: Icon(
                              Icons.cancel,
                              color: themeService.textSecondary,
                              size: 18,
                            ),
                            onPressed: _clearSearch,
                            splashRadius: 20,
                          ),
                        )
                      : const SizedBox(
                          key: ValueKey('empty'),
                          width: 48,
                        ),
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }
}

