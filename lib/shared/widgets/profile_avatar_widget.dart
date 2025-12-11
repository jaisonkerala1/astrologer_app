import 'package:flutter/material.dart';
import 'dart:io';
import '../../core/constants/api_constants.dart';

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
    final imageProvider = _getImageProvider();
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.white,
      backgroundImage: imageProvider,
      onBackgroundImageError: imageProvider != null ? (exception, stackTrace) {
        // Silent fail - fallback to text avatar
      } : null,
      child: imageProvider == null 
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
          imagePath!.startsWith('https://')) {
        // Full URL provided
        return NetworkImage(imagePath!);
      } else if (imagePath!.startsWith('/uploads/')) {
        // Relative path - construct full URL using ApiConstants
        final fullUrl = '${ApiConstants.baseUrl}$imagePath';
        return NetworkImage(fullUrl);
      } else {
        // Local file path
        return FileImage(File(imagePath!));
      }
    } catch (e) {
      return null;
    }
  }
}





