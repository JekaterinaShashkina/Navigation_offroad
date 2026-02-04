import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/features/competition/application/providers/competitions_providers.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition_participant.dart';
import 'package:offroad_nav/features/competition/presentation/pages/competition_user_attempts_page.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/competition_participant_row.dart';

class CompetitionParticipantsPage extends ConsumerWidget {
  final String competitionId;

  const CompetitionParticipantsPage({
    super.key,
    required this.competitionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.watch(competitionParticipantsProvider(competitionId));

    return Scaffold(
      appBar: NewAppBar(
        title: 'Participants',
        onPressed: () => Navigator.pop(context),
      ),
      backgroundColor: backgroundMainColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: participantsAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return const HintText('No participants yet');
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final CompetitionParticipant p = items[i];
                final title =
                  ((p.displayName?.trim().isNotEmpty ?? false) ? p.displayName : p.uid) as String;
                return CompetitionParticipantRow(
                  p: p,
                  onTap: () {
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
                  );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load participants: $e')),
        ),
      ),
    );
  }
}
