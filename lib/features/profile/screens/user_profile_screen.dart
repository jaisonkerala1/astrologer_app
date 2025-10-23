import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/profile_avatar_widget.dart';

/// User/Follower Profile Screen - Instagram-inspired design
/// Shows detailed information about a user/follower from astrologer's perspective
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Mock user data
  final Map<String, dynamic> _mockUser = {
    'name': 'Priya Sharma',
    'age': 28,
    'gender': 'Female',
    'location': 'Mumbai, Maharashtra',
    'sunSign': 'Aries ♈',
    'moonSign': 'Cancer ♋',
    'risingSign': 'Leo ♌',
    'birthDate': 'March 21, 1995',
    'birthTime': '06:30 AM',
    'birthPlace': 'Mumbai, India',
    'totalConsultations': 12,
    'lastConsultation': '3 days ago',
    'preferredMethod': 'Video Call',
    'followerSince': 'January 10, 2024',
    'totalSpent': 8500,
    'avgDuration': '35 mins',
    'phone': '+91 98765 43210',
    'email': 'priya.sharma@example.com',
    'about': 'Looking for career guidance and relationship advice. Interested in understanding my life path through Vedic astrology.',
    'concerns': ['Career Growth', 'Relationship', 'Health'],
  };

  // Mock discussion posts from user
  final List<Map<String, dynamic>> _mockPosts = [
    {
      'title': 'Seeking Career Guidance',
      'content': 'I am at a crossroads in my career and would love some astrological insight on the best path forward...',
      'date': '2 days ago',
      'likes': 12,
      'comments': 5,
      'category': 'Career',
    },
    {
      'title': 'Understanding My Birth Chart',
      'content': 'Can someone help me understand what my Mars placement means for my relationships?',
      'date': '1 week ago',
      'likes': 8,
      'comments': 3,
      'category': 'Astrology',
    },
    {
      'title': 'Best Time for New Beginnings',
      'content': 'Planning to start a new business. What are the auspicious dates this month?',
      'date': '2 weeks ago',
      'likes': 15,
      'comments': 7,
      'category': 'Business',
    },
  ];

  // Mock notes
  String _astrologerNotes = 'Client is going through career transition. Recommended wearing Ruby gemstone. Saturn transit affecting 10th house. Suggest follow-up consultation in April 2024.';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'User Profile',
              style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Color(0xFF6B6B8D)),
                onPressed: () {},
              ),
            ],
          ),
          body: Column(
            children: [
              // Header Card
              _buildHeaderCard(),
              const SizedBox(height: 8),
              
              // Action Buttons
              _buildActionButtons(),
              const SizedBox(height: 8),
              
              // Tab Bar
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF7C3AED),
                  unselectedLabelColor: const Color(0xFF6B6B8D),
                  indicatorColor: const Color(0xFF7C3AED),
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Posts'),
                    Tab(text: 'History'),
                    Tab(text: 'Notes'),
                  ],
                ),
              ),
              
              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildPostsTab(),
                    _buildHistoryTab(),
                    _buildNotesTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Profile Picture - Smaller
          ProfileAvatarWidget(
            imagePath: null,
            radius: 36,
            fallbackText: 'PS',
            backgroundColor: const Color(0xFF7C3AED).withOpacity(0.1),
            textColor: const Color(0xFF7C3AED),
          ),
          const SizedBox(width: 12),
          
          // Name and Info - Compact
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${_mockUser['name']}, ${_mockUser['age']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Color(0xFF6B6B8D)),
                    const SizedBox(width: 4),
                    Text(
                      _mockUser['gender'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B6B8D),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF6B6B8D)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _mockUser['location'],
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B6B8D),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.favorite, size: 14, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 4),
                    Text(
                      'Since ${_mockUser['followerSince']}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7C3AED),
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

  Widget _buildActionButtons() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(Icons.phone, 'Call', const Color(0xFF34A853)),
          _buildActionButton(Icons.chat_bubble_outline, 'Chat', const Color(0xFF4285F4)),
          _buildActionButton(Icons.videocam, 'Video', const Color(0xFFEA4335)),
          _buildActionButton(Icons.calendar_today, 'Schedule', const Color(0xFF7C3AED)),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAstrologicalInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF7C3AED), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Astrological Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Signs
          Row(
            children: [
              Expanded(child: _buildSignItem('Sun', _mockUser['sunSign'])),
              Expanded(child: _buildSignItem('Moon', _mockUser['moonSign'])),
              Expanded(child: _buildSignItem('Rising', _mockUser['risingSign'])),
            ],
          ),
          const SizedBox(height: 16),
          
          // Divider
          Divider(color: const Color(0xFF6B6B8D).withOpacity(0.2)),
          const SizedBox(height: 16),
          
          // Birth Details
          const Text(
            'Birth Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.calendar_today, 'Date', _mockUser['birthDate']),
          _buildInfoRow(Icons.access_time, 'Time', _mockUser['birthTime']),
          _buildInfoRow(Icons.location_on, 'Place', _mockUser['birthPlace']),
          const SizedBox(height: 16),
          
          // View Chart Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.stars, size: 18),
              label: const Text('View Birth Chart'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7C3AED),
                side: const BorderSide(color: Color(0xFF7C3AED)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B6B8D),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6B6B8D)),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B6B8D),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              const Icon(Icons.bar_chart, color: Color(0xFF7C3AED), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Consultation Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Total', '${_mockUser['totalConsultations']}', Icons.event_note),
              ),
              Expanded(
                child: _buildStatItem('Last', _mockUser['lastConsultation'], Icons.schedule),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Method', _mockUser['preferredMethod'], Icons.videocam),
              ),
              Expanded(
                child: _buildStatItem('Duration', _mockUser['avgDuration'], Icons.timer),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF34A853).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Spent',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF34A853),
                  ),
                ),
                Text(
                  '₹${_mockUser['totalSpent']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF34A853),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF6B6B8D)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B6B8D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Row(
            children: [
              Icon(Icons.description_outlined, color: Color(0xFF7C3AED), size: 20),
              SizedBox(width: 8),
              Text(
                'About',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _mockUser['about'],
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B6B8D),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          
          const Text(
            'Current Concerns',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (_mockUser['concerns'] as List).map((concern) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  concern,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Row(
            children: [
              Icon(Icons.contact_phone_outlined, color: Color(0xFF7C3AED), size: 20),
              SizedBox(width: 8),
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildContactRow(Icons.phone, _mockUser['phone']),
          const SizedBox(height: 8),
          _buildContactRow(Icons.email, _mockUser['email']),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6B6B8D)),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history, color: Color(0xFF7C3AED), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Recent Consultations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildHistoryItem(
            'March 15, 2024',
            'Video Call',
            '45 mins',
            '₹800',
            Icons.videocam,
            const Color(0xFFEA4335),
          ),
          const SizedBox(height: 12),
          _buildHistoryItem(
            'March 1, 2024',
            'Phone Call',
            '30 mins',
            '₹500',
            Icons.phone,
            const Color(0xFF34A853),
          ),
          const SizedBox(height: 12),
          _buildHistoryItem(
            'February 20, 2024',
            'Chat',
            '20 mins',
            '₹300',
            Icons.chat_bubble_outline,
            const Color(0xFF4285F4),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String date, String type, String duration, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$date • $duration',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B6B8D),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF34A853),
            ),
          ),
        ],
      ),
    );
  }

  // Tab Views
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          // Astrological Info Card
          _buildAstrologicalInfoCard(),
          const SizedBox(height: 12),
          
          // Stats Card
          _buildStatsCard(),
          const SizedBox(height: 12),
          
          // About Section
          _buildAboutCard(),
          const SizedBox(height: 12),
          
          // Contact Info Card
          _buildContactCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    return _mockPosts.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.post_add,
                  size: 64,
                  color: const Color(0xFF6B6B8D).withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No posts yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B6B8D),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'User hasn\'t posted in discussions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B6B8D),
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: _mockPosts.length,
            itemBuilder: (context, index) {
              final post = _mockPosts[index];
              return _buildPostCard(post);
            },
          );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Category and Date
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  post['category'],
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                post['date'],
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B6B8D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Title
          Text(
            post['title'],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          
          // Content
          Text(
            post['content'],
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B6B8D),
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          
          // Engagement Row
          Row(
            children: [
              Icon(
                Icons.favorite_border,
                size: 18,
                color: const Color(0xFF6B6B8D),
              ),
              const SizedBox(width: 4),
              Text(
                '${post['likes']}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B6B8D),
                ),
              ),
              const SizedBox(width: 20),
              Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: const Color(0xFF6B6B8D),
              ),
              const SizedBox(width: 4),
              Text(
                '${post['comments']} comments',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B6B8D),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('View Post'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _buildHistorySection(),
      ],
    );
  }

  Widget _buildNotesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notes Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                Row(
                  children: [
                    const Icon(Icons.note_outlined, color: Color(0xFF7C3AED), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Private Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      color: const Color(0xFF7C3AED),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _astrologerNotes,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A2E),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Tags Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                Row(
                  children: [
                    const Icon(Icons.label_outline, color: Color(0xFF7C3AED), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTag('Career Transition'),
                    _buildTag('Gemstone Recommended'),
                    _buildTag('Follow-up Needed'),
                    _buildTag('Saturn Transit'),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Tag'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF7C3AED),
                    side: const BorderSide(color: Color(0xFF7C3AED)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Reminders Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                Row(
                  children: [
                    const Icon(Icons.notifications_outlined, color: Color(0xFF7C3AED), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Reminders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildReminderItem('Follow-up consultation', 'April 15, 2024'),
                _buildReminderItem('Check Ruby gemstone feedback', 'April 1, 2024'),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Reminder'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF7C3AED),
                    side: const BorderSide(color: Color(0xFF7C3AED)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.close,
              size: 14,
              color: Color(0xFF7C3AED),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderItem(String title, String date) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.alarm, size: 18, color: Color(0xFF7C3AED)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B6B8D),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 18),
            color: const Color(0xFF6B6B8D),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

