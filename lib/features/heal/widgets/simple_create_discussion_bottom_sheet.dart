import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/theme/models/app_theme.dart';
import '../../../shared/widgets/profile_avatar_widget.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/models/astrologer_model.dart';

class SimpleCreateDiscussionBottomSheet extends StatefulWidget {
  final Function(String title, String content, String category) onSubmit;

  const SimpleCreateDiscussionBottomSheet({
    super.key,
    required this.onSubmit,
  });

  @override
  State<SimpleCreateDiscussionBottomSheet> createState() => _SimpleCreateDiscussionBottomSheetState();
}

class _SimpleCreateDiscussionBottomSheetState extends State<SimpleCreateDiscussionBottomSheet> {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedCategory = 'General';
  bool _isPosting = false;
  AstrologerModel? _currentUser;

  final List<String> _categories = [
    'General',
    'Astrology',
    'Vedic',
    'Tarot',
    'Numerology',
    'Healing',
    'Meditation',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccessState) {
      setState(() {
        _currentUser = authState.astrologer;
      });
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handlePost() async {
    if (_topicController.text.trim().isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.discussionTopicRequired),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isPosting = true);
    HapticFeedback.mediumImpact();

    await widget.onSubmit(
      _topicController.text.trim(),
      _descriptionController.text.trim(),
      _selectedCategory,
    );

    if (mounted) {
      setState(() => _isPosting = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.currentTheme.type == AppThemeType.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          gradient: isDarkMode
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1A1A2E),
                    Color(0xFF0F0F1E),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            _buildHeader(l10n, themeService, isDarkMode),
            Expanded(
              child: Column(
                children: [
                  _buildCategoryChips(themeService, isDarkMode),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    color: isDarkMode 
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.08),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTopicInput(l10n, isDarkMode),
                          const SizedBox(height: 20),
                          _buildDescriptionInput(l10n, isDarkMode),
                        ],
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
  }

  Widget _buildHeader(AppLocalizations l10n, ThemeService themeService, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
      child: Row(
        children: [
          // Close button
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.close,
              color: isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black87,
            ),
          ),
          
          // Title (center)
          Expanded(
            child: Text(
              l10n.createDiscussion,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          
          // Post button (right)
          GestureDetector(
            onTap: _isPosting ? null : _handlePost,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isPosting 
                    ? Colors.grey.shade600 
                    : themeService.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isPosting ? l10n.posting : l10n.postDiscussion,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(ThemeService themeService, bool isDarkMode) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedCategory = category);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? themeService.primaryColor 
                      : (isDarkMode 
                          ? Colors.white.withOpacity(0.1) 
                          : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected 
                      ? null 
                      : Border.all(
                          color: isDarkMode 
                              ? Colors.white.withOpacity(0.1) 
                              : Colors.grey.shade300,
                        ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected 
                        ? Colors.white 
                        : (isDarkMode 
                            ? Colors.white.withOpacity(0.7) 
                            : Colors.black87),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopicInput(AppLocalizations l10n, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Avatar - Ultra minimal integration
        Container(
          margin: const EdgeInsets.only(right: 12, top: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDarkMode 
                  ? Colors.white.withOpacity(0.15) 
                  : Colors.black.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ProfileAvatarWidget(
            imagePath: _currentUser?.profilePicture,
            radius: 18,
            fallbackText: _currentUser?.name?.substring(0, 1).toUpperCase() ?? 'A',
            backgroundColor: isDarkMode 
                ? const Color(0xFF2A2A3E) 
                : Colors.grey.shade100,
            textColor: isDarkMode 
                ? Colors.white.withOpacity(0.9)
                : Colors.black87,
          ),
        ),
        
        // Topic Input - Flows naturally after avatar
        Expanded(
          child: TextField(
            controller: _topicController,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
            decoration: InputDecoration(
              hintText: l10n.discussionTopicHint,
              hintStyle: TextStyle(
                color: isDarkMode 
                    ? Colors.white.withOpacity(0.35) 
                    : Colors.grey.shade400,
                fontSize: 20,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.only(top: 2),
              isDense: true,
            ),
            textInputAction: TextInputAction.next,
            maxLength: 100,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionInput(AppLocalizations l10n, bool isDarkMode) {
    return TextField(
      controller: _descriptionController,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText: l10n.discussionDescriptionHint,
        hintStyle: TextStyle(
          color: isDarkMode 
              ? Colors.white.withOpacity(0.4) 
              : Colors.grey.shade500,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      minLines: 3,
      maxLines: 10,
      maxLength: 500,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
    );
  }
}

