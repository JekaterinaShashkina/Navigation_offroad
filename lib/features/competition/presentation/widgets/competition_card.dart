import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
// import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition.dart';

class CompetitionCard extends StatelessWidget {
  final Competition competition;
  final VoidCallback onTap;

  const CompetitionCard({
    super.key,
    required this.competition, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
final status = competition.status;
    final statusLabel = switch (status) {
      CompetitionStatus.upcoming => 'Upcoming',
      CompetitionStatus.active => 'Active',
      CompetitionStatus.ended => 'Past',
    };

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(radius12),
        ),
        padding: const EdgeInsets.all(padding16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    competition.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

          _StatusChip(label: statusLabel, status: status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              competition.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: textHintColor),
            ),
            const SizedBox(height: 8),
            Text(
              'From ${_formatDate(competition.startAt)} to ${_formatDate(competition.endAt)}',
              style: const TextStyle(fontSize: 12, color: textHintColor),
            ),
          ],
        ),
      ),
    );
  }

  
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final CompetitionStatus status;
  const _StatusChip({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: textHintColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: textMainColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
