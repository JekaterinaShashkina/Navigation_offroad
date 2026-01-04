import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';

class TrackingBottomControls extends StatelessWidget {
  final VoidCallback onFinish;
  final VoidCallback onPauseResume;
  final VoidCallback onSettings;

  final bool isPaused;
  final bool started;

  const TrackingBottomControls({
    super.key,
    required this.onFinish,
    required this.onPauseResume,
    required this.onSettings,
    required this.isPaused,
    required this.started,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(radius24),
          topRight: Radius.circular(radius24),
        ),
        boxShadow: [
          BoxShadow(
            color: textMainColor.withOpacity(0.10),
            blurRadius: radius12,
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _PillButton(
              icon: Icons.flag,
              label: 'Finish',
              enabled: started,
              onTap: started ? onFinish : null,
            ),
          ),
          const SizedBox(width: width16),
          Expanded(
            child: _PillButton(
              icon: isPaused ? Icons.play_arrow : Icons.pause,
              label: isPaused ? 'Resume' : 'Pause',
              enabled: started,
              onTap: started ? onPauseResume : null,
            ),
          ),
          const SizedBox(width: width16),
          Expanded(
            child: _PillButton(
              icon: Icons.settings,
              label: 'Settings',
              enabled: true,
              onTap: onSettings,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.06),
            borderRadius: BorderRadius.circular(radius24),
            border: Border.all(
              color: buttonSecondBackgroundColor.withOpacity(0.65),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: textMainColor),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textMainColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
