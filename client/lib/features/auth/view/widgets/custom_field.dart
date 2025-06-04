import 'package:flutter/material.dart';

class CustomField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final bool isObscureText;
  const CustomField({
    super.key,
    required this.hintText,
    required this.controller,
    this.isObscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(hintText: hintText),
      validator: (val) {
        if (val!.trim().isEmpty) {
          return "$hintText is missing!";
        }
        if (hintText == 'Email') {
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(val.trim())) {
            return "Enter a valid email!";
          }
        }
        if (hintText == 'Password' && val.trim().length < 5) {
          return "Password must be at least 5 characters!";
        }
        if (hintText == 'Name' && val.trim().length < 3) {
          return "Name must be at least 3 characters!";
        }
        return null;
      },
      obscureText: isObscureText,
    );
  }
}
