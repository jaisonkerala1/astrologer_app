import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/profile_avatar_widget.dart';

/// Astrologer Profile Screen (End-User Perspective)
/// Facebook/Meta-level UI/UX Design
/// What users/seekers see when browsing astrologers
class AstrologerProfileScreen extends StatefulWidget {
  const AstrologerProfileScreen({super.key});

  @override
  State<AstrologerProfileScreen> createState() => _AstrologerProfileScreenState();
}

class _AstrologerProfileScreenState extends State<AstrologerProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;
  final ScrollController _scrollController = ScrollController();
  bool _showStickyHeader = false;

  // Mock astrologer data
  final Map<String, dynamic> _mockAstrologer = {
    'name': 'Dr. Rajesh Kumar',
    'title': 'Vedic Astrology Expert',
    'rating': 4.8,
    'totalReviews': 230,
    'experience': 12,
    'totalConsultations': 1200,
    'responseTime': 'Within 2 hours',
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
    'accuracyRate': 95,
    'repeatClients': 78,
    'verified': true,
  };

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
      'title': 'Mercury Retrograde 2024 - What to Expect',
      'excerpt': 'Navigate this challenging period with these simple tips and remedies...',
      'type': 'article',
      'date': '3 days ago',
      'likes': 124,
      'comments': 23,
      'views': 890,
    },
    {
      'title': 'Understanding Your Birth Chart - Complete Guide',
      'excerpt': 'Learn how to read your birth chart and understand planetary influences',
      'type': 'video',
      'duration': '12:45',
      'date': '1 week ago',
      'likes': 67,
      'comments': 12,
      'views': 456,
    },
    {
      'title': 'Career & Finance Q&A Session',
      'excerpt': 'Live session replay covering common career and financial questions',
      'type': 'live',
      'duration': '45:20',
      'date': '2 weeks ago',
      'likes': 189,
      'comments': 34,
      'views': 1200,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.offset > 200 && !_showStickyHeader) {
      setState(() => _showStickyHeader = true);
    } else if (_scrollController.offset <= 200 && _showStickyHeader) {
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
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: Stack(
            children: [
              NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    _buildAppBar(),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildHeader(),
                          _buildQuickStats(),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverTabBarDelegate(
                        TabBar(
                          controller: _tabController,
                          labelColor: const Color(0xFF1877F2),
                          unselectedLabelColor: const Color(0xFF65676B),
                          indicatorColor: const Color(0xFF1877F2),
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
                    _buildAboutTab(),
                    _buildServicesTab(),
                    _buildReviewsTab(),
                    _buildPostsTab(),
                  ],
                ),
              ),
              
              // Sticky booking button
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBookingButton(),
              ),
              
              // Sticky header when scrolling
              if (_showStickyHeader) _buildStickyHeader(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      floating: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF050505)),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Color(0xFF050505)),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Color(0xFF050505)),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Picture
          Stack(
            children: [
              ProfileAvatarWidget(
                imagePath: null,
                radius: 60,
                fallbackText: 'RK',
                backgroundColor: const Color(0xFF1877F2).withOpacity(0.1),
                textColor: const Color(0xFF1877F2),
              ),
              if (_mockAstrologer['verified'])
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1877F2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Name and Title
          Text(
            _mockAstrologer['name'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF050505),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _mockAstrologer['title'],
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF65676B),
            ),
          ),
          const SizedBox(height: 12),
          
          // Rating and Reviews
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Color(0xFFFFC107), size: 20),
              const SizedBox(width: 4),
              Text(
                '${_mockAstrologer['rating']}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF050505),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${_mockAstrologer['totalReviews']} reviews)',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF65676B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_mockAstrologer['experience']} years experience • ${_mockAstrologer['totalConsultations']}+ consultations',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF65676B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.people_outline, '${_mockAstrologer['followers']}', 'Followers'),
          Container(width: 1, height: 40, color: const Color(0xFFE4E6EB)),
          _buildStatItem(Icons.speed, '${_mockAstrologer['accuracyRate']}%', 'Accuracy'),
          Container(width: 1, height: 40, color: const Color(0xFFE4E6EB)),
          _buildStatItem(Icons.repeat, '${_mockAstrologer['repeatClients']}%', 'Repeat'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF1877F2), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF050505),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF65676B),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() => _isFollowing = !_isFollowing);
                HapticFeedback.lightImpact();
              },
              icon: Icon(_isFollowing ? Icons.check : Icons.add, size: 20),
              label: Text(_isFollowing ? 'Following' : 'Follow'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? const Color(0xFFE4E6EB) : const Color(0xFF1877F2),
                foregroundColor: _isFollowing ? const Color(0xFF050505) : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.message_outlined, size: 20),
              label: const Text('Message'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF050505),
                side: const BorderSide(color: Color(0xFFCED0D4)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            ProfileAvatarWidget(
              imagePath: null,
              radius: 16,
              fallbackText: 'RK',
              backgroundColor: const Color(0xFF1877F2).withOpacity(0.1),
              textColor: const Color(0xFF1877F2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _mockAstrologer['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF050505),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFC107), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${_mockAstrologer['rating']}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF65676B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _showBookingSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1877F2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text('Book'),
            ),
          ],
        ),
      ),
    );
  }

  // Tab Views - Will continue in next part...
  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        const SizedBox(height: 12),
        _buildAboutBio(),
        const SizedBox(height: 12),
        _buildExpertiseAreas(),
        const SizedBox(height: 12),
        _buildQualifications(),
        const SizedBox(height: 12),
        _buildAchievements(),
        const SizedBox(height: 12),
        _buildLanguages(),
        const SizedBox(height: 12),
        _buildConsultationRates(),
      ],
    );
  }

  Widget _buildAboutBio() {
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
          const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF1877F2), size: 20),
              SizedBox(width: 8),
              Text(
                'About',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF050505),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _mockAstrologer['bio'],
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF050505),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertiseAreas() {
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
          const Row(
            children: [
              Icon(Icons.workspace_premium, color: Color(0xFF1877F2), size: 20),
              SizedBox(width: 8),
              Text(
                'Expertise Areas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF050505),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (_mockAstrologer['expertise'] as List).map((expertise) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1877F2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF1877F2).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  expertise,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1877F2),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQualifications() {
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
          const Row(
            children: [
              Icon(Icons.school, color: Color(0xFF1877F2), size: 20),
              SizedBox(width: 8),
              Text(
                'Qualifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF050505),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...(_mockAstrologer['qualifications'] as List).map((qual) {
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
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF050505),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
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
          const Row(
            children: [
              Icon(Icons.emoji_events, color: Color(0xFFFFC107), size: 20),
              SizedBox(width: 8),
              Text(
                'Achievements & Awards',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF050505),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...(_mockAstrologer['achievements'] as List).map((achievement) {
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
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF050505),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLanguages() {
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
          const Row(
            children: [
              Icon(Icons.language, color: Color(0xFF1877F2), size: 20),
              SizedBox(width: 8),
              Text(
                'Languages',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF050505),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            (_mockAstrologer['languages'] as List).join(', '),
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF050505),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationRates() {
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
          const Row(
            children: [
              Icon(Icons.currency_rupee, color: Color(0xFF1877F2), size: 20),
              SizedBox(width: 8),
              Text(
                'Consultation Rates',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF050505),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRateItem(Icons.phone, 'Voice Call', '₹500', '30 min'),
          _buildRateItem(Icons.videocam, 'Video Call', '₹800', '30 min'),
          _buildRateItem(Icons.chat_bubble_outline, 'Chat', '₹300', 'per session'),
        ],
      ),
    );
  }

  Widget _buildRateItem(IconData icon, String type, String price, String duration) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1877F2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF1877F2), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              type,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF050505),
              ),
            ),
          ),
          Text(
            '$price/$duration',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1877F2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];
        return _buildServiceCard(service);
      },
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: service['popular']
            ? Border.all(color: const Color(0xFF1877F2), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1877F2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  service['icon'],
                  color: const Color(0xFF1877F2),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            service['name'],
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF050505),
                            ),
                          ),
                        ),
                        if (service['popular'])
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC107),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'POPULAR',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Color(0xFF65676B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${service['duration']} mins',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF65676B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            service['description'],
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF65676B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '₹${service['price']}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1877F2),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _showBookingSheet(preselectedService: service),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1877F2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Book Now'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Continuing with Reviews and Posts tabs...
  Widget _buildReviewsTab() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        const SizedBox(height: 12),
        _buildRatingBreakdown(),
        const SizedBox(height: 12),
        _buildMostMentioned(),
        const SizedBox(height: 12),
        ..._reviews.map((review) => _buildReviewCard(review)).toList(),
      ],
    );
  }

  Widget _buildRatingBreakdown() {
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
          const Text(
            'Rating Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF050505),
            ),
          ),
          const SizedBox(height: 16),
          _buildRatingBar(5, 180, 230),
          _buildRatingBar(4, 35, 230),
          _buildRatingBar(3, 10, 230),
          _buildRatingBar(2, 3, 230),
          _buildRatingBar(1, 2, 230),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count, int total) {
    final percentage = (count / total * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$stars',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF050505),
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
                backgroundColor: const Color(0xFFE4E6EB),
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
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF65676B),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostMentioned() {
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
          const Text(
            'Most Mentioned',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF050505),
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

  Widget _buildReviewCard(Map<String, dynamic> review) {
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
                backgroundColor: const Color(0xFF1877F2).withOpacity(0.1),
                textColor: const Color(0xFF1877F2),
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
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF050505),
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (review['verified'])
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF1877F2),
                            size: 14,
                          ),
                      ],
                    ),
                    Text(
                      review['date'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF65676B),
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
              color: const Color(0xFFE4E6EB),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              review['service'],
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF65676B),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            review['comment'],
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF050505),
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
                  foregroundColor: const Color(0xFF65676B),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 80),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        return _buildPostCard(_posts[index]);
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    IconData typeIcon;
    String typeLabel;
    Color typeColor;

    switch (post['type']) {
      case 'video':
        typeIcon = Icons.play_circle_outline;
        typeLabel = post['duration'];
        typeColor = const Color(0xFFEA4335);
        break;
      case 'live':
        typeIcon = Icons.wifi_tethering;
        typeLabel = 'LIVE REPLAY';
        typeColor = const Color(0xFFEA4335);
        break;
      default:
        typeIcon = Icons.article_outlined;
        typeLabel = 'ARTICLE';
        typeColor = const Color(0xFF1877F2);
    }

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post image/video thumbnail
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF1877F2).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Center(
              child: Icon(
                typeIcon,
                size: 64,
                color: typeColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      post['date'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF65676B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  post['title'],
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF050505),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post['excerpt'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF65676B),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildEngagementItem(Icons.favorite_border, '${post['likes']}'),
                    const SizedBox(width: 16),
                    _buildEngagementItem(Icons.chat_bubble_outline, '${post['comments']}'),
                    const SizedBox(width: 16),
                    _buildEngagementItem(Icons.visibility, '${post['views']}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementItem(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF65676B)),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF65676B),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _showBookingSheet,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1877F2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 20),
              SizedBox(width: 8),
              Text(
                'Book Consultation - ₹500 onwards',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingSheet({Map<String, dynamic>? preselectedService}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4E6EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Book Consultation',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF050505),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Choose consultation type:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF050505),
                ),
              ),
              const SizedBox(height: 12),
              _buildBookingOption(Icons.phone, 'Voice Call', '₹500', '30 min'),
              _buildBookingOption(Icons.videocam, 'Video Call', '₹800', '30 min'),
              _buildBookingOption(Icons.chat_bubble_outline, 'Chat', '₹300', 'per session'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Continue to Payment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingOption(IconData icon, String title, String price, String duration) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE4E6EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1877F2)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF050505),
              ),
            ),
          ),
          Text(
            '$price/$duration',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1877F2),
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

