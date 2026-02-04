import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition.dart';

class CompetitionInfoCard extends StatelessWidget {
  final Competition competition;
  final String statusLabel;
  final int participantCount;

  final bool canEdit;
  final VoidCallback? onEdit;
  final VoidCallback? onOpenRoute;
  final String adminLabel;
  final bool canChangeAdmin;
  final VoidCallback? onChangeAdmin;

  const CompetitionInfoCard({
    super.key,
    required this.competition,
    required this.statusLabel,
    required this.participantCount,
    this.canEdit = false,
    this.onEdit,
    this.onOpenRoute,
    this.adminLabel = '—',
    required this.canChangeAdmin,
    this.onChangeAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final routeTitle =
        (competition.routeName?.trim().isNotEmpty ?? false) ? competition.routeName! : competition.routeId;

    final modeText = _modeLabel(competition.vehicleType);

    return Container(
      padding: const EdgeInsets.all(padding16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E6EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  competition.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),

              if (canEdit)
                GestureDetector(
                  onTap: onEdit,
                  child: Stack(
                    alignment: Alignment.center,
                    children: const [
                      Icon(Icons.edit_rounded, size: 22, color: Colors.black),
                      Icon(Icons.edit_rounded, size: 20, color: chipBgColor),
                    ],
                  ),
                ),
              if (canEdit) const SizedBox(width: 12),

              _StatusBadge(text: statusLabel),
            ],
          ),

          if (competition.description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(competition.description, style: const TextStyle(color: Colors.black87)),
          ],

          const SizedBox(height: 10),
          // Text('Route: $routeTitle', style: const TextStyle(color: textHintColor)),
Row(
  children: [
    const Text('Route: ', style: TextStyle(color: textHintColor)),
    InkWell(
      onTap: onOpenRoute,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: buttonBackgroundColor,
          borderRadius: BorderRadius.circular(10),
          // border: Border.all(color: bgNightColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              routeTitle,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 6),
              // const Icon(Icons.open_in_new, size: 16, color: Colors.black54),
          ],
        ),
      ),
    ),
  ],
),
          const SizedBox(height: 4),
          Text(
            'Time: ${formatCompetitionDate(competition.startAt)} - ${formatCompetitionDate(competition.endAt)}',
            style: const TextStyle(color: textHintColor),
          ),

          const SizedBox(height: 4),
          Text('Mode: $modeText', style: const TextStyle(color: textHintColor)),
          const SizedBox(height: 4),
          Text('Participants: $participantCount', style: const TextStyle(color: textHintColor)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Admin: $adminLabel', style: const TextStyle(color: textHintColor)),
              const Spacer(),
              if (canChangeAdmin && onChangeAdmin != null)
                InkWell(
                  onTap: onChangeAdmin,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: buttonSecondBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE6E6EA)),
                    ),
                    child: const Text('Change', style: TextStyle(fontWeight: FontWeight.w700, color: surfaceColor)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Rules: ${competition.rulesText}', style: TextStyle(color: textHintColor)),
        ],
      ),
    );
  }

  String _modeLabel(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    return switch (v) {
      'moto' => 'Moto',
      'auto' => 'Auto',
      'walk' => 'Walk',
      _ => '—',
    };
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  const _StatusBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9CFEA)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

String formatCompetitionDate(DateTime date) {
  return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
