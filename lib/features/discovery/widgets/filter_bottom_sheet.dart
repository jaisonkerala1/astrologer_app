import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/services/theme_service.dart';

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

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.currentFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.themeService.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: widget.themeService.borderColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
                TextButton(
                  onPressed: _clearFilters,
                  style: TextButton.styleFrom(
                    foregroundColor: widget.themeService.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: widget.themeService.textSecondary,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: widget.themeService.borderColor.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSortBySection(),
                  const SizedBox(height: 24),
                  _buildSkillsSection(),
                  const SizedBox(height: 24),
                  _buildLanguagesSection(),
                  const SizedBox(height: 24),
                  _buildGenderSection(),
                  const SizedBox(height: 24),
                  _buildCountrySection(),
                  const SizedBox(height: 24),
                  _buildOffersSection(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Apply button
          Container(
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
          ),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Skills'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _skills.map((skill) {
            final selectedSkills = (_filters['skills'] as List?) ?? [];
            final isSelected = selectedSkills.contains(skill);
            return _buildPillChip(
              label: skill,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  final skills = List<String>.from((_filters['skills'] as List?) ?? []);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Languages'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _languages.map((language) {
            final selectedLanguages = (_filters['languages'] as List?) ?? [];
            final isSelected = selectedLanguages.contains(language);
            return _buildPillChip(
              label: language,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  final languages = List<String>.from((_filters['languages'] as List?) ?? []);
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
              : widget.themeService.cardColor,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? widget.themeService.primaryColor
                : widget.themeService.borderColor.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: widget.themeService.primaryColor.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
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

