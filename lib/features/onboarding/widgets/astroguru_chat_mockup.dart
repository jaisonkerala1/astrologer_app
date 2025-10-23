import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/services/language_service.dart';

/// AstroGuru chat interface mockup for onboarding
/// Shows healing and helping platform features
class AstroGuruChatMockup extends StatelessWidget {
  const AstroGuruChatMockup({super.key});

  @override
  Widget build(BuildContext context) {
    final isHindi = Provider.of<LanguageService>(context).isHindi;
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: const Color(0xFF1A1A1A),
            child: Row(
              children: [
                const Icon(Icons.menu, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'AstroGuru',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        isHindi ? 'उपचार और मदद' : 'Heal & Help',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 10,
                  backgroundColor: const Color(0xFF4285F4),
                  child: const Icon(Icons.person, size: 11, color: Colors.white),
                ),
              ],
            ),
          ),
          
          // Chat content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Text(
                    isHindi ? 'स्वागत, गुरु' : 'Welcome, Guru',
                    style: const TextStyle(
                      color: Color(0xFF4285F4),
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 16),
                  
                  // View consultations button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFF34A853),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.calendar_today,
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          isHindi ? 'परामर्श देखें' : 'View consultations',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 400.ms)
                    .then(delay: 600.ms)
                    .animate(onPlay: (controller) => controller.repeat())
                    .scale(
                      duration: 2500.ms,
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.03, 1.03),
                      curve: Curves.easeInOut,
                    )
                    .then()
                    .scale(
                      duration: 2500.ms,
                      begin: const Offset(1.03, 1.03),
                      end: const Offset(1.0, 1.0),
                      curve: Curves.easeInOut,
                    ),
                  const SizedBox(height: 16),
                  
                  // Message card
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFF404040),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.volunteer_activism,
                              size: 28,
                              color: const Color(0xFF89B4F8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isHindi 
                              ? 'अपने मार्गदर्शन की तलाश करने वाले अनुयायियों से जुड़ें। बुकिंग प्रबंधित करें, परामर्श करें, और अपनी आध्यात्मिक प्रथा का निर्माण करें'
                              : 'Connect with followers seeking your guidance. Manage bookings, conduct consultations, and build your spiritual practice.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 600.ms).slideY(begin: 0.3, end: 0),
                  
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}









