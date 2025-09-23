import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/simple_shimmer.dart';
import '../models/help_article.dart';
import '../services/help_support_service.dart';
import 'help_support_screen.dart';

class FAQScreen extends StatefulWidget {
  final List<FAQItem> faqItems;
  final bool isLoading;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const FAQScreen({
    super.key,
    required this.faqItems,
    required this.isLoading,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<FAQItem> _filteredFAQ = [];
  String _selectedCategory = 'All';
  final HelpSupportService _helpSupportService = HelpSupportService();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
    _filteredFAQ = widget.faqItems;
    _filterFAQ();
  }

  @override
  void didUpdateWidget(FAQScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.faqItems != oldWidget.faqItems) {
      _filteredFAQ = widget.faqItems;
      _filterFAQ();
    }
  }

  void _filterFAQ() {
    setState(() {
      _filteredFAQ = widget.faqItems.where((faq) {
        final matchesCategory = _selectedCategory == 'All' || 
                               faq.category == _selectedCategory;
        final matchesSearch = widget.searchQuery.isEmpty ||
                             faq.question.toLowerCase().contains(widget.searchQuery.toLowerCase()) ||
                             faq.answer.toLowerCase().contains(widget.searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    widget.onSearchChanged(query);
    _filterFAQ();
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterFAQ();
  }

  void _toggleFAQ(int index) {
    setState(() {
      _filteredFAQ[index] = _filteredFAQ[index].copyWith(
        isExpanded: !_filteredFAQ[index].isExpanded,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        HelpSearchBar(
          controller: _searchController,
          hintText: 'Search FAQ...',
          onChanged: _onSearchChanged,
          onClear: () {
            _searchController.clear();
            _onSearchChanged('');
          },
        ),
        
        // Category filter
        _buildCategoryFilter(),
        
        // Content
        Expanded(
          child: widget.isLoading
              ? const FAQContentSkeleton()
              : _filteredFAQ.isEmpty
                  ? _buildEmptyState()
                  : _buildFAQList(),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', ..._helpSupportService.getFAQCategories()];
    
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedCategory;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _onCategoryChanged(category);
                }
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFAQList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredFAQ.length,
      itemBuilder: (context, index) {
        final faq = _filteredFAQ[index];
        return _buildFAQItem(faq, index);
      },
    );
  }

  Widget _buildFAQItem(FAQItem faq, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            faq.question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    faq.answer,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          faq.category,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _buildHelpfulButtons(faq, index),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpfulButtons(FAQItem faq, int index) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _filteredFAQ[index] = faq.copyWith(
                helpfulCount: faq.helpfulCount + 1,
              );
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.thumb_up,
                  size: 14,
                  color: Colors.green[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${faq.helpfulCount}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              _filteredFAQ[index] = faq.copyWith(
                notHelpfulCount: faq.notHelpfulCount + 1,
              );
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.thumb_down,
                  size: 14,
                  color: Colors.red[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${faq.notHelpfulCount}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.help_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No FAQ found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or category filter',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// FAQ content skeleton
class FAQContentSkeleton extends StatelessWidget {
  const FAQContentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerContainer(
                width: double.infinity,
                height: 20,
                borderRadius: 4,
              ),
              const SizedBox(height: 12),
              ShimmerContainer(
                width: double.infinity,
                height: 16,
                borderRadius: 4,
              ),
              const SizedBox(height: 8),
              ShimmerContainer(
                width: 150,
                height: 16,
                borderRadius: 4,
              ),
            ],
          ),
        );
      },
    );
  }
}
