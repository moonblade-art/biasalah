import 'package:flutter/material.dart';

class CurvedContainer extends StatelessWidget {
  final Widget child;
  final double curveRadius;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final double maxWidth;

  const CurvedContainer({
    super.key,
    required this.child,
    this.curveRadius = 30.0,
    this.padding = const EdgeInsets.all(24),
    this.backgroundColor,
    this.maxWidth = 600, 
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
        ),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(curveRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}
