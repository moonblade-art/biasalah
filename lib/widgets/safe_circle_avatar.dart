// lib/widgets/safe_circle_avatar.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A safe CircleAvatar widget that properly handles null/empty image URLs
/// and prevents the CircleAvatar assertion failure that causes mouse tracker spam
class SafeCircleAvatar extends StatelessWidget {
  final double radius;
  final String? imageUrl;
  final String? fallbackText;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;

  const SafeCircleAvatar({
    super.key,
    required this.radius,
    this.imageUrl,
    this.fallbackText,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    // Safe validation of image URL
    final hasValidUrl = imageUrl != null && 
                       imageUrl!.isNotEmpty && 
                       (imageUrl!.startsWith('http') || imageUrl!.startsWith('https'));
    
    // Safe fallback text
    final displayText = fallbackText?.isNotEmpty == true 
        ? fallbackText![0].toUpperCase() 
        : '?';

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey[300],
      // CRITICAL: Only set backgroundImage when URL is valid
      // This prevents the assertion failure: backgroundImage != null || onBackgroundImageError == null
      backgroundImage: hasValidUrl ? NetworkImage(imageUrl!) : null,
      // CRITICAL: Only set onBackgroundImageError when backgroundImage is not null
      onBackgroundImageError: hasValidUrl ? (exception, stackTrace) {
        debugPrint('Failed to load profile image: $exception');
        // Don't call setState to avoid rebuild loops
      } : null,
      // CRITICAL: Only show child when there's no background image
      child: !hasValidUrl ? Text(
        displayText,
        style: GoogleFonts.poppins(
          fontSize: fontSize ?? (radius * 0.7),
          color: textColor ?? Colors.grey[700],
          fontWeight: fontWeight ?? FontWeight.w600,
        ),
      ) : null,
    );
  }
}

/// Extension method for easy usage
extension SafeCircleAvatarExtension on Widget {
  /// Create a safe CircleAvatar from user profile data
  static Widget fromUserProfile({
    required double radius,
    String? profilePictureUrl,
    String? fullName,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return SafeCircleAvatar(
      radius: radius,
      imageUrl: profilePictureUrl,
      fallbackText: fullName,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }
}