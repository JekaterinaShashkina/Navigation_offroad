import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/styles.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefix;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.prefix,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: padding16),
      decoration: BoxDecoration(
        color: backgroundMainColor,
        borderRadius: BorderRadius.circular(radius24),
      ),
      child: Row(
        children: [
          if (prefix != null) ...[prefix!, const SizedBox(width: 8)],
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              style: bodyTextStyle,
              validator: validator,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none, // без подчёркивания/рамки
                hintText: hint,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
                errorMaxLines: 2, // текст ошибки поместится
              ),
            ),
          ),
          if (suffix != null) suffix!,
        ],
      ),
    );
  }
}
