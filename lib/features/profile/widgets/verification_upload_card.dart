import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/theme/services/theme_service.dart';

/// Reusable upload card widget for verification documents
class VerificationUploadCard extends StatelessWidget {
  final File? image;
  final Function(File) onImagePicked;
  final VoidCallback onImageRemoved;
  final ThemeService themeService;
  final String documentType;

  const VerificationUploadCard({
    super.key,
    required this.image,
    required this.onImagePicked,
    required this.onImageRemoved,
    required this.themeService,
    this.documentType = 'document',
  });

  Future<void> _showImageSourceDialog(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: themeService.cardColor,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: themeService.borderColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Upload $documentType',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeService.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(
                  Icons.photo_camera,
                  color: themeService.primaryColor,
                ),
                title: Text(
                  'Take Photo',
                  style: TextStyle(color: themeService.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: themeService.primaryColor,
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(color: themeService.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(context, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedImage != null) {
        onImagePicked(File(pickedImage.path));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final horizontalPadding = screenWidth > 600 ? 48.0 : 24.0;
    final cardHeight = isSmallScreen ? 200.0 : 240.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        height: cardHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: image == null
              ? _buildUploadArea(context)
              : _buildImagePreview(context),
        ),
      ),
    );
  }

  Widget _buildUploadArea(BuildContext context) {
    return InkWell(
      onTap: () => _showImageSourceDialog(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: themeService.backgroundColor,
          border: Border.all(
            color: themeService.primaryColor.withOpacity(0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: DashedBorderPainter(
          color: themeService.primaryColor.withOpacity(0.3),
          strokeWidth: 2,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 48,
                  color: themeService.primaryColor.withOpacity(0.6),
                ),
                const SizedBox(height: 12),
                Text(
                  'Add Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: themeService.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Camera or Gallery',
                  style: TextStyle(
                    fontSize: 13,
                    color: themeService.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    return Stack(
      children: [
        // Full image
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            image!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),

        // Top gradient overlay
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Bottom gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Action buttons at top right
        Positioned(
          top: 12,
          right: 12,
          child: Row(
            children: [
              _buildActionButton(
                Icons.edit,
                () => _showImageSourceDialog(context),
                Colors.white.withOpacity(0.9),
                iconColor: themeService.textPrimary,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                Icons.close,
                onImageRemoved,
                Colors.white.withOpacity(0.9),
                iconColor: Colors.red,
              ),
            ],
          ),
        ),

        // Success indicator at bottom
        Positioned(
          bottom: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'Document uploaded',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    VoidCallback onTap,
    Color backgroundColor, {
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

/// Custom painter for dashed border
class DashedBorderPainter extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  const DashedBorderPainter({
    super.key,
    required this.child,
    required this.color,
    this.strokeWidth = 2,
    this.dashWidth = 8,
    this.dashSpace = 4,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderCustomPainter(
        color: color,
        strokeWidth: strokeWidth,
        dashWidth: dashWidth,
        dashSpace: dashSpace,
      ),
      child: child,
    );
  }
}

class _DashedBorderCustomPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  _DashedBorderCustomPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ));

    final dashPath = _createDashedPath(path);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source) {
    final Path dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double length = dashWidth;
        final Path extractPath = metric.extractPath(distance, distance + length);
        dest.addPath(extractPath, Offset.zero);
        distance += length + dashSpace;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(_DashedBorderCustomPainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        dashWidth != oldDelegate.dashWidth ||
        dashSpace != oldDelegate.dashSpace;
  }
}

