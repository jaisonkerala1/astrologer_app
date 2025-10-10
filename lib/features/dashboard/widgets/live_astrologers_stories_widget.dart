import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import 'live_astrologer_circle_widget.dart';
import '../../live/screens/live_stream_viewer_screen.dart';
import '../../live/models/live_stream_model.dart';
import '../../live/services/live_stream_service.dart';

class LiveAstrologersStoriesWidget extends StatelessWidget {
  const LiveAstrologersStoriesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate responsive container height
    // Small screens get compact height, larger screens get comfortable height
    final double containerHeight = screenWidth < 360 
        ? 116.0  // Small screens - reduced to match smaller circle size
        : screenWidth < 400 
            ? 128.0  // Medium screens
            : 140.0;  // Large screens
    
    // Calculate responsive font sizes
    final double titleFontSize = screenWidth < 360 ? 14.0 : 16.0;
    final double buttonFontSize = screenWidth < 360 ? 11.0 : 12.0;
    
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          height: containerHeight,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with "Live Now" title
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Live Now',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: themeService.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: titleFontSize,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        // Navigate to all live streams
                        HapticFeedback.lightImpact();
                        Navigator.pushNamed(context, '/live-streams');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeService.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: themeService.primaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: themeService.primaryColor,
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Horizontal scrolling live astrologers
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  itemCount: _getMockLiveAstrologers().length,
                  itemBuilder: (context, index) {
                    final astrologer = _getMockLiveAstrologers()[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: LiveAstrologerCircleWidget(
                        astrologer: astrologer,
                        onTap: () => _handleAstrologerTap(context, astrologer),
                        onLongPress: () => _handleAstrologerLongPress(context, astrologer),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleAstrologerTap(BuildContext context, MockLiveAstrologer astrologer) async {
    HapticFeedback.lightImpact();
    
    try {
      // Convert MockLiveAstrologer to LiveStreamModel
      final liveStream = LiveStreamModel(
        id: astrologer.id,
        astrologerId: astrologer.id,
        astrologerName: astrologer.name,
        astrologerProfilePicture: astrologer.profilePicture,
        astrologerSpecialty: astrologer.specialty,
        title: '${astrologer.specialty} Session',
        description: 'Join me for a live ${astrologer.specialty.toLowerCase()} session!',
        viewerCount: astrologer.viewerCount,
        isLive: astrologer.isLive,
        startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        thumbnailUrl: astrologer.thumbnailUrl,
        tags: [astrologer.specialty.toLowerCase()],
        rating: 4.5 + (astrologer.viewerCount % 50) / 10, // Mock rating
        totalSessions: 100 + astrologer.viewerCount,
        isVerified: astrologer.viewerCount > 200,
      );
      
      // Navigate to live stream viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LiveStreamViewerScreen(
            liveStream: liveStream,
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join live stream: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleAstrologerLongPress(BuildContext context, MockLiveAstrologer astrologer) {
    HapticFeedback.mediumImpact();
    // TODO: Show profile preview modal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${astrologer.name} - ${astrologer.specialty}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  List<MockLiveAstrologer> _getMockLiveAstrologers() {
    return [
      MockLiveAstrologer(
        id: '1',
        name: 'Priya Sharma',
        profilePicture: null,
        specialty: 'Vedic Astrology',
        viewerCount: 234,
        isLive: true,
        liveStreamUrl: '',
        thumbnailUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=400&h=400&fit=crop&crop=face',
      ),
      MockLiveAstrologer(
        id: '2',
        name: 'Raj Kumar',
        profilePicture: null,
        specialty: 'Tarot Reading',
        viewerCount: 189,
        isLive: true,
        liveStreamUrl: '',
        thumbnailUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face',
      ),
      MockLiveAstrologer(
        id: '3',
        name: 'Anita Singh',
        profilePicture: null,
        specialty: 'Numerology',
        viewerCount: 156,
        isLive: true,
        liveStreamUrl: '',
        thumbnailUrl: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face',
      ),
      MockLiveAstrologer(
        id: '4',
        name: 'Vikram Joshi',
        profilePicture: null,
        specialty: 'Palmistry',
        viewerCount: 98,
        isLive: true,
        liveStreamUrl: '',
        thumbnailUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop&crop=face',
      ),
      MockLiveAstrologer(
        id: '5',
        name: 'Sita Devi',
        profilePicture: null,
        specialty: 'Crystal Healing',
        viewerCount: 312,
        isLive: true,
        liveStreamUrl: '',
        thumbnailUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop&crop=face',
      ),
      MockLiveAstrologer(
        id: '6',
        name: 'Arjun Patel',
        profilePicture: null,
        specialty: 'Vastu Shastra',
        viewerCount: 67,
        isLive: true,
        liveStreamUrl: '',
        thumbnailUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop&crop=face',
      ),
      MockLiveAstrologer(
        id: '7',
        name: 'Meera Jain',
        profilePicture: null,
        specialty: 'Palmistry',
        viewerCount: 145,
        isLive: true,
        liveStreamUrl: '',
        thumbnailUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=400&fit=crop&crop=face',
      ),
      MockLiveAstrologer(
        id: '8',
        name: 'Krishna Das',
        profilePicture: null,
        specialty: 'Vedic Remedies',
        viewerCount: 278,
        isLive: true,
        liveStreamUrl: '',
        thumbnailUrl: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400&h=400&fit=crop&crop=face',
      ),
    ];
  }
}

// Mock data class
class MockLiveAstrologer {
  final String id;
  final String name;
  final String? profilePicture;
  final String specialty;
  final int viewerCount;
  final bool isLive;
  final String liveStreamUrl;
  final String thumbnailUrl;

  MockLiveAstrologer({
    required this.id,
    required this.name,
    this.profilePicture,
    required this.specialty,
    required this.viewerCount,
    required this.isLive,
    required this.liveStreamUrl,
    required this.thumbnailUrl,
  });
}
