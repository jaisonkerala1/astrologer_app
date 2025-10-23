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

class _UserProfileScreenState extends State<UserProfileScreen> {
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
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                
                // Header Card
                _buildHeaderCard(),
                const SizedBox(height: 12),
                
                // Action Buttons
                _buildActionButtons(),
                const SizedBox(height: 12),
                
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
                const SizedBox(height: 12),
                
                // Recent History
                _buildHistorySection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard() {
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
        children: [
          // Profile Picture
          ProfileAvatarWidget(
            imagePath: null,
            radius: 50,
            fallbackText: 'PS',
            backgroundColor: const Color(0xFF7C3AED).withOpacity(0.1),
            textColor: const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 16),
          
          // Name and Age
          Text(
            '${_mockUser['name']}, ${_mockUser['age']}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          
          // Gender and Location
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 16, color: Color(0xFF6B6B8D)),
              const SizedBox(width: 4),
              Text(
                _mockUser['gender'],
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B6B8D),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF6B6B8D)),
              const SizedBox(width: 4),
              Text(
                _mockUser['location'],
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B6B8D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Follower Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, size: 14, color: Color(0xFF7C3AED)),
                const SizedBox(width: 6),
                Text(
                  'Follower since ${_mockUser['followerSince']}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7C3AED),
                  ),
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
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
}

