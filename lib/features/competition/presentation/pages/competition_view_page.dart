import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/features/competition/application/providers/competitions_providers.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition_attempt.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/leaderboard_table.dart';

class CompetitionViewPage extends ConsumerWidget {
  final String competitionId;
  const CompetitionViewPage({super.key, required this.competitionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitionAsync = ref.watch(competitionProvider(competitionId));
    final participantsAsync = ref.watch(competitionParticipantsProvider(competitionId));
    final leaderboard = ref.watch(leaderboardProvider(competitionId));
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: 'Competition',
        onPressed: () => Navigator.pop(context),
      ),
      body: competitionAsync.when(
        data: (competition) {
          if (competition == null) {
            return const Center(child: Text('Competition not found'));
          }
          final statusLabel = switch (competition.status) {
            CompetitionStatus.upcoming => 'Upcoming',
            CompetitionStatus.active => 'Active',
            CompetitionStatus.ended => 'Past',
          };
          final participants = participantsAsync.maybeWhen(
            data: (value) => value,
            orElse: () => const [],
          );
          final joined = uid != null && participants.any((p) => p.uid == uid);

          final activeAttempt = ref.watch(activeAttemptProvider(competitionId));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(padding16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoCard(
                  competition: competition,
                  statusLabel: statusLabel,
                  participantCount: participants.length,
                ),
                const SizedBox(height: height16),
                _JoinActions(
                  joined: joined,
                  status: competition.status,
                  onJoin: () async {
                    try {
                      await ref
                          .read(competitionsRepositoryProvider)
                          .joinCompetition(competitionId);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
                  onLeave: () async {
                    try {
                      await ref
                          .read(competitionsRepositoryProvider)
                          .leaveCompetition(competitionId);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: height16),
                _AttemptControls(
                  status: competition.status,
                  joined: joined,
                  activeAttempt: activeAttempt,
                  onStart: () async {
                    try {
                      await ref.read(competitionsRepositoryProvider).startAttempt(competitionId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Attempt started')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
                  onFinish: () async {
                    try {
                      await ref.read(competitionsRepositoryProvider).finishAttempt(competitionId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Attempt finished')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: height24),
                const Text(
                  'Participants',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                participantsAsync.when(
                  data: (items) => Column(
                    children: items
                        .map(
                          (p) => ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text(p.displayName ?? p.uid),
                            subtitle: Text(p.uid),
                          ),
                        )
                        .toList(),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Failed to load participants: $e'),
                ),
                const SizedBox(height: height24),
                const Text(
                  'Leaderboard',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                LeaderboardTable(entries: leaderboard),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load competition: $e')),
      ),

    );
  }
}

class _InfoCard extends StatelessWidget {
  final Competition competition;
  final String statusLabel;
  final int participantCount;

  const _InfoCard({
    required this.competition,
    required this.statusLabel,
    required this.participantCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(padding16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(radius12),
      ),
      child: 
        Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  competition.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Chip(label: Text(statusLabel)),
            ],
          ),

          const SizedBox(height: 8),
          Text(competition.description),
          const SizedBox(height: 8),
          Text(
            'Route: ${competition.routeId}',
            style: const TextStyle(color: textHintColor),
          ),

          const SizedBox(height: 4),
          Text(
            '${_formatDate(competition.startAt)} - ${_formatDate(competition.endAt)}',
            style: const TextStyle(color: textHintColor),

          ),
          const SizedBox(height: 4),
          Text('Participants: $participantCount', style: const TextStyle(color: textHintColor)),
          const SizedBox(height: 8),
          const Text(
            'Rules',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(competition.rulesText, style: hintTextStyle.copyWith(color: Colors.black)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _JoinActions extends StatelessWidget {
  final bool joined;
  final CompetitionStatus status;
  final VoidCallback onJoin;
  final VoidCallback onLeave;

  const _JoinActions({
    required this.joined,
    required this.status,
    required this.onJoin,
    required this.onLeave,
  });

   @override
  Widget build(BuildContext context) {
    final isEnded = status == CompetitionStatus.ended;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: isEnded
                ? null
                : joined
                    ? onLeave
                    : onJoin,
            style: ElevatedButton.styleFrom(
              backgroundColor: joined ? Colors.grey[300] : textHintColor,
              foregroundColor: joined ? Colors.black87 : Colors.black,
              elevation: 0,
              
            ),
            child: Text(joined ? 'Leave competition' : 'Join competition'),
          ),
        ),
      ]
    );
  }
}

class _AttemptControls extends StatelessWidget {
  final CompetitionStatus status;
  final bool joined;
  final CompetitionAttempt? activeAttempt;
  final VoidCallback onStart;
  final VoidCallback onFinish;


  const _AttemptControls({
    required this.status,
    required this.joined,
    required this.activeAttempt,
    required this.onStart,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    if (!joined) return const SizedBox.shrink();

    final isActive = status == CompetitionStatus.active;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attempts',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: isActive && activeAttempt == null ? onStart : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  elevation: 0,
                ),
                child: const Text('Start attempt'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: isActive && activeAttempt != null ? onFinish : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  elevation: 0,
                ),
                child: const Text('Finish'),
              ),
            ),
          ],
        ),
        if (!isActive)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Attempts are available only while competition is active.',
              style: TextStyle(color: textHintColor),
            ),
          ),
      ],
    );
  }
}