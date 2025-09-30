import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/transition_animations.dart';
import '../../../shared/widgets/animated_button.dart';
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

class _FacebookCreatePostBottomSheetState extends State<FacebookCreatePostBottomSheet>
    with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();
  
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  String _selectedCategory = 'General';
  String _selectedPrivacy = 'Public';
  bool _isPosting = false;
  bool _showEmojiPicker = false;
  
  final List<String> _categories = [
    'General',
    'Astrology & Horoscopes',
    'Vedic Astrology',
    'Western Astrology',
    'Numerology',
    'Tarot & Divination',
    'Crystal Healing',
    'Chakra Healing',
    'Reiki & Energy Healing',
    'Meditation & Mindfulness',
    'Yoga & Spiritual Practice',
    'Buddhism & Philosophy',
    'New Age & Awakening',
    'Spiritual Guidance',
    'Dream Interpretation',
    'Palmistry & Palm Reading',
    'Feng Shui & Vastu',
    'Mantras & Chanting',
    'Ayurveda & Wellness',
    'Community Support & Life Talk',
  ];
  
  final List<Map<String, dynamic>> _privacyOptions = [
    {'value': 'Public', 'label': 'Public', 'icon': Icons.public},
    {'value': 'Friends', 'label': 'Friends', 'icon': Icons.people},
    {'value': 'Only Me', 'label': 'Only Me', 'icon': Icons.lock},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupFocusListeners();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    // Start animations
    _slideController.forward();
    _fadeController.forward();
  }

  void _setupFocusListeners() {
    _titleFocusNode.addListener(() {
      if (_titleFocusNode.hasFocus) {
        _slideController.forward();
      }
    });
    
    _contentFocusNode.addListener(() {
      if (_contentFocusNode.hasFocus) {
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildUserProfile(),
                          const SizedBox(height: 20),
                          _buildPrivacySelector(),
                          const SizedBox(height: 20),
                          _buildTitleInput(),
                          const SizedBox(height: 16),
                          _buildContentInput(),
                          const SizedBox(height: 20),
                          _buildCategorySelector(),
                          const SizedBox(height: 20),
                          _buildMediaOptions(),
                        ],
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Close button
          GestureDetector(
            onTap: () => _closeBottomSheet(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.close,
                size: 20,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          const Text(
            'Create Post',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          // Post button
          AnimatedButton(
            onPressed: _isPosting ? null : _handlePost,
            text: _isPosting ? 'Posting...' : 'Post',
            icon: _isPosting ? null : Icons.send,
            backgroundColor: _isPosting ? Colors.grey : AppTheme.primaryColor,
            foregroundColor: Colors.white,
            width: 100,
            height: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return Consumer<StatusService>(
          builder: (context, statusService, child) {
            String userName = 'Your Name';
            bool isOnline = false;
            
            if (authState is AuthSuccessState) {
              userName = authState.astrologer.name;
              isOnline = statusService.isOnline;
            }
            
            return Row(
              children: [
                // Profile avatar with online status indicator
                Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
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
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          isOnline ? Icons.circle : Icons.circle,
                          color: Colors.white,
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'Astrologer',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '•',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
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

  Widget _buildPrivacySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _privacyOptions.firstWhere((option) => option['value'] == _selectedPrivacy)['icon']!,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            _privacyOptions.firstWhere((option) => option['value'] == _selectedPrivacy)['label']!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _showPrivacyOptions,
            child: const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Post Title',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            decoration: const InputDecoration(
              hintText: 'What\'s on your mind?',
              hintStyle: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildContentInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Post Content',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: _contentController,
            focusNode: _contentFocusNode,
            decoration: const InputDecoration(
              hintText: 'Share your thoughts, experiences, or ask questions...',
              hintStyle: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
            maxLines: 6,
            minLines: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showCategoryOptions,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.category,
                  size: 20,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedCategory,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add to your post',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
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
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Who can see your post?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ..._privacyOptions.map((option) => ListTile(
              leading: Icon(
                option['icon']!,
                size: 20,
                color: Colors.grey[600],
              ),
              title: Text(option['label']!),
              trailing: _selectedPrivacy == option['value']
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
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
  }

  void _showCategoryOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Select Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ..._categories.map((category) => ListTile(
              title: Text(category),
              trailing: _selectedCategory == category
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _handleMediaSelection(String type) {
    HapticFeedback.lightImpact();
    // TODO: Implement media selection based on type
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type selection coming soon!'),
        backgroundColor: AppTheme.primaryColor,
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

    _closeBottomSheet();
  }

  void _closeBottomSheet() {
    _slideController.reverse().then((_) {
      _fadeController.reverse().then((_) {
        Navigator.pop(context);
      });
    });
  }
}
