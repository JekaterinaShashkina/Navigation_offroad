import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import '../../../../design/widgets/form_fields_label.dart'; // если тут лежит PillBox

class TimeLimitPicker extends StatelessWidget {
  final Duration value;
  final ValueChanged<Duration> onChanged;

  const TimeLimitPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  String get _label {
    final h = value.inHours;
    final m = value.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  Future<void> _pick(BuildContext context) async {
    final options = <Duration>[
      const Duration(minutes: 30),
      const Duration(hours: 1),
      const Duration(hours: 2),
      const Duration(hours: 3),
    ];

    final res = await showModalBottomSheet<Duration>(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Time limit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          for (final d in options)
            ListTile(
              title: Text(
                '${d.inHours > 0 ? '${d.inHours}h ' : ''}${d.inMinutes % 60}m',
              ),
              onTap: () => Navigator.pop(context, d),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );

    if (res != null) {
      onChanged(res);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => _pick(context),
      child: PillBox(
        child: Row(
          children: [
            Expanded(child: Text(_label)),
            const Icon(Icons.timer_rounded, color: textHintColor),
          ],
        ),
      ),
    );
  }
}
