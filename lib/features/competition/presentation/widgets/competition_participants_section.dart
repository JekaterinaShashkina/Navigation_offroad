import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/widgets/smart_avatar.dart';
import 'package:offroad_nav/design/widgets/pill_nav_row.dart';

class CompetitionParticipantsSection extends StatelessWidget {
  final AsyncValue<List<dynamic>> participantsAsync;

  const CompetitionParticipantsSection({
    super.key,
    required this.participantsAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Participants', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 8),
        participantsAsync.when(
          data: (items) {
            if (items.isEmpty) return const _HintText('No participants yet');
            return Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _ParticipantRow(p: items[i]),
                  if (i != items.length - 1) const SizedBox(height: 10),
                ]
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Failed to load participants: $e'),
        ),
      ],
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  final dynamic p;
  const _ParticipantRow({required this.p});

  @override
  Widget build(BuildContext context) {
    final title = ((p.displayName?.trim().isNotEmpty ?? false) ? p.displayName : p.uid) as String;

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
      trailing: const Icon(Icons.chevron_right_rounded, color: textHintColor),
      onTap: null,
    );
  }
}

class _HintText extends StatelessWidget {
  final String text;
  const _HintText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(text, style: const TextStyle(color: textHintColor)),
    );
  }
}
