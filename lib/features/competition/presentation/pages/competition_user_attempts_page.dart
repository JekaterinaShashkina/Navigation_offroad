import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/features/competition/application/providers/competitions_providers.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition_attempt.dart';

class CompetitionUserAttemptsPage extends ConsumerWidget {
  final String competitionId;
  final String userId;
  final String title;

  const CompetitionUserAttemptsPage({
    super.key,
    required this.competitionId,
    required this.userId,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attemptsAsync = ref.watch(competitionAttemptsProvider(competitionId));

    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: title,
        onPressed: () => Navigator.pop(context),
      ),
      body: attemptsAsync.when(
        data: (attempts) {
          final mine = attempts.where((a) => a.uid == userId).toList();
          if (mine.isEmpty) {
            return const Center(child: Text('No attempts yet'));
          }

          mine.sort((a, b) {
            final ad = a.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bd = b.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bd.compareTo(ad);
          });

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              padding16,
              padding12,
              padding16,
              padding24,
            ),
            itemCount: mine.length,
            separatorBuilder: (_, __) => const SizedBox(height: height12),
            itemBuilder: (context, i) => _AttemptCard(a: mine[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load attempts: $e')),
      ),
    );
  }
}

class _AttemptCard extends StatelessWidget {
  final CompetitionAttempt a;
  const _AttemptCard({required this.a});

  @override
  Widget build(BuildContext context) {
    final finished = a.finishedAt != null && a.durationSeconds != null;

    final title = finished
        ? _formatDuration(a.durationSeconds!)
        : 'In progress';

    final startedStr = a.startedAt != null ? _formatDate(a.startedAt!) : null;
    final finishedStr = a.finishedAt != null ? _formatDate(a.finishedAt!) : null;

    final distanceStr = a.distanceMeters != null
        ? _formatDistance(a.distanceMeters!)
        : null;

    final indexStr = (a.startIndex != null && a.endIndex != null)
        ? '${a.startIndex} → ${a.endIndex}'
        : null;

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
          // заголовок карточки
          Row(
            children: [
              Expanded(
                child: Text(
                  "Time: $title",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusChip(
                text: finished ? 'Finished' : 'Active',
                filled: finished,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // строки метрик
          _InfoLine(label: 'Start', value: startedStr ?? '—'),
          if (finishedStr != null) _InfoLine(label: 'Finish', value: finishedStr),
          if (distanceStr != null) _InfoLine(label: 'Distance', value: distanceStr),
          if (indexStr != null) _InfoLine(label: 'Index', value: indexStr),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              '$label:',
              style: const TextStyle(color: textHintColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final bool filled;

  const _StatusChip({required this.text, required this.filled});

  @override
  Widget build(BuildContext context) {
    final bg = filled ? const Color(0xFFF4F0FA) : Colors.black.withOpacity(0.06);
    final border = filled ? const Color(0xFFD9CFEA) : Colors.black.withOpacity(0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// mm:ss или h:mm:ss
String _formatDuration(int seconds) {
  if (seconds < 0) seconds = 0;
  final d = Duration(seconds: seconds);
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);

  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String _formatDate(DateTime dt) {
  return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

String _formatDistance(double meters) {
  if (meters.isNaN || meters.isInfinite) return '—';
  if (meters >= 1000) {
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }
  return '${meters.toStringAsFixed(1)} m';
}
