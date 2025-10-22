import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/services/language_service.dart';

/// Community growth mockup for onboarding
/// Shows discussions, live streaming, and community features
class CommunityGrowthMockup extends StatelessWidget {
  const CommunityGrowthMockup({super.key});

  @override
  Widget build(BuildContext context) {
    final isHindi = Provider.of<LanguageService>(context).isHindi;
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHindi ? 'समुदाय' : 'Community',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isHindi ? 'साथ विकसित हों' : 'Grow Together',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4444),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 18),
          
          // Discussion card - Clean & Minimal
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with avatar
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4285F4),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'D',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dr. Sharma',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                          Text(
                            isHindi ? '2 घंटे पहले' : '2h ago',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 10,
                            ),
                          ).animate().fadeIn(duration: 400.ms, delay: 350.ms),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Title
                Text(
                  isHindi ? 'बुध वक्री चर्चा' : 'Mercury Retrograde Discussion',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
                const SizedBox(height: 6),
                // Description
                Text(
                  isHindi 
                      ? 'बुध वक्री प्रभावों पर अपनी अंतर्दृष्टि साझा करें...'
                      : 'Share your insights on Mercury retrograde effects...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
                const SizedBox(height: 12),
                // Stats - Clean row
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: Colors.white.withOpacity(0.5), size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '24',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.favorite_border, color: Colors.white.withOpacity(0.5), size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '56',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Live streaming section
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E40AF), Color(0xFF4285F4)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.play_circle_filled, color: Colors.white, size: 20)
                    .animate(onPlay: (controller) => controller.repeat())
                    .scale(
                      duration: 2000.ms,
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.12, 1.12),
                      curve: Curves.easeInOut,
                    )
                    .then()
                    .scale(
                      duration: 2000.ms,
                      begin: const Offset(1.12, 1.12),
                      end: const Offset(1.0, 1.0),
                      curve: Curves.easeInOut,
                    ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start Live Stream',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Connect with seekers',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 700.ms).slideY(begin: 0.2, end: 0),
          
          const Spacer(),
        ],
      ),
    );
  }
}





