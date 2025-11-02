import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/profile_avatar_widget.dart';
import '../models/client_model.dart';
import 'package:intl/intl.dart';

/// Client Detail Screen - Matches User Profile Design with Scroll Effects
/// Shows client information with consultation history
class ClientDetailScreen extends StatefulWidget {
  final ClientModel client;

  const ClientDetailScreen({
    super.key,
    required this.client,
  });

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  String _astrologerNotes = '';
  bool _showCompactHeader = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _showCompactHeader = _scrollController.offset > 100;
        });
      });
    _astrologerNotes = widget.client.lastNotes ?? 'No notes yet for this client.';
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
          body: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // App Bar
                SliverAppBar(
                  backgroundColor: Colors.white,
                  elevation: 0.5,
                  pinned: true,
                  expandedHeight: _showCompactHeader ? 56 : 210,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: AnimatedOpacity(
                    opacity: _showCompactHeader ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      widget.client.clientName,
                      style: const TextStyle(
                        color: Color(0xFF1A1A2E),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Color(0xFF6B6B8D)),
                      onPressed: () {},
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: AnimatedOpacity(
                      opacity: _showCompactHeader ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildHeaderCard(),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Tab Bar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    TabBar(
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
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildPostsTab(),
                _buildHistoryTab(),
                _buildNotesTab(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          // Profile Picture
          Stack(
            children: [
              ProfileAvatarWidget(
                imagePath: 'https://i.pravatar.cc/300?u=' + 
                    Uri.encodeComponent(widget.client.clientName),
                radius: 40,
                fallbackText: widget.client.initials,
                backgroundColor: widget.client.avatarColor.withOpacity(0.1),
                textColor: widget.client.avatarColor,
              ),
              if (widget.client.isVIP)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.star,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Name and Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.client.clientName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 14, color: Color(0xFF6B6B8D)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        widget.client.clientPhone,
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 4),
                    Text(
                      'Last: ${widget.client.lastConsultationText}',
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _showMessage('Opening schedule for ${widget.client.clientName}');
              },
              icon: const Icon(Icons.calendar_today, size: 18),
              label: const Text('Schedule'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1877F2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
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
              onPressed: () {
                _showAddNotesDialog();
              },
              icon: const Icon(Icons.note_add, size: 18),
              label: const Text('Add Notes'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF050505),
                side: const BorderSide(color: Color(0xFFCED0D4)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Astrology Info Card - NEW!
          _buildAstrologyInfoCard(),
          const SizedBox(height: 12),
          
          // Stats Card
          _buildStatsCard(),
          const SizedBox(height: 12),
          
          // Contact Info Card
          _buildContactCard(),
          const SizedBox(height: 12),
          
          // Additional Info
          _buildAdditionalInfoCard(),
        ],
      ),
    );
  }

  Widget _buildAstrologyInfoCard() {
    // Mock astrology data based on client
    final Map<String, String> astrologyData = {
      'Sun Sign': 'Aries ♈',
      'Moon Sign': 'Cancer ♋',
      'Rising Sign': 'Leo ♌',
    };

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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Astrological Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAstrologyItem(
                  'Sun Sign',
                  astrologyData['Sun Sign']!,
                  const Color(0xFFFF6B6B),
                ),
              ),
              Expanded(
                child: _buildAstrologyItem(
                  'Moon Sign',
                  astrologyData['Moon Sign']!,
                  const Color(0xFF4ECDC4),
                ),
              ),
              Expanded(
                child: _buildAstrologyItem(
                  'Rising Sign',
                  astrologyData['Rising Sign']!,
                  const Color(0xFFFFD93D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAstrologyItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value.split(' ')[1], // Get the emoji
            style: const TextStyle(fontSize: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF6B6B8D),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value.split(' ')[0], // Get the sign name
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
          const Text(
            'Client Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Sessions',
                  widget.client.totalConsultations.toString(),
                  Icons.event_note,
                  const Color(0xFF4285F4),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Completed',
                  widget.client.completedConsultations.toString(),
                  Icons.check_circle,
                  const Color(0xFF34A853),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Spent',
                  '₹${widget.client.totalSpent.toStringAsFixed(0)}',
                  Icons.account_balance_wallet,
                  const Color(0xFFFFB300),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Avg Duration',
                  '${widget.client.averageDuration}m',
                  Icons.timer,
                  const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
          if (widget.client.averageRating != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFB300), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Average Rating: ${widget.client.averageRating!.toStringAsFixed(1)} / 5.0',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFB300),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6B6B8D),
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.phone, 'Phone', widget.client.clientPhone),
          if (widget.client.clientEmail != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.email, 'Email', widget.client.clientEmail!),
          ],
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
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
          const Text(
            'Additional Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            widget.client.preferredTypeIcon,
            'Preferred Method',
            widget.client.preferredTypeDisplay,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.calendar_today,
            'First Consultation',
            DateFormat('MMM dd, yyyy').format(widget.client.firstConsultation),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.event,
            'Last Consultation',
            DateFormat('MMM dd, yyyy').format(widget.client.lastConsultation),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6B6B8D)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B6B8D),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostsTab() {
    // Mock discussion posts from client
    final List<Map<String, dynamic>> mockPosts = [
      {
        'title': 'Seeking Career Guidance',
        'content': 'I am at a crossroads in my career and would love some astrological insight on the best path forward. Should I take the new job offer?',
        'date': '2 days ago',
        'likes': 12,
        'comments': 5,
        'category': 'Career',
      },
      {
        'title': 'Understanding My Birth Chart',
        'content': 'Can someone help me understand what my Mars placement means for my relationships? I keep experiencing similar patterns.',
        'date': '1 week ago',
        'likes': 8,
        'comments': 3,
        'category': 'Astrology',
      },
      {
        'title': 'Best Time for New Beginnings',
        'content': 'Planning to start a new business venture. What are the most auspicious dates this month according to my chart?',
        'date': '2 weeks ago',
        'likes': 15,
        'comments': 7,
        'category': 'Business',
      },
    ];

    return mockPosts.isEmpty
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
                  'Client hasn\'t posted in discussions',
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
            itemCount: mockPosts.length,
            itemBuilder: (context, index) {
              final post = mockPosts[index];
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
              const Icon(
                Icons.favorite_border,
                size: 18,
                color: Color(0xFF6B6B8D),
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
              const Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: Color(0xFF6B6B8D),
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
                onPressed: () {
                  _showMessage('Opening discussion post...');
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text(
                  'View Post',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        final date = DateTime.now().subtract(Duration(days: index * 15));
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF34A853).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF34A853),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMM dd, yyyy').format(date),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.client.preferredTypeDisplay} • ${widget.client.averageDuration} min',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B6B8D),
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                '₹700',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF34A853),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
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
            const Text(
              'Your Private Notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Only you can see these notes',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B6B8D),
              ),
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
    );
  }

  void _showAddNotesDialog() {
    final controller = TextEditingController(text: _astrologerNotes);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Notes'),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Enter your notes about this client...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _astrologerNotes = controller.text;
                });
                Navigator.pop(context);
                _showMessage('Notes saved successfully');
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Tab Bar Delegate for Sticky Tabs
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
