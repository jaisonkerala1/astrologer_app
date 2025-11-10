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
    final cardHeight = isSmallScreen ? 180.0 : 220.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          color: themeService.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: image != null
                ? Colors.green.withOpacity(0.5)
                : themeService.borderColor,
            width: 2,
          ),
          boxShadow: image != null
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
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
      child: Container(
        color: themeService.primaryColor.withOpacity(0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 48,
              color: themeService.primaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              'Tap to upload',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: themeService.primaryColor,
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
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image
        Image.file(
          image!,
          fit: BoxFit.cover,
        ),

        // Gradient overlay for better button visibility
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Action buttons
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              _buildActionButton(
                Icons.edit,
                () => _showImageSourceDialog(context),
                themeService.primaryColor,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                Icons.delete,
                onImageRemoved,
                Colors.red,
              ),
            ],
          ),
        ),

        // Success checkmark
        Positioned(
          bottom: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
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
                  'Uploaded',
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

  Widget _buildActionButton(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

