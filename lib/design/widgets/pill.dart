import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';

class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
    this.radius = 18,
    this.padding = const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    this.selectedBg = textHintColor,
    this.unselectedBg = listShadowColor,
    this.selectedFg = surfaceColor,
    this.unselectedFg = textHintColor,
    this.withShadowWhenSelected = true,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  final double radius;
  final EdgeInsetsGeometry padding;

  final Color selectedBg;
  final Color unselectedBg;
  final Color selectedFg;
  final Color unselectedFg;
  final bool withShadowWhenSelected;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? selectedBg : unselectedBg;
    final fg = selected ? selectedFg : unselectedFg;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: selected && withShadowWhenSelected
            ? [BoxShadow(color: textHintColor, blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: Center(
              child: Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: fg)),
            ),
          ),
        ),
      ),
    );
  }
}
