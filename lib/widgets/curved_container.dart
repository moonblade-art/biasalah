import 'package:flutter/material.dart';

class CurvedContainer extends StatelessWidget {
  final Widget child;
  final double curveRadius;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final double maxWidth;
  final bool showShadow;

  const CurvedContainer({
    super.key,
    required this.child,
    this.curveRadius = 30.0,
    this.padding = const EdgeInsets.all(24),
    this.backgroundColor,
    this.maxWidth = 600,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
        ),
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(curveRadius),
          boxShadow: showShadow
              ? [
                  const BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: child, 
      ),
    );
  }
}
