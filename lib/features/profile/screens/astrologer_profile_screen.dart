import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../services/services_exports.dart';
import '../../../shared/widgets/profile_avatar_widget.dart';
import '../../discovery/models/discovery_astrologer.dart';
import '../widgets/service_card_variants.dart';

/// Astrologer Profile Screen (End-User Perspective)
/// Facebook/Meta-level UI/UX Design
/// What users/seekers see when browsing astrologers
class AstrologerProfileScreen extends StatefulWidget {
  final DiscoveryAstrologer? astrologer;

  const AstrologerProfileScreen({super.key, this.astrologer});

  @override
  State<AstrologerProfileScreen> createState() => _AstrologerProfileScreenState();
}

class _AstrologerProfileScreenState extends State<AstrologerProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;
  final ScrollController _scrollController = ScrollController();
  bool _showStickyHeader = false;
  
  // Notification preferences
  bool _notificationsEnabled = false;
  bool _notifyOnline = true;
  bool _notifyLive = true;
  bool _notifyDiscussion = true;

  // Mock astrologer data
  final Map<String, dynamic> _mockAstrologer = {
    'name': 'Dr. Rajesh Kumar',
    'title': 'Vedic Astrology Expert',
    'rating': 4.8,
    'totalReviews': 230,
    'experience': 12,
    'totalConsultations': 1200,
    'languages': ['English', 'Hindi', 'Marathi'],
    'followers': 2450,
    'bio': 'Expert in Vedic Astrology with 12 years of experience. Specialized in career guidance, marriage compatibility, and gemstone recommendations. My approach combines ancient wisdom with modern life challenges.',
    'expertise': ['Career', 'Marriage', 'Health', 'Business', 'Gemstones', 'Kundali'],
    'qualifications': [
      'M.A. in Vedic Astrology',
      'Certified from ICAS',
      'Gold Medal in Jyotish Shastra',
    ],
    'achievements': [
      'Best Astrologer Award 2023',
      'Featured in Times of India',
      'TEDx Speaker on Astrology',
    ],
    'responseTime': '5 min',
    'repeatClients': 78,
    'verified': true,
  };

  Map<String, dynamic>? _customAstrologerData;

  Map<String, dynamic> get _astrologerData {
    if (widget.astrologer == null) {
      return _mockAstrologer;
    }
    return _customAstrologerData ??= _buildAstrologerData(widget.astrologer!);
  }

  Map<String, dynamic> _buildAstrologerData(DiscoveryAstrologer astrologer) {
    return {
      'name': astrologer.name,
      'title': astrologer.title,
      'rating': astrologer.rating,
      'totalReviews': astrologer.totalReviews,
      'experience': astrologer.experience,
      'followers': astrologer.followers,
      'responseTime': astrologer.responseTime,
      'repeatClients': astrologer.repeatClients,
      'bio': astrologer.bio.isNotEmpty ? astrologer.bio : _mockAstrologer['bio'],
      'expertise': astrologer.specializations.isNotEmpty
          ? astrologer.specializations
          : _mockAstrologer['expertise'],
      'qualifications': _mockAstrologer['qualifications'],
      'achievements': astrologer.achievements.isNotEmpty
          ? astrologer.achievements
          : _mockAstrologer['achievements'],
      'languages': astrologer.languages.isNotEmpty
          ? astrologer.languages
          : _mockAstrologer['languages'],
      'verified': astrologer.isVerified,
    };
  }

  final List<Map<String, dynamic>> _services = [
    {
      'name': 'Kundali Analysis',
      'description': 'Complete horoscope reading with life predictions and planetary analysis',
      'price': 1500,
      'duration': 60,
      'popular': true,
      'icon': Icons.auto_awesome,
    },
    {
      'name': 'Career Guidance',
      'description': 'Career path analysis, job changes, and business decisions',
      'price': 800,
      'duration': 45,
      'popular': true,
      'icon': Icons.work_outline,
    },
    {
      'name': 'Marriage Matching',
      'description': 'Kundali matching for marriage compatibility and timing',
      'price': 1200,
      'duration': 60,
      'popular': false,
      'icon': Icons.favorite_border,
    },
    {
      'name': 'Gemstone Consultation',
      'description': 'Personalized gemstone recommendations based on birth chart',
      'price': 600,
      'duration': 30,
      'popular': false,
      'icon': Icons.diamond_outlined,
    },
  ];

  final List<Map<String, dynamic>> _reviews = [
    {
      'name': 'Priya Sharma',
      'rating': 5,
      'date': '2 weeks ago',
      'service': 'Career Consultation',
      'comment': 'Dr. Kumar\'s guidance helped me make the right career decision. His predictions were incredibly accurate and I got the promotion he mentioned!',
      'helpful': 23,
      'verified': true,
    },
    {
      'name': 'Amit Verma',
      'rating': 5,
      'date': '1 month ago',
      'service': 'Marriage Consultation',
      'comment': 'Very patient and explains everything clearly. The kundali matching was detailed and helped us understand compatibility better. Highly recommended!',
      'helpful': 15,
      'verified': true,
    },
    {
      'name': 'Sneha Patel',
      'rating': 4,
      'date': '2 months ago',
      'service': 'Kundali Analysis',
      'comment': 'Good experience overall. The consultation was thorough and I learned a lot about my birth chart. Looking forward to a follow-up session.',
      'helpful': 8,
      'verified': false,
    },
  ];

  final List<Map<String, dynamic>> _posts = [
    {
      'id': '1',
      'title': 'Mercury Retrograde 2024 - What to Expect',
      'content': 'Navigate this challenging period with these simple tips and remedies. Learn how to protect your communication and avoid common pitfalls during this transit...',
      'author': 'Rajesh Kumar',
      'authorInitial': 'RK',
      'timeAgo': '3 days ago',
      'category': 'Astrology Guidance',
      'likes': 124,
      'isLiked': false,
    },
    {
      'id': '2',
      'title': 'Understanding Your Birth Chart - Complete Guide',
      'content': 'Learn how to read your birth chart and understand planetary influences. Discover the secrets hidden in your natal chart and how they shape your destiny...',
      'author': 'Rajesh Kumar',
      'authorInitial': 'RK',
      'timeAgo': '1 week ago',
      'category': 'Education',
      'likes': 67,
      'isLiked': false,
    },
    {
      'id': '3',
      'title': 'Career & Finance Predictions for 2024',
      'content': 'Detailed insights on career transitions and financial opportunities this year. Find out what the planets have in store for your professional growth...',
      'author': 'Rajesh Kumar',
      'authorInitial': 'RK',
      'timeAgo': '2 weeks ago',
      'category': 'Career & Finance',
      'likes': 189,
      'isLiked': false,
    },
    {
      'id': '4',
      'title': 'Remedies for Saturn Transit Effects',
      'content': 'Powerful remedies to mitigate challenging Saturn transits. Learn simple daily practices that can help you navigate difficult periods with grace...',
      'author': 'Rajesh Kumar',
      'authorInitial': 'RK',
      'timeAgo': '3 weeks ago',
      'category': 'Remedies',
      'likes': 98,
      'isLiked': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(_scrollListener);
    if (widget.astrologer != null) {
      _customAstrologerData = _buildAstrologerData(widget.astrologer!);
    }
  }

  void _scrollListener() {
    if (_scrollController.offset > 150 && !_showStickyHeader) {
      setState(() => _showStickyHeader = true);
    } else if (_scrollController.offset <= 150 && _showStickyHeader) {
      setState(() => _showStickyHeader = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AstrologerProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.astrologer != oldWidget.astrologer && widget.astrologer != null) {
      _customAstrologerData = _buildAstrologerData(widget.astrologer!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          body: Stack(
            children: [
              NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    _buildAppBar(themeService),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildHeader(themeService),
                          _buildQuickStats(themeService),
                          _buildActionButtons(themeService),
                        ],
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverTabBarDelegate(
                        TabBar(
                        controller: _tabController,
                        labelColor: themeService.primaryColor,
                        unselectedLabelColor: themeService.textSecondary,
                        indicatorColor: themeService.primaryColor,
                        indicatorWeight: 3,
                          labelStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          tabs: const [
                            Tab(text: 'About'),
                            Tab(text: 'Services'),
                            Tab(text: 'Reviews'),
                            Tab(text: 'Posts'),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAboutTab(themeService),
                    _buildServicesTab(themeService),
                    _buildReviewsTab(themeService),
                    _buildPostsTab(themeService),
                  ],
                ),
              ),
              
              // Sticky header when scrolling
              if (_showStickyHeader)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildStickyHeader(themeService),
                ),
              
              // Sticky booking button
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBookingButton(themeService),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(ThemeService themeService) {
    return SliverAppBar(
      backgroundColor: _showStickyHeader ? Colors.transparent : Colors.white,
      elevation: 0,
      floating: true,
      leadingWidth: _showStickyHeader ? 0 : 72,
      leading: _showStickyHeader
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(left: 16),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: themeService.cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: themeService.borderColor.withOpacity(0.1),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: themeService.textPrimary,
                    size: 18,
                  ),
                ),
              ),
            ),
      actions: _showStickyHeader ? [] : [
        // Notification Bell Icon
        IconButton(
          icon: Icon(
            _notificationsEnabled ? Icons.notifications_active : Icons.notifications_outlined,
            color: _notificationsEnabled ? themeService.primaryColor : themeService.textPrimary,
          ),
          onPressed: _showNotificationPreferences,
        ),
        // 3-dot menu
        IconButton(
          icon: Icon(Icons.more_vert, color: themeService.textPrimary),
          onPressed: _showOptionsMenu,
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeService themeService) {
    final profileData = _astrologerData;
    final name = profileData['name']?.toString() ?? 'Astrologer';
    final trimmedName = name.trim();
    final fallbackInitial =
        trimmedName.isNotEmpty ? trimmedName.substring(0, 1).toUpperCase() : 'A';
    final isOnline = widget.astrologer?.isOnline ?? true;
    final isVerified = profileData['verified'] == true;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Picture - Smaller with Online Status
          Stack(
            children: [
              ProfileAvatarWidget(
                imagePath: widget.astrologer?.profilePicture,
                radius: 36,
                fallbackText: fallbackInitial,
                backgroundColor: themeService.primaryColor.withOpacity(0.1),
                textColor: themeService.primaryColor,
              ),
              // Online Status Indicator (bottom-right)
              if (isOnline)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF44B700),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          
          // Name and Info - Compact
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeService.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified,
                        color: themeService.primaryColor,
                        size: 18,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  profileData['title'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: themeService.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFFC107), size: 16),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${profileData['rating']} (${profileData['totalReviews']}) • ${profileData['experience']}y exp',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: themeService.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ThemeService themeService) {
    final profileData = _astrologerData;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('${profileData['followers']}', 'Followers', themeService),
          Container(width: 1, height: 30, color: themeService.borderColor),
          _buildStatItem('${profileData['responseTime']}', 'Response', themeService),
          Container(width: 1, height: 30, color: themeService.borderColor),
          _buildStatItem('${profileData['repeatClients']}%', 'Repeat', themeService),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, ThemeService themeService) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: themeService.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: themeService.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeService themeService) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() => _isFollowing = !_isFollowing);
                HapticFeedback.selectionClick();
              },
              icon: Icon(_isFollowing ? Icons.check : Icons.add, size: 18),
              label: Text(
                _isFollowing ? 'Following' : 'Follow',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? themeService.borderColor : themeService.primaryColor,
                foregroundColor: _isFollowing ? themeService.textPrimary : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text(
                'Message',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: themeService.textPrimary,
                side: BorderSide(color: themeService.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyHeader(ThemeService themeService) {
    final profileData = _astrologerData;
    final name = profileData['name']?.toString() ?? 'Astrologer';
    final trimmedName = name.trim();
    final fallbackInitial =
        trimmedName.isNotEmpty ? trimmedName.substring(0, 1).toUpperCase() : 'A';
    final isOnline = widget.astrologer?.isOnline ?? true;

    return Material(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: themeService.textPrimary),
                onPressed: () => Navigator.pop(context),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              Stack(
                children: [
                  ProfileAvatarWidget(
                    imagePath: widget.astrologer?.profilePicture,
                    radius: 16,
                    fallbackText: fallbackInitial,
                    backgroundColor: themeService.primaryColor.withOpacity(0.1),
                    textColor: themeService.primaryColor,
                  ),
                  // Online Status Indicator
                  if (isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF44B700),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: themeService.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFFC107), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${profileData['rating']} • ${profileData['totalReviews']} reviews',
                          style: TextStyle(
                            fontSize: 12,
                            color: themeService.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Notification icon
              IconButton(
                icon: Icon(
                  _notificationsEnabled ? Icons.notifications_active : Icons.notifications_outlined,
                  color: _notificationsEnabled ? themeService.primaryColor : themeService.textPrimary,
                  size: 20,
                ),
                onPressed: _showNotificationPreferences,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
              ),
              // Menu icon
              IconButton(
                icon: Icon(Icons.more_vert, color: themeService.textPrimary, size: 20),
                onPressed: _showOptionsMenu,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tab Views - Will continue in next part...
  Widget _buildAboutTab(ThemeService themeService) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        const SizedBox(height: 12),
        _buildAboutBio(themeService),
        const SizedBox(height: 12),
        _buildExpertiseAreas(themeService),
        const SizedBox(height: 12),
        _buildQualifications(themeService),
        const SizedBox(height: 12),
        _buildAchievements(themeService),
        const SizedBox(height: 12),
        _buildLanguages(themeService),
        const SizedBox(height: 12),
        _buildConsultationRates(themeService),
      ],
    );
  }

  Widget _buildAboutBio(ThemeService themeService) {
    final profileData = _astrologerData;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: themeService.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'About',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeService.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            profileData['bio'],
            style: TextStyle(
              fontSize: 15,
              color: themeService.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertiseAreas(ThemeService themeService) {
    final profileData = _astrologerData;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium, color: themeService.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Expertise Areas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeService.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (profileData['expertise'] as List).map((expertise) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: themeService.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: themeService.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  expertise,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: themeService.primaryColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQualifications(ThemeService themeService) {
    final profileData = _astrologerData;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school, color: themeService.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Qualifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeService.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...(profileData['qualifications'] as List).map((qual) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF42B72A),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      qual,
                      style: TextStyle(
                        fontSize: 15,
                        color: themeService.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAchievements(ThemeService themeService) {
    final profileData = _astrologerData;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Color(0xFFFFC107), size: 20),
              const SizedBox(width: 8),
              Text(
                'Achievements & Awards',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeService.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...(profileData['achievements'] as List).map((achievement) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.stars,
                    color: Color(0xFFFFC107),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      achievement,
                      style: TextStyle(
                        fontSize: 15,
                        color: themeService.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLanguages(ThemeService themeService) {
    final profileData = _astrologerData;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language, color: themeService.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Languages',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeService.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            (profileData['languages'] as List).join(', '),
            style: TextStyle(
              fontSize: 15,
              color: themeService.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationRates(ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.currency_rupee, color: themeService.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Consultation Rates',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeService.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRateItem(Icons.phone, 'Voice Call', '₹500', '30 min', themeService),
          _buildRateItem(Icons.videocam, 'Video Call', '₹800', '30 min', themeService),
          _buildRateItem(Icons.chat_bubble_outline, 'Chat', '₹300', 'per session', themeService),
        ],
      ),
    );
  }

  Widget _buildRateItem(IconData icon, String type, String price, String duration, ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeService.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: themeService.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              type,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: themeService.textPrimary,
              ),
            ),
          ),
          Text(
            '$price/$duration',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: themeService.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTab(ThemeService themeService) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];
        return ServiceCardV2SwiggyStyle(
          service: service,
          themeService: themeService,
          onTap: () => _showBookingSheet(preselectedService: service), // Card tap -> Details
          onBookNow: () => _directToBooking(service), // BOOK button -> Direct to booking
        );
      },
    );
  }

  // Direct navigation to booking screen (skipping details)
  void _directToBooking(Map<String, dynamic> serviceData) {
    HapticFeedback.mediumImpact();
    
    // Convert mock service to ServiceModel
    final service = _convertToServiceModel(serviceData);
    
    // Create repository and add the service
    final repository = ServiceRepositoryImpl();
    repository.addService(service);
    
    // Navigate directly to booking screen with BLoC providers
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider<ServiceBloc>(
              create: (_) => ServiceBloc(repository: repository),
            ),
            BlocProvider<BookingBloc>(
              create: (_) => BookingBloc(repository: repository),
            ),
            BlocProvider<OrderBloc>(
              create: (_) => OrderBloc(repository: repository),
            ),
          ],
          child: ServiceBookingScreen(
            service: service,
            astrologerId: service.astrologerId,
            userId: 'user_123', // TODO: Get from auth service
          ),
        ),
      ),
    );
  }

  // Continuing with Reviews and Posts tabs...
  Widget _buildReviewsTab(ThemeService themeService) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        const SizedBox(height: 12),
        _buildRatingBreakdown(themeService),
        const SizedBox(height: 12),
        _buildMostMentioned(themeService),
        const SizedBox(height: 12),
        ..._reviews.map((review) => _buildReviewCard(review, themeService)),
      ],
    );
  }

  Widget _buildRatingBreakdown(ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rating Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildRatingBar(5, 180, 230, themeService),
          _buildRatingBar(4, 35, 230, themeService),
          _buildRatingBar(3, 10, 230, themeService),
          _buildRatingBar(2, 3, 230, themeService),
          _buildRatingBar(1, 2, 230, themeService),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count, int total, ThemeService themeService) {
    final percentage = (count / total * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$stars',
            style: TextStyle(
              fontSize: 14,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star, color: Color(0xFFFFC107), size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: themeService.borderColor,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                color: themeService.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostMentioned(ThemeService themeService) {
    final tags = ['Accurate', 'Patient', 'Helpful', 'Expert', 'Detailed'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Most Mentioned',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeService.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF42B72A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF42B72A),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileAvatarWidget(
                imagePath: null,
                radius: 20,
                fallbackText: review['name'][0],
                backgroundColor: themeService.primaryColor.withOpacity(0.1),
                textColor: themeService.primaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review['name'],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: themeService.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (review['verified'])
                          Icon(
                            Icons.verified,
                            color: themeService.primaryColor,
                            size: 14,
                          ),
                      ],
                    ),
                    Text(
                      review['date'],
                      style: TextStyle(
                        fontSize: 13,
                        color: themeService.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review['rating'] ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFC107),
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: themeService.borderColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              review['service'],
              style: TextStyle(
                fontSize: 12,
                color: themeService.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            review['comment'],
            style: TextStyle(
              fontSize: 15,
              color: themeService.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.thumb_up_outlined, size: 16),
                label: Text('Helpful (${review['helpful']})'),
                style: TextButton.styleFrom(
                  foregroundColor: themeService.textSecondary,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab(ThemeService themeService) {
    return Container(
      color: themeService.surfaceColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return _buildPostCard(_posts[index], themeService);
        },
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.white,
            Color(0xFFFAFAFA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Show post detail
            HapticFeedback.selectionClick();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Avatar + Metadata
                Row(
                  children: [
                    // Author Avatar
                    ProfileAvatarWidget(
                      imagePath: null,
                      radius: 20,
                      fallbackText: post['authorInitial'],
                      backgroundColor: themeService.primaryColor.withOpacity(0.1),
                      textColor: themeService.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    
                    // Author Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post['author'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${post['timeAgo']} • ${post['category']}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF6B6B8D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // More Options
                    IconButton(
                      icon: const Icon(
                        Icons.more_horiz,
                        color: Color(0xFF6B6B8D),
                        size: 20,
                      ),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Post Title
                Text(
                  post['title'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                    height: 1.4,
                    letterSpacing: -0.3,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Post Content Preview
                Text(
                  post['content'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B6B8D),
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 16),
                
                // Action Bar
                Row(
                  children: [
                    // Like Button
                    _buildDiscussionActionButton(
                      icon: post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                      label: '${post['likes']}',
                      color: post['isLiked'] ? Colors.red : const Color(0xFF6B6B8D),
                      onTap: () {
                        // Toggle like
                        HapticFeedback.selectionClick();
                      },
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Comment Button
                    _buildDiscussionActionButton(
                      icon: Icons.chat_bubble_outline,
                      label: 'Comment',
                      color: const Color(0xFF6B6B8D),
                      onTap: () {},
                    ),
                    
                    const Spacer(),
                    
                    // Share Button
                    IconButton(
                      icon: const Icon(
                        Icons.share_outlined,
                        size: 20,
                      ),
                      color: const Color(0xFF6B6B8D),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscussionActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingButton(ThemeService themeService) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.0),  // Transparent at top
            Colors.white.withOpacity(0.8),  // Semi-transparent
            Colors.white.withOpacity(0.95), // Almost solid
            Colors.white,                   // Solid white
          ],
          stops: const [0.0, 0.15, 0.4, 0.6],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Call Button (longest)
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                onPressed: () {
                  // Handle call action
                  HapticFeedback.selectionClick();
                },
                icon: const Icon(Icons.phone, size: 18),
                label: const Text('Call'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34A853),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Video Call Button (medium)
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Handle video call action
                  HapticFeedback.selectionClick();
                },
                icon: const Icon(Icons.videocam, size: 18),
                label: const Text('Video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA4335),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Book Consultation Button (medium)
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _showBookingSheet,
                icon: const Icon(Icons.calendar_today, size: 18),
                label: const Text('Book'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeService.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _showNotificationPreferences() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              _notificationsEnabled ? Icons.notifications_active : Icons.notifications_outlined,
              color: themeService.primaryColor,
            ),
            const SizedBox(width: 12),
            const Text(
              'Notification Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setDialogState(() => _notificationsEnabled = value);
                    setState(() => _notificationsEnabled = value);
                    HapticFeedback.selectionClick();
                  },
                  title: const Text(
                    'Enable Notifications',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Get notified about this astrologer'),
                  activeColor: themeService.primaryColor,
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                if (_notificationsEnabled) ...[
                  CheckboxListTile(
                    value: _notifyOnline,
                    onChanged: (value) {
                      setDialogState(() => _notifyOnline = value ?? true);
                      setState(() => _notifyOnline = value ?? true);
                      HapticFeedback.selectionClick();
                    },
                    title: const Text('Online Status'),
                    subtitle: const Text('When astrologer comes online'),
                    activeColor: themeService.primaryColor,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: _notifyLive,
                    onChanged: (value) {
                      setDialogState(() => _notifyLive = value ?? true);
                      setState(() => _notifyLive = value ?? true);
                      HapticFeedback.selectionClick();
                    },
                    title: const Text('Live Sessions'),
                    subtitle: const Text('When going live'),
                    activeColor: themeService.primaryColor,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: _notifyDiscussion,
                    onChanged: (value) {
                      setDialogState(() => _notifyDiscussion = value ?? true);
                      setState(() => _notifyDiscussion = value ?? true);
                      HapticFeedback.selectionClick();
                    },
                    title: const Text('New Discussions'),
                    subtitle: const Text('When creating new posts'),
                    activeColor: themeService.primaryColor,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: themeService.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Share option
              ListTile(
                leading: Icon(Icons.share_outlined, color: themeService.textPrimary),
                title: const Text(
                  'Share Profile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  HapticFeedback.selectionClick();
                  // Handle share
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share profile...')),
                  );
                },
              ),
              const Divider(height: 1),
              // Report option
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Color(0xFFEA4335)),
                title: const Text(
                  'Report',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFEA4335),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  HapticFeedback.selectionClick();
                  _showReportDialog();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.flag_outlined, color: Color(0xFFEA4335)),
            SizedBox(width: 12),
            Text(
              'Report Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to report this profile? Our team will review it.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report submitted. Thank you.')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEA4335)),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showBookingSheet({Map<String, dynamic>? preselectedService}) {
    HapticFeedback.mediumImpact();
    
    // Convert mock service to ServiceModel
    final service = _convertToServiceModel(preselectedService ?? _services[0]);
    
    // Create repository and add the service
    final repository = ServiceRepositoryImpl();
    repository.addService(service);
    
    // Navigate to service detail screen with BLoC providers
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => ServiceBloc(
                repository: repository,
              ),
            ),
            BlocProvider(
              create: (context) => BookingBloc(
                repository: repository,
              ),
            ),
            BlocProvider(
              create: (context) => OrderBloc(
                repository: repository,
              ),
            ),
          ],
          child: ServiceDetailScreen(
            serviceId: service.id,
            heroTag: 'service_${service.id}',
          ),
        ),
      ),
    );
  }
  
  // Convert mock service data to ServiceModel
  ServiceModel _convertToServiceModel(Map<String, dynamic> mockService) {
    // Map icon to string name
    String iconName = 'auto_awesome';
    if (mockService['icon'] == Icons.auto_awesome) {
      iconName = 'auto_awesome';
    } else if (mockService['icon'] == Icons.work_outline) {
      iconName = 'work_outline';
    } else if (mockService['icon'] == Icons.favorite_border) {
      iconName = 'favorite_border';
    } else if (mockService['icon'] == Icons.diamond_outlined) {
      iconName = 'diamond_outlined';
    }
    
    // Determine delivery methods based on service type
    List<DeliveryMethod> deliveryMethods = [
      DeliveryMethod.videoCall,
      DeliveryMethod.audioCall,
      DeliveryMethod.chat,
    ];
    
    // For report-based services
    if (mockService['name'] == 'Marriage Matching') {
      deliveryMethods = [
        DeliveryMethod.report,
        DeliveryMethod.videoCall,
      ];
    }
    
    return ServiceModel(
      id: 'srv_${mockService['name'].toString().replaceAll(' ', '_').toLowerCase()}',
      name: mockService['name'],
      description: mockService['description'],
      price: (mockService['price'] as int).toDouble(),
      durationInMinutes: mockService['duration'],
      serviceType: deliveryMethods.contains(DeliveryMethod.report) 
          ? ServiceType.report 
          : ServiceType.live,
      availableDeliveryMethods: deliveryMethods,
      iconName: iconName,
      astrologerId: 'astrologer_123', // Mock astrologer ID
      isPopular: mockService['popular'] ?? false,
      whatsIncluded: _getWhatsIncluded(mockService['name']),
      howItWorks: _getHowItWorks(mockService['name']),
      totalBookings: 150,
      averageRating: 4.8,
      reviewCount: 120,
    );
  }
  
  List<String> _getWhatsIncluded(String serviceName) {
    switch (serviceName) {
      case 'Kundali Analysis':
        return [
          'Complete birth chart analysis',
          'Planetary positions and their effects',
          'Dasha and transit predictions',
          'Life predictions for next 5 years',
          'Personalized remedies and suggestions',
          'Follow-up consultation (15 mins)',
        ];
      case 'Career Guidance':
        return [
          'Career horoscope analysis',
          'Best career path recommendations',
          'Job change timing prediction',
          'Business opportunity analysis',
          'Remedies for career growth',
        ];
      case 'Marriage Matching':
        return [
          'Guna Milan (36 points matching)',
          'Manglik Dosha analysis',
          'Compatibility report',
          'Marriage timing prediction',
          'Remedies for happy married life',
          'Detailed PDF report',
        ];
      case 'Gemstone Consultation':
        return [
          'Birth chart gemstone analysis',
          'Recommended gemstone(s)',
          'Wearing instructions',
          'Purity and authenticity tips',
          'Alternative gemstones',
        ];
      default:
        return [
          'Detailed consultation',
          'Personalized analysis',
          'Expert recommendations',
        ];
    }
  }
  
  List<String> _getHowItWorks(String serviceName) {
    if (serviceName == 'Marriage Matching') {
      return [
        'Share both partners birth details',
        'Analysis completed within 24 hours',
        'Receive comprehensive PDF report',
        'Optional video consultation for queries',
      ];
    }
    return [
      'Share your birth details (date, time, place)',
      'Schedule a consultation at your preferred time',
      'Join via video/audio call or chat',
      'Get personalized analysis and remedies',
    ];
  }

  Widget _buildBookingOption(IconData icon, String title, String price, String duration, ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: themeService.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: themeService.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: themeService.textPrimary,
              ),
            ),
          ),
          Text(
            '$price/$duration',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: themeService.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Sliver Tab Bar Delegate
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

