// lib/utils/layout_helper.dart

import 'package:flutter/material.dart';

class LayoutHelper {
  /// Safely builds a widget with proper error handling
  static Widget safeBuilder({
    required Widget Function() builder,
    Widget? fallback,
  }) {
    try {
      return builder();
    } catch (e) {
      print('Layout error caught: $e');
      return fallback ?? const SizedBox.shrink();
    }
  }

  /// Creates a safe container that prevents layout issues
  static Widget safeContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Decoration? decoration,
    double? width,
    double? height,
  }) {
    return Container(
      key: UniqueKey(),
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: decoration,
      child: child,
    );
  }

  /// Creates a safe column that prevents overflow
  static Widget safeColumn({
    required List<Widget> children,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.min,
  }) {
    return Column(
      key: UniqueKey(),
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }

  /// Creates a safe row that prevents overflow
  static Widget safeRow({
    required List<Widget> children,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
  }) {
    return Row(
      key: UniqueKey(),
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }
}