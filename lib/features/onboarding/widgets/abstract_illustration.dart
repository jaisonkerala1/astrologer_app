import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Abstract playful illustration with organic shapes and device mockup
/// Based on Android's onboarding design with floating decorative elements
class AbstractIllustration extends StatelessWidget {
  const AbstractIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final illustrationHeight = math.min(screenHeight * 0.5, 400.0);

    return SizedBox(
      height: illustrationHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background decorative shapes
          Positioned(
            left: 20,
            top: 60,
            child: _buildFloatingShape(
              color: const Color(0xFFF8DC89), // Yellow daisy
              size: 120,
              type: ShapeType.flower,
            ),
          ),
          Positioned(
            left: 40,
            top: 10,
            child: _buildFloatingShape(
              color: const Color(0xFFF8A5A5), // Pink blob
              size: 80,
              type: ShapeType.blob,
            ),
          ),
          Positioned(
            right: 30,
            top: 40,
            child: _buildFloatingShape(
              color: const Color(0xFF4DA6FF), // Blue shape
              size: 50,
              type: ShapeType.blob,
            ),
          ),
          Positioned(
            right: 60,
            top: 120,
            child: _buildFloatingShape(
              color: const Color(0xFF4DA6FF), // Blue music note
              size: 60,
              type: ShapeType.musicNote,
            ),
          ),
          Positioned(
            right: 20,
            bottom: 80,
            child: _buildFloatingShape(
              color: const Color(0xFF89B4F8), // Light blue
              size: 90,
              type: ShapeType.blob,
            ),
          ),
          Positioned(
            left: 30,
            bottom: 40,
            child: _buildFloatingShape(
              color: const Color(0xFF89F8B4), // Green blob
              size: 70,
              type: ShapeType.heart,
            ),
          ),
          
          // Center device mockup
          Center(
            child: Container(
              width: 180,
              height: 340,
              decoration: BoxDecoration(
                color: const Color(0xFF4A4A4A),
                borderRadius: BorderRadius.circular(48),
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 48,
                    offset: const Offset(0, 24),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.android,
                  size: 48,
                  color: const Color(0xFF34A853), // Android green
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingShape({
    required Color color,
    required double size,
    required ShapeType type,
  }) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ShapePainter(color: color, type: type),
    );
  }
}

enum ShapeType { blob, flower, musicNote, heart }

class _ShapePainter extends CustomPainter {
  final Color color;
  final ShapeType type;

  _ShapePainter({required this.color, required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (type) {
      case ShapeType.blob:
        _drawBlob(canvas, size, paint);
        break;
      case ShapeType.flower:
        _drawFlower(canvas, size, paint);
        break;
      case ShapeType.musicNote:
        _drawMusicNote(canvas, size, paint);
        break;
      case ShapeType.heart:
        _drawHeart(canvas, size, paint);
        break;
    }
  }

  void _drawBlob(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    path.moveTo(cx + r * 0.8, cy);
    path.cubicTo(
      cx + r, cy - r * 0.5,
      cx + r * 0.5, cy - r,
      cx, cy - r * 0.8,
    );
    path.cubicTo(
      cx - r * 0.5, cy - r,
      cx - r, cy - r * 0.5,
      cx - r * 0.8, cy,
    );
    path.cubicTo(
      cx - r, cy + r * 0.5,
      cx - r * 0.5, cy + r,
      cx, cy + r * 0.8,
    );
    path.cubicTo(
      cx + r * 0.5, cy + r,
      cx + r, cy + r * 0.5,
      cx + r * 0.8, cy,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawFlower(Canvas canvas, Size size, Paint paint) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 5;

    // Draw 8 petals
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4);
      final petalCx = cx + math.cos(angle) * r * 1.5;
      final petalCy = cy + math.sin(angle) * r * 1.5;
      canvas.drawCircle(Offset(petalCx, petalCy), r, paint);
    }

    // Draw center
    final centerPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 0.8, centerPaint);
  }

  void _drawMusicNote(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 6;

    // Note head
    canvas.drawCircle(Offset(cx - r, cy + r), r, paint);

    // Note stem
    final stemPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = r / 2;
    canvas.drawLine(
      Offset(cx - r + r * 0.8, cy + r),
      Offset(cx - r + r * 0.8, cy - r * 2),
      stemPaint,
    );

    // Note flag (curved)
    final flagPath = Path();
    flagPath.moveTo(cx - r + r * 0.8, cy - r * 2);
    flagPath.quadraticBezierTo(
      cx + r * 1.5, cy - r * 1.5,
      cx + r, cy - r,
    );
    canvas.drawPath(flagPath, stemPaint);
  }

  void _drawHeart(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 4;

    // Left lobe
    path.addOval(Rect.fromCircle(center: Offset(cx - r / 2, cy - r / 2), radius: r / 2));
    // Right lobe
    path.addOval(Rect.fromCircle(center: Offset(cx + r / 2, cy - r / 2), radius: r / 2));

    // Bottom point
    final bottomPath = Path();
    bottomPath.moveTo(cx - r, cy - r / 2);
    bottomPath.quadraticBezierTo(cx, cy + r, cx, cy + r);
    bottomPath.quadraticBezierTo(cx, cy + r, cx + r, cy - r / 2);
    
    path.addPath(bottomPath, Offset.zero);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



