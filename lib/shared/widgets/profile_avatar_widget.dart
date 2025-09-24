import 'package:flutter/material.dart';
import 'dart:io';

class ProfileAvatarWidget extends StatelessWidget {
  final String? imagePath;
  final double radius;
  final String? fallbackText;
  final Color? backgroundColor;
  final Color? textColor;

  const ProfileAvatarWidget({
    super.key,
    this.imagePath,
    this.radius = 28,
    this.fallbackText,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.white,
      backgroundImage: _getImageProvider(),
      onBackgroundImageError: (exception, stackTrace) {
        print('🖼️ [PROFILE_AVATAR] Image loading error: $exception');
        print('🖼️ [PROFILE_AVATAR] Image path: $imagePath');
        print('🖼️ [PROFILE_AVATAR] This is expected for Railway ephemeral storage');
      },
      child: _getImageProvider() == null 
          ? Text(
              fallbackText ?? 'A',
              style: TextStyle(
                fontSize: radius * 0.6,
                fontWeight: FontWeight.bold,
                color: textColor ?? const Color(0xFF1E40AF),
              ),
            )
          : null,
    );
  }

  ImageProvider? _getImageProvider() {
    try {
      // Validate imagePath is not empty
      if (imagePath == null || imagePath!.isEmpty) {
        return null;
      }
      
      if (imagePath!.startsWith('http://') || 
          imagePath!.startsWith('https://') || 
          imagePath!.startsWith('/uploads/')) {
        // Network URL - construct full URL for Railway backend
        if (imagePath!.startsWith('/uploads/')) {
          final fullUrl = 'https://astrologerapp-production.up.railway.app$imagePath';
          print('🖼️ [PROFILE_AVATAR] Loading from Railway: $fullUrl');
          return NetworkImage(fullUrl);
        }
        return NetworkImage(imagePath!);
      } else {
        // Local file path
        return FileImage(File(imagePath!));
      }
    } catch (e) {
      print('🖼️ [PROFILE_AVATAR] Error creating image provider: $e');
      return null;
    }
  }
}





