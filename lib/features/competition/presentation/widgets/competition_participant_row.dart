import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/widgets/pill_nav_row.dart';
import 'package:offroad_nav/design/widgets/smart_avatar.dart';

class CompetitionParticipantRow extends StatelessWidget {
  final dynamic p;
  final VoidCallback? onTap;
  final Widget? trailing;

  const CompetitionParticipantRow({
    super.key,
    required this.p,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final title = ((p.displayName?.trim().isNotEmpty ?? false)
            ? p.displayName
            : p.uid) as String;

    return PillNavRow(
      title: title,
      leading: SmartAvatar(
        src: p.photoUrl,
        size: 28,
        placeholder: Container(
          color: surfaceColor,
          child: const Icon(Icons.person_outline, color: textHintColor, size: 18),
        ),
      ),
      trailing: trailing ??
          (onTap == null
              ? null
              : const Icon(Icons.chevron_right_rounded, color: textHintColor)),
      onTap: onTap,
    );
  }
}

class HintText extends StatelessWidget {
  final String text;
  const HintText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(text, style: const TextStyle(color: textHintColor)),
    );
  }
}
