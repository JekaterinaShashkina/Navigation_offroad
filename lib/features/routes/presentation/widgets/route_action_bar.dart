import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';

/// Конфиг одной кнопки в нижнем баре
class ActionButtonConfig {
  final String label;
  final Widget? iconWidget;   // кастомная иконка (SVG, png и т.п.)
  final IconData? iconData;   // запасной вариант – обычная Icon
  final VoidCallback? onTap;
  final bool filled;          // «главная» / активная
  final bool enabled;         // доступность

  const ActionButtonConfig({
    required this.label,
    this.iconWidget,
    this.iconData,
    this.onTap,
    this.filled = false,
    this.enabled = true,
  });
}

class RouteActionBar extends StatelessWidget {
  const RouteActionBar({
    super.key,
    required this.actions,
  });

  /// Список кнопок (2–3 штуки)
  final List<ActionButtonConfig> actions;

  @override
  Widget build(BuildContext context) {
    final visible = actions;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(60),
          boxShadow: const [
            BoxShadow(
              blurRadius: 14,
              color: Colors.black38,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: List.generate(visible.length * 2 - 1, (index) {
            if (index.isOdd) return const SizedBox(width: 8);

            final a = visible[index ~/ 2];
            return Expanded(
              child: _segButton(
                label: a.label,
                iconWidget: a.iconWidget,
                icon: a.iconData,
                onTap: a.enabled ? a.onTap : null,
                filled: a.filled && a.enabled,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _segButton({
    required String label,
    IconData? icon,
    Widget? iconWidget,
    VoidCallback? onTap,
    bool filled = false,
    BorderRadius? radius,
  }) {
    radius ??= BorderRadius.circular(50);
    final bool disabled = onTap == null;

    final Color bg = disabled
        ? surfaceColor.withOpacity(.10)
        : (filled ? textHintColor : Colors.white.withOpacity(.08));
    final Color fg = disabled
        ? textHintColor
        : (filled ? textMainColor : surfaceColor);
    final Color border = disabled ? Colors.white10 : Colors.white24;

    return Material(
      color: bg,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconWidget != null)
                iconWidget
              else if (icon != null)
                Icon(icon, color: fg, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
