import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/live_stream_model.dart';

class LiveControlsOverlay extends StatelessWidget {
  final LiveStreamModel stream;
  final VoidCallback onTogglePause;
  final VoidCallback onEndStream;

  const LiveControlsOverlay({
    super.key,
    required this.stream,
    required this.onTogglePause,
    required this.onEndStream,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stream Stats
          _buildStreamStats(),
          const SizedBox(height: 16),
          
          // Control Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildControlButton(
                icon: Icons.pause,
                label: 'Pause',
                onTap: onTogglePause,
                color: Colors.orange,
              ),
              const SizedBox(width: 12),
              _buildControlButton(
                icon: Icons.stop,
                label: 'End',
                onTap: onEndStream,
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreamStats() {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              '${stream.viewerCount} viewers',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite,
              color: Colors.red.withOpacity(0.8),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              '${stream.likes} likes',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: Colors.blue.withOpacity(0.8),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              '${stream.commentsCount} comments',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
