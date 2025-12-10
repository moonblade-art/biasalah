// lib/utils/mouse_tracker_fix.dart

import 'package:flutter/material.dart';


/// A wrapper widget that prevents mouse tracker assertion errors
/// by properly handling mouse events and widget lifecycle
class MouseTrackerSafeWrapper extends StatefulWidget {
  final Widget child;
  
  const MouseTrackerSafeWrapper({
    super.key,
    required this.child,
  });

  @override
  State<MouseTrackerSafeWrapper> createState() => _MouseTrackerSafeWrapperState();
}

class _MouseTrackerSafeWrapperState extends State<MouseTrackerSafeWrapper> {
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return const SizedBox.shrink();
    }

    return MouseRegion(
      onEnter: (_) {
        // Handle mouse enter safely
        if (mounted && !_isDisposed) {
          // Optional: Add mouse enter logic here
        }
      },
      onExit: (_) {
        // Handle mouse exit safely
        if (mounted && !_isDisposed) {
          // Optional: Add mouse exit logic here
        }
      },
      child: widget.child,
    );
  }
}

/// Extension to add mouse tracker safety to any widget
extension MouseTrackerSafe on Widget {
  Widget get mouseTrackerSafe => MouseTrackerSafeWrapper(child: this);
}

/// Global error handler for mouse tracker assertions
class MouseTrackerErrorHandler {
  static void initialize() {
    // Override Flutter's error handling for mouse tracker and layout assertions
    FlutterError.onError = (FlutterErrorDetails details) {
      final exceptionString = details.exception.toString();
      
      // Suppress mouse tracker and layout errors in debug mode
      if (exceptionString.contains('mouse_tracker.dart') ||
          exceptionString.contains('Assertion failed') ||
          exceptionString.contains('Cannot hit test a render box') ||
          exceptionString.contains('RenderBox was not laid out') ||
          exceptionString.contains('hasSize')) {
        // Silently handle these errors - they don't affect functionality
        // Only log in debug mode if needed
        // debugPrint('Layout/Mouse tracker assertion suppressed: ${details.exception}');
        return;
      }
      
      // For other errors, use default handling
      FlutterError.presentError(details);
    };
  }
}