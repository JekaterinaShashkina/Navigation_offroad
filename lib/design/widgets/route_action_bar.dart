import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/images.dart';

class RouteActionBar extends StatelessWidget {
  const RouteActionBar({
    super.key,
    required this.onSave,
    this.onToggleGo,
    required this.onDelete,
    this.isRecording = false,
    this.canSave = true,
    this.canDelete = true,
  });

  final VoidCallback? onSave;
  final VoidCallback? onToggleGo;
  final VoidCallback? onDelete;

  final bool isRecording;
  final bool canSave;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
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
          children: [
            // Save
            Expanded(
              child: _segButton(
                label: 'Save',
                iconWidget: saveIconNavigation,
                onTap: canSave ? onSave : null,
                filled: canSave, // активная — залитая
              ),
            ),
            const SizedBox(width: 8),

            // Go / Pause — показываем только если передан обработчик
            if (onToggleGo != null) ...[
              Expanded(
                child: _segButton(
                  label: isRecording ? 'Pause' : 'Go',
                  iconWidget: isRecording ? pauseIconNavigation : goIconNavigation,
                  onTap: onToggleGo,
                  filled: isRecording, // когда пишем — заливка
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Delete
            Expanded(
              child: _segButton(
                label: 'Delete',
                iconWidget: deleteIconNavigation,
                onTap: canDelete ? onDelete : null,
                filled: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segButton({
    required String label,
    IconData? icon,          // запасной вариант
    Widget? iconWidget,      // приоритетнее IconData
    VoidCallback? onTap,
    bool filled = false,
    BorderRadius? radius,
  }) {
    radius ??= BorderRadius.circular(50);
    final bool disabled = onTap == null;

    // цвета
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
              if (iconWidget != null) iconWidget else if (icon != null)
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
