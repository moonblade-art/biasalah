import 'package:flutter/material.dart';

class SafeGradient {
  /// Creates a safe LinearGradient that ensures at least 2 colors
  /// If only one color is provided, it creates a gradient with the same color twice
  /// If null colors are provided, it uses fallback colors
  static LinearGradient create({
    required List<Color?> colors,
    AlignmentGeometry begin = Alignment.topCenter,
    AlignmentGeometry end = Alignment.bottomCenter,
    List<double>? stops,
    TileMode tileMode = TileMode.clamp,
    Color fallbackColor = const Color(0xFF3E5F44), // Default primary color
  }) {
    // Filter out null colors and ensure we have valid colors
    List<Color> validColors = colors
        .where((color) => color != null)
        .cast<Color>()
        .toList();
    
    // If no valid colors, use fallback
    if (validColors.isEmpty) {
      validColors = [fallbackColor, fallbackColor];
    }
    // If only one color, duplicate it to meet LinearGradient requirement
    else if (validColors.length == 1) {
      validColors = [validColors[0], validColors[0]];
    }
    
    return LinearGradient(
      begin: begin,
      end: end,
      colors: validColors,
      stops: stops,
      tileMode: tileMode,
    );
  }
  
  /// Creates a safe BoxDecoration with gradient
  static BoxDecoration createDecoration({
    required List<Color?> colors,
    AlignmentGeometry begin = Alignment.topCenter,
    AlignmentGeometry end = Alignment.bottomCenter,
    List<double>? stops,
    TileMode tileMode = TileMode.clamp,
    Color fallbackColor = const Color(0xFF3E5F44),
    BorderRadius? borderRadius,
    Border? border,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: create(
        colors: colors,
        begin: begin,
        end: end,
        stops: stops,
        tileMode: tileMode,
        fallbackColor: fallbackColor,
      ),
      borderRadius: borderRadius,
      border: border,
      boxShadow: boxShadow,
    );
  }
  
  /// Helper method to create a simple two-color gradient
  static LinearGradient simple({
    required Color startColor,
    required Color endColor,
    AlignmentGeometry begin = Alignment.topCenter,
    AlignmentGeometry end = Alignment.bottomCenter,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [startColor, endColor],
    );
  }
}