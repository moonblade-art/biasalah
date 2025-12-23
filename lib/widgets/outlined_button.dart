import 'package:flutter/material.dart';
import '../utils/color_palette.dart';

class OutlinedButtonCustom extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const OutlinedButtonCustom({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: ColorPalette.primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: ColorPalette.primaryColor,
          ),
        ),
      ),
    );
  }
}
