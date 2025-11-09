// widgets/hud_widgets.dart
import 'package:flutter/material.dart';

class RouteStatChip extends StatelessWidget {
  const RouteStatChip({
    super.key,
    required this.points,
    required this.distanceText,
    this.onTap,
  });

  final int points;
  final String distanceText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.6),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          'Pts: $points • $distanceText',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final color = disabled ? Colors.white54 : Colors.white;

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.6),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}
