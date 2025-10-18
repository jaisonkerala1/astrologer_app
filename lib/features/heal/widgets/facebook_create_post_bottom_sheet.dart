import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/transition_animations.dart' hide AnimatedContainer;
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/profile_avatar_widget.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/models/astrologer_model.dart';
import '../../../core/services/status_service.dart';

class FacebookCreatePostBottomSheet extends StatefulWidget {
  final Function(String title, String content, String category, String privacy) onSubmit;

  const FacebookCreatePostBottomSheet({
    super.key,
    required this.onSubmit,
  });

  @override
  State<FacebookCreatePostBottomSheet> createState() => _FacebookCreatePostBottomSheetState();
}

class _FacebookCreatePostBottomSheetState extends State<FacebookCreatePostBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();
  
  String _selectedCategory = 'general';
  String _selectedPrivacy = 'Public';
  bool _isPosting = false;
  bool _showEmojiPicker = false;
  
  // Categories matching backend enum (lowercase)
  final List<Map<String, String>> _categories = [
    {'value': 'general', 'label': 'General Discussion'},
    {'value': 'vedic', 'label': 'Vedic Astrology'},
    {'value': 'western', 'label': 'Western Astrology'},
    {'value': 'numerology', 'label': 'Numerology'},
    {'value': 'tarot', 'label': 'Tarot & Divination'},
    {'value': 'palmistry', 'label': 'Palmistry'},
    {'value': 'vastu', 'label': 'Vastu Shastra & Feng Shui'},
    {'value': 'other', 'label': 'Other Topics'},
  ];
  
  final List<Map<String, dynamic>> _privacyOptions = [
    {'value': 'Public', 'label': 'Public', 'icon': Icons.public},
    {'value': 'Friends', 'label': 'Friends', 'icon': Icons.people},
    {'value': 'Only Me', 'label': 'Only Me', 'icon': Icons.lock},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: themeService.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(themeService),
              Flexible(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserProfile(themeService),
                      const SizedBox(height: 20),
                      _buildPrivacySelector(themeService),
                      const SizedBox(height: 20),
                      _buildTitleInput(themeService),
                      const SizedBox(height: 16),
                      _buildContentInput(themeService),
                      const SizedBox(height: 20),
                      _buildCategorySelector(themeService),
                      const SizedBox(height: 20),
                      _buildMediaOptions(themeService),
                    ],
                  ),
                ),
              ),
              // Add bottom padding for keyboard
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeService themeService) {
    return Row(
      children: [
        // Close button
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          color: themeService.textSecondary,
        ),
        const SizedBox(width: 8),
        // Title
        Text(
          'Create Post',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: themeService.textPrimary,
          ),
        ),
        const Spacer(),
        // Post button
        AnimatedButton(
          onPressed: _isPosting ? null : _handlePost,
          text: _isPosting ? 'Posting...' : 'Post',
          icon: _isPosting ? null : Icons.send,
          backgroundColor: _isPosting ? themeService.textSecondary : themeService.primaryColor,
          foregroundColor: Colors.white,
          width: 100,
          height: 40,
        ),
      ],
    );
  }

  Widget _buildUserProfile(ThemeService themeService) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return Consumer<StatusService>(
          builder: (context, statusService, child) {
            String userName = 'Your Name';
            bool isOnline = false;
            
            String? userPhoto;
            String userInitial = 'Y';
            
            if (authState is AuthSuccessState) {
              userName = authState.astrologer.name;
              isOnline = statusService.isOnline;
              userPhoto = authState.astrologer.profilePicture;
              userInitial = authState.astrologer.name.isNotEmpty 
                  ? authState.astrologer.name[0].toUpperCase() 
                  : 'Y';
            }
            
            return Row(
              children: [
                // Profile avatar with online status indicator
                Stack(
                  children: [
                    ProfileAvatarWidget(
                      imagePath: userPhoto,
                      radius: 25,
                      fallbackText: userInitial,
                      backgroundColor: themeService.primaryColor.withOpacity(0.1),
                      textColor: themeService.primaryColor,
                    ),
                    // Online status indicator
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: themeService.surfaceColor,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          isOnline ? Icons.circle : Icons.circle,
                          color: themeService.surfaceColor,
                          size: 8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeService.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'Astrologer',
                            style: TextStyle(
                              fontSize: 12,
                              color: themeService.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '•',
                            style: TextStyle(
                              fontSize: 12,
                              color: themeService.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOnline ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPrivacySelector(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: themeService.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeService.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _privacyOptions.firstWhere((option) => option['value'] == _selectedPrivacy)['icon']!,
            size: 16,
            color: themeService.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            _privacyOptions.firstWhere((option) => option['value'] == _selectedPrivacy)['label']!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _showPrivacyOptions,
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: themeService.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleInput(ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Post Title',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: themeService.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: themeService.surfaceColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeService.borderColor),
          ),
          child: TextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) {
              // Move focus to content field when done
              FocusScope.of(context).requestFocus(_contentFocusNode);
            },
            decoration: InputDecoration(
              hintText: 'What\'s on your mind?',
              hintStyle: TextStyle(
                color: themeService.textSecondary,
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: TextStyle(
              fontSize: 16,
              color: themeService.textPrimary,
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildContentInput(ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Post Content',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: themeService.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: themeService.surfaceColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeService.borderColor),
          ),
          child: TextField(
            controller: _contentController,
            focusNode: _contentFocusNode,
            textInputAction: TextInputAction.newline,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: 'Share your thoughts, experiences, or ask questions...',
              hintStyle: TextStyle(
                color: themeService.textSecondary,
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: TextStyle(
              fontSize: 16,
              color: themeService.textPrimary,
            ),
            maxLines: 6,
            minLines: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: themeService.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showCategoryOptions,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: themeService.surfaceColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: themeService.borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.category,
                  size: 20,
                  color: themeService.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _categories.firstWhere((cat) => cat['value'] == _selectedCategory)['label']!,
                    style: TextStyle(
                      fontSize: 14,
                      color: themeService.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: themeService.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaOptions(ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add to your post',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: themeService.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildMediaOption(
              icon: Icons.photo_library,
              label: 'Photo/Video',
              color: Colors.green,
              onTap: () => _handleMediaSelection('photo'),
            ),
            const SizedBox(width: 16),
            _buildMediaOption(
              icon: Icons.emoji_emotions,
              label: 'Feeling',
              color: Colors.orange,
              onTap: () => _handleMediaSelection('feeling'),
            ),
            const SizedBox(width: 16),
            _buildMediaOption(
              icon: Icons.location_on,
              label: 'Check in',
              color: Colors.red,
              onTap: () => _handleMediaSelection('location'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showPrivacyOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return Container(
            decoration: BoxDecoration(
              color: themeService.surfaceColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: themeService.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Text(
                      'Who can see your post?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeService.textPrimary,
                      ),
                    ),
                  ),
                  Divider(color: themeService.borderColor, height: 1),
                  ..._privacyOptions.map((option) => ListTile(
                    leading: Icon(
                      option['icon']!,
                      size: 20,
                      color: themeService.textSecondary,
                    ),
                    title: Text(
                      option['label']!,
                      style: TextStyle(color: themeService.textPrimary),
                    ),
                    trailing: _selectedPrivacy == option['value']
                        ? Icon(Icons.check, color: themeService.primaryColor)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedPrivacy = option['value']!;
                      });
                      Navigator.pop(context);
                    },
                  )),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCategoryOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: themeService.surfaceColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: themeService.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Text(
                        'Select Category',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeService.textPrimary,
                        ),
                      ),
                    ),
                    Divider(color: themeService.borderColor, height: 1),
                    // Scrollable list
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return ListTile(
                            title: Text(
                              category['label']!,
                              style: TextStyle(color: themeService.textPrimary),
                            ),
                            trailing: _selectedCategory == category['value']
                                ? Icon(Icons.check, color: themeService.primaryColor)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedCategory = category['value']!;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleMediaSelection(String type) {
    HapticFeedback.lightImpact();
    // TODO: Implement media selection based on type
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type selection coming soon!'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  void _handlePost() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both title and content'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    // Simulate posting delay
    await Future.delayed(const Duration(seconds: 1));

    // Call the callback with the post data
    widget.onSubmit(
      _titleController.text.trim(),
      _contentController.text.trim(),
      _selectedCategory,
      _selectedPrivacy,
    );

    setState(() {
      _isPosting = false;
    });

    Navigator.pop(context);
  }
}
