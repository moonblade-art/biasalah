import 'package:flutter/material.dart';
import '../widgets/page_transition.dart';

class BackButtonWidget extends StatelessWidget {
  final Widget? previousPage; 
  final Color color;

  const BackButtonWidget({
    super.key,
    this.previousPage,
    this.color = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, top: 8),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: color),
          onPressed: () {
            if (previousPage != null) {
              Navigator.of(context).pushReplacement(
                PageTransitionWidget.createRoute(previousPage!),
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }
}
