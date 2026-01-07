import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/styles.dart';

class FormFieldLabel extends StatelessWidget {
  final String text;

  const FormFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: textMainColor,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );
  }
}

InputDecoration pillInputDecoration(String? hint) => InputDecoration(
      hintText: hint,
      hintStyle: hintTextStyle,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: Color(0xFFE6E6EA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: Color(0xFFE6E6EA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: Color(0xFFD0D0D6)),
      ),
    );

/// Поле ввода фиксированной высоты 50px 
class PillTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final String? Function(String?)? validator;

  const PillTextField({
    super.key,
    required this.controller,
    this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: 1,
        decoration: pillInputDecoration(hint)
        ),
      );
  }
}

/// Контейнер с бордюром и высотой 50px 
class PillBox extends StatelessWidget {
  final Widget child;

  const PillBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6E6EA)),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
