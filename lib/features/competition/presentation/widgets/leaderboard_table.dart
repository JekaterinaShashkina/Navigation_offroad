import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/features/competition/application/providers/competitions_providers.dart';

class LeaderboardTable extends StatelessWidget {
  final List<LeaderboardEntry> entries;

  const LeaderboardTable({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(padding16),
        child: Text(
          'No finished attempts yet',
          style: TextStyle(color: textHintColor),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: padding16),
          child: Row(
            children: const [
              Expanded(child: Text('Participant', style: TextStyle(fontWeight: FontWeight.w600))),
              SizedBox(width: 12),
              Text('Time', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...entries.asMap().entries.map(
          (entry) {
            final rank = entry.key + 1;
            final item = entry.value;
            final name = item.participant?.displayName ?? 'User ${item.participant?.uid ?? ''}';
            final time = _formatDuration(item.attempt.durationSeconds);

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: surfaceColor,
                child: Text('$rank'),
              ),
              title: Text(name),
              //subtitle: Text(item.participant?.uid ?? ''),
              trailing: Text(time),
            );
          },
        ),
      ],
    );
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}