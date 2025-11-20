import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final String label;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;

  const InputField({
    super.key,
    required this.label,
    required this.prefixIcon,
    this.suffixIcon,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue),
        ),
      ),
    );
  }
}