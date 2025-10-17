import 'package:flutter/material.dart';
import '../utils/color_palette.dart';

class InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final bool obscure;

  const InputField({
    super.key,
    required this.label,
    required this.controller,
    this.prefixIcon,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: ColorPalette.primaryColor)
            : null,
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade50,
        labelStyle: const TextStyle(color: Colors.black87),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: ColorPalette.primaryColor, width: 1.8),
        ),
      ),
    );
  }
}
