import 'package:flutter/material.dart';

/// AstroGuru chat interface mockup for onboarding
/// Shows healing and helping platform features
class AstroGuruChatMockup extends StatelessWidget {
  const AstroGuruChatMockup({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF1A1A1A),
            child: Row(
              children: [
                const Icon(Icons.menu, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AstroGuru',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Heal & Help',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF4285F4),
                  child: const Icon(Icons.person, size: 16, color: Colors.white),
                ),
              ],
            ),
          ),
          
          // Chat content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  const Text(
                    'Namaste, Seeker',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Heal button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF34A853),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.healing,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Start healing journey',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Message card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF404040),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.volunteer_activism,
                              size: 32,
                              color: const Color(0xFF89B4F8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Connect with astrologers who can guide you through life\'s challenges and help heal your spiritual journey',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Input area
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E40AF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.spa, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              const Text(
                                'Heal',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.close, size: 14, color: Colors.white),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF89B4F8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_upward, size: 16, color: Color(0xFF1A1A1A)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



