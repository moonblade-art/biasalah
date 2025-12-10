// lib/widgets/safe_circle_avatar.dart

import 'package:flutter/material.dart';

/// Safe CircleAvatar with backward compatibility.
class SafeCircleAvatar extends StatelessWidget {
  final double radius;

  /// Field lama — tetap dipertahankan agar tidak error,
  /// meskipun sekarang tidak dipakai lagi.
  final String? fallbackText;

  final String? imageUrl;
  final Color? backgroundColor;
  final Color? iconColor;

  SafeCircleAvatar({
    super.key,
    required this.radius,
    this.imageUrl,
    this.fallbackText, // ← tetap ada agar tidak error
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasValidUrl = imageUrl != null &&
        imageUrl!.trim().isNotEmpty &&
        (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'));

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey[300],

      // Hanya load gambar jika URL valid
      backgroundImage: hasValidUrl ? NetworkImage(imageUrl!) : null,

      onBackgroundImageError:
          hasValidUrl ? (e, s) => debugPrint('Image load error: $e') : null,

      // Fallback: Icon person, bukan huruf / fallbackText
      child: !hasValidUrl
          ? Icon(
              Icons.person,
              size: radius * 0.9,
              color: iconColor ?? Colors.grey[700],
            )
          : null,
    );
  }
}
