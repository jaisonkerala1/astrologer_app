import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';

class ConsultationSearchBar extends StatefulWidget {
  final String searchQuery;
  final bool isSearching;
  final int resultCount;
  final Function(String) onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onSearchSubmitted;

  const ConsultationSearchBar({
    super.key,
    required this.searchQuery,
    required this.isSearching,
    required this.resultCount,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSearchSubmitted,
  });

  @override
  State<ConsultationSearchBar> createState() => _ConsultationSearchBarState();
}

class _ConsultationSearchBarState extends State<ConsultationSearchBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
    _focusNode = FocusNode();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ConsultationSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      _controller.text = widget.searchQuery;
    }
  }

  void _onSearchChanged(String value) {
    widget.onSearchChanged(value);
  }

  void _onClearPressed() {
    _controller.clear();
    _focusNode.unfocus();
    widget.onClearSearch();
    HapticFeedback.selectionClick();
  }

  void _onSearchSubmitted(String value) {
    widget.onSearchSubmitted();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Main search bar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: themeService.surfaceColor,
                        borderRadius: themeService.borderRadius,
                        border: Border.all(
                          color: themeService.borderColor,
                          width: 1,
                        ),
                        boxShadow: [themeService.cardShadow],
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onChanged: _onSearchChanged,
                        onSubmitted: _onSearchSubmitted,
                        textInputAction: TextInputAction.search,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: themeService.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search consultations...',
                          hintStyle: TextStyle(
                            color: themeService.textHint,
                            fontWeight: FontWeight.w400,
                            fontSize: 15,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.search_rounded,
                              color: widget.isSearching 
                                  ? themeService.primaryColor 
                                  : themeService.textHint,
                              size: 20,
                            ),
                          ),
                          suffixIcon: widget.searchQuery.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _onClearPressed,
                                      borderRadius: themeService.borderRadius,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: themeService.borderColor,
                                          borderRadius: themeService.borderRadius,
                                        ),
                                        child: Icon(
                                          Icons.close_rounded,
                                          color: themeService.textSecondary,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    
                    // Results indicator (integrated into search bar)
                    if (widget.isSearching && widget.searchQuery.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: themeService.backgroundColor,
                          borderRadius: themeService.borderRadius,
                          border: Border.all(
                            color: themeService.borderColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: themeService.textSecondary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.resultCount == 0
                                    ? 'No results for "${widget.searchQuery}"'
                                    : widget.resultCount == 1
                                        ? '1 result for "${widget.searchQuery}"'
                                        : '${widget.resultCount} results for "${widget.searchQuery}"',
                                style: TextStyle(
                                  color: themeService.textSecondary,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class SearchResultsIndicator extends StatelessWidget {
  final int resultCount;
  final String searchQuery;
  final bool isSearching;

  const SearchResultsIndicator({
    super.key,
    required this.resultCount,
    required this.searchQuery,
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context) {
    if (!isSearching || searchQuery.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: Colors.grey[600],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              resultCount == 0
                  ? 'No results for "$searchQuery"'
                  : resultCount == 1
                      ? '1 result for "$searchQuery"'
                      : '$resultCount results for "$searchQuery"',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchEmptyState extends StatelessWidget {
  final String searchQuery;
  final VoidCallback onClearSearch;

  const SearchEmptyState({
    super.key,
    required this.searchQuery,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Center(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: themeService.surfaceColor,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: themeService.textHint,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Results Found',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: themeService.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No consultations match "$searchQuery"',
                    style: TextStyle(
                      fontSize: 16,
                      color: themeService.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try searching with different keywords',
                    style: TextStyle(
                      fontSize: 14,
                      color: themeService.textHint,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: onClearSearch,
                    icon: const Icon(Icons.clear_all_rounded),
                    label: const Text('Clear Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeService.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: themeService.borderRadius,
                      ),
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
