import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';

class MapQuickControls extends StatelessWidget {
  const MapQuickControls({
    super.key,
    required this.onCenter,
    required this.onNorth,
    this.onToggleRestricted,
    this.restrictedEnabled = false,
  });

  final VoidCallback onCenter;
  final VoidCallback onNorth;
  final VoidCallback? onToggleRestricted;
  final bool restrictedEnabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onToggleRestricted != null) ...[
          _FabMini(
            icon: Icons.shield_outlined,
            tooltip: 'Restricted areas',
            onTap: onToggleRestricted!,
            filled: restrictedEnabled,
          ),
          const SizedBox(height: 10),
        ],
        _FabMini(
          icon: Icons.explore,
          tooltip: 'Face north',
          onTap: onNorth,
        ), // north
        const SizedBox(height: 10),
        _FabMini(
          icon: Icons.my_location,
          tooltip: 'Center on route start',
          onTap: onCenter,
        ), // center
      ],
    );
  }
}

class _FabMini extends StatelessWidget {
  const _FabMini({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: Material(
        color: filled ? buttonBackgroundColor : surfaceColor,
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: filled ? surfaceColor : textMainColor),
          ),
        ),
      ),
    );
  }
}
