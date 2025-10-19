import 'package:flutter/material.dart';

/// Device mockup widget that displays a phone frame with custom content
class DeviceMockupWidget extends StatelessWidget {
  final Widget child;
  final double? maxHeight;
  final Color borderColor;
  final Color backgroundColor;
  final double borderRadius;
  final double borderWidth;

  const DeviceMockupWidget({
    super.key,
    required this.child,
    this.maxHeight,
    this.borderColor = Colors.white,
    this.backgroundColor = const Color(0xFF1A1A1A),
    this.borderRadius = 32.0,
    this.borderWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final deviceHeight = maxHeight ?? screenHeight * 0.55;

    return Container(
      constraints: BoxConstraints(
        maxHeight: deviceHeight,
        maxWidth: deviceHeight * 0.46, // ~9:19.5 aspect ratio
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 48,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        child: child,
      ),
    );
  }
}

/// Gemini-style chat interface mockup
class GeminiChatMockup extends StatelessWidget {
  const GeminiChatMockup({super.key});

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
                        'Gemini',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '2.5 Flash',
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
                    'Hello, Elisa',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Talk Live button
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
                            color: const Color(0xFF4285F4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.graphic_eq,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Talk Live about this',
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
                        // Thumbnail
                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF404040),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.pets,
                              size: 32,
                              color: Color(0xFF89B4F8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Have me posing with a lot of puppies all over this room',
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
                              const Icon(Icons.image, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              const Text(
                                'Image',
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



