import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/widgets/pill_nav_row.dart';
import 'package:offroad_nav/design/widgets/smart_avatar.dart';
import 'package:offroad_nav/features/competition/presentation/pages/competition_user_attempts_page.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/competition_participant_row.dart';

class CompetitionParticipantsSection extends StatelessWidget {
  final AsyncValue<List<dynamic>> participantsAsync;
  final VoidCallback? onSeeAll;
  final String competitionId;

  const CompetitionParticipantsSection({
    super.key,
    required this.participantsAsync,
    required this.competitionId,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Participants',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            participantsAsync.maybeWhen(
              data: (items) {
                final total = items.length;
                if (total <= 3) return const SizedBox.shrink();
                if (onSeeAll == null) return const SizedBox.shrink();

                return TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('See all ($total)'),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 8),

        participantsAsync.when(
          data: (items) {
            if (items.isEmpty) return const HintText('No participants yet');

            final shown = items.take(3).toList(); // ✅ безопасно

            return Column(
              children: [
                for (int i = 0; i < shown.length; i++) ...[
                  CompetitionParticipantRow(
                    p: shown[i],
                    onTap: () {
                      final p = shown[i];
                      final title = ((p.displayName?.trim().isNotEmpty ?? false)
                              ? p.displayName
                              : p.uid) as String;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CompetitionUserAttemptsPage(
                            competitionId: competitionId,
                            userId: p.uid as String,
                            title: title,
                          ),
                        ),
                      );
                    },
                  ),
                  if (i != shown.length - 1) const SizedBox(height: 10),
                ],
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

