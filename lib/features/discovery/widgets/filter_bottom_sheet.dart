import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/services/theme_service.dart';

/// Sheet height modes
enum FilterSheetHeight {
  minimized, // 50% - Shows essential filters only
  full,      // 90% - All filters
}

class FilterBottomSheet extends StatefulWidget {
  final ThemeService themeService;
  final Map<String, dynamic> currentFilters;

  const FilterBottomSheet({
    super.key,
    required this.themeService,
    required this.currentFilters,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Map<String, dynamic> _filters;
  late FilterSheetHeight _currentHeight;

  // Filter options
  final List<String> _sortOptions = [
    'Popularity',
    'Experience High to Low',
    'Experience Low to High',
    'Orders High to Low',
    'Price',
    'Rating',
  ];

  final List<String> _skills = [
    'Face Reading',
    'Life Coach',
    'Nadi',
    'Numerology',
    'Palmistry',
    'Psychic',
    'Tarot',
    'Vastu',
    'Vedic',
  ];

  final List<String> _languages = [
    'English',
    'Hindi',
    'Bengali',
    'Gujarati',
    'Malayalam',
    'Kannada',
    'Marathi',
    'Punjabi',
    'Tamil',
    'Telugu',
    'Urdu',
  ];

  final List<String> _genders = ['Male', 'Female'];
  final List<String> _countries = ['India', 'Outside India'];
  final List<String> _offers = ['Active', 'Inactive'];

  // Top priority items for minimized view
  final List<String> _topSkills = ['Vedic', 'Tarot', 'Numerology', 'Palmistry', 'Vastu'];
  final List<String> _topLanguages = ['English', 'Hindi', 'Bengali', 'Tamil', 'Telugu'];

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.currentFilters);
    _currentHeight = FilterSheetHeight.minimized; // Start minimized
  }

  @override
  void dispose() {
    super.dispose();
  }

  double get _sheetHeight {
    final screenHeight = MediaQuery.of(context).size.height;
    switch (_currentHeight) {
      case FilterSheetHeight.minimized:
        return screenHeight * 0.50;
      case FilterSheetHeight.full:
        return screenHeight * 0.90;
    }
  }

  bool get _isMinimized => _currentHeight == FilterSheetHeight.minimized;

  void _toggleHeight() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentHeight = _isMinimized
          ? FilterSheetHeight.full
          : FilterSheetHeight.minimized;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: _sheetHeight,
        decoration: BoxDecoration(
          color: widget.themeService.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _buildDragHandle(),
            _buildHeader(),
            Expanded(child: _buildContent()),
            _buildApplyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: widget.themeService.borderColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: widget.themeService.borderColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Filter & Sort',
            style: TextStyle(
              color: widget.themeService.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          // Height toggle button
          GestureDetector(
            onTap: _toggleHeight,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                _isMinimized
                    ? Icons.unfold_more_rounded
                    : Icons.unfold_less_rounded,
                color: widget.themeService.primaryColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Clear button
          GestureDetector(
            onTap: _clearFilters,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Clear',
                style: TextStyle(
                  color: widget.themeService.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Close button
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.close_rounded,
                color: widget.themeService.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final sections = <Widget>[
      _buildSectionWrapper(_buildSortBySection()),
      _buildSectionWrapper(_buildSkillsSection()),
      _buildSectionWrapper(_buildLanguagesSection()),
    ];

    if (!_isMinimized) {
      sections.addAll([
        _buildSectionWrapper(_buildGenderSection()),
        _buildSectionWrapper(_buildCountrySection()),
        _buildSectionWrapper(_buildOffersSection()),
      ]);
    }

    return ListView.builder(
      key: ValueKey(_currentHeight), // Force rebuild when height changes
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemCount: sections.length + 1,
      itemBuilder: (context, index) {
        if (index == sections.length) {
          return const SizedBox(height: 20);
        }
        return sections[index];
      },
    );
  }

  Widget _buildSectionWrapper(Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: child,
    );
  }

  Widget _buildApplyButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.themeService.backgroundColor,
        border: Border(
          top: BorderSide(
            color: widget.themeService.borderColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.themeService.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Apply Filters ${_getActiveFilterCount() > 0 ? '(${_getActiveFilterCount()})' : ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortBySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Sort By'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _sortOptions.map((option) {
            final isSelected = _filters['sortBy'] == option;
            return _buildPillChip(
              label: option,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _filters['sortBy'] = isSelected ? null : option;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    final selectedSkills = (_filters['skills'] as List?) ?? [];
    final displaySkills = _isMinimized ? _topSkills : _skills;
    final hiddenCount = _skills.length - _topSkills.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionTitle('Skills'),
            if (_isMinimized && hiddenCount > 0) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _toggleHeight,
                child: Text(
                  '+$hiddenCount more',
                  style: TextStyle(
                    color: widget.themeService.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: displaySkills.map((skill) {
            final isSelected = selectedSkills.contains(skill);
            return _buildPillChip(
              label: skill,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  final skills = List<String>.from(selectedSkills);
                  if (isSelected) {
                    skills.remove(skill);
                  } else {
                    skills.add(skill);
                  }
                  _filters['skills'] = skills;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLanguagesSection() {
    final selectedLanguages = (_filters['languages'] as List?) ?? [];
    final displayLanguages = _isMinimized ? _topLanguages : _languages;
    final hiddenCount = _languages.length - _topLanguages.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionTitle('Languages'),
            if (_isMinimized && hiddenCount > 0) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _toggleHeight,
                child: Text(
                  '+$hiddenCount more',
                  style: TextStyle(
                    color: widget.themeService.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: displayLanguages.map((language) {
            final isSelected = selectedLanguages.contains(language);
            return _buildPillChip(
              label: language,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  final languages = List<String>.from(selectedLanguages);
                  if (isSelected) {
                    languages.remove(language);
                  } else {
                    languages.add(language);
                  }
                  _filters['languages'] = languages;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGenderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Gender'),
        const SizedBox(height: 12),
        Row(
          children: _genders.map((gender) {
            final isSelected = _filters['gender'] == gender;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildPillChip(
                label: gender,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _filters['gender'] = isSelected ? null : gender;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCountrySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Country'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _countries.map((country) {
            final isSelected = _filters['country'] == country;
            return _buildPillChip(
              label: country,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _filters['country'] = isSelected ? null : country;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOffersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Offers'),
        const SizedBox(height: 12),
        Row(
          children: _offers.map((offer) {
            final isSelected = _filters['offers'] == offer;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildPillChip(
                label: offer,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _filters['offers'] = isSelected ? null : offer;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: widget.themeService.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildPillChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? widget.themeService.primaryColor
              : widget.themeService.surfaceColor, // Use surfaceColor instead of cardColor for subtle contrast
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? widget.themeService.primaryColor
                : widget.themeService.borderColor.withOpacity(0.15), // Lighter border for unselected
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            // Elevated shadow for selected chips
            if (isSelected)
              BoxShadow(
                color: widget.themeService.primaryColor.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            // Subtle depth shadow for unselected chips
            if (!isSelected) ...[
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
              // Soft ambient shadow for extra depth
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : widget.themeService.textPrimary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_filters['sortBy'] != null) count++;
    if ((_filters['skills'] as List?)?.isNotEmpty ?? false) {
      count += (_filters['skills'] as List).length;
    }
    if ((_filters['languages'] as List?)?.isNotEmpty ?? false) {
      count += (_filters['languages'] as List).length;
    }
    if (_filters['gender'] != null) count++;
    if (_filters['country'] != null) count++;
    if (_filters['offers'] != null) count++;
    return count;
  }

  void _clearFilters() {
    setState(() {
      _filters = {
        'sortBy': null,
        'skills': [],
        'languages': [],
        'gender': null,
        'country': null,
        'offers': null,
      };
    });
  }

  void _applyFilters() {
    Navigator.pop(context, _filters);
  }
}

