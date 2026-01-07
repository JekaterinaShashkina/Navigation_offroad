import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';
import 'package:offroad_nav/design/widgets/smart_avatar.dart';

import 'package:offroad_nav/features/competition/application/providers/competitions_providers.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition_attempt.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/leaderboard_table.dart';

// твои pill-компоненты
import 'package:offroad_nav/design/widgets/pill_nav_row.dart';

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
          final routeLabel = (competition.routeName?.trim().isNotEmpty ?? false)
          ? competition.routeName!
          : competition.routeId;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(padding16, padding12, padding16, padding24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoCardStyled(
                  competition: competition,
                  statusLabel: statusLabel,
                  participantCount: participants.length,
                ),

                const SizedBox(height: height12),

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

                const SizedBox(height: height20),

                _AttemptsControls(
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

                const SizedBox(height: height20),

                const Text(
                  'Participants',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),

                participantsAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const _HintText('No participants yet');
                    }
                    return _PillList(
                      children: items.map((p) {
                        final title = (p.displayName?.trim().isNotEmpty ?? false)
                            ? p.displayName!
                            : p.uid;
                        return PillNavRow(
                          title: title,
                          leading: SmartAvatar(
                            src: p.photoUrl, // или p.img — как поле называется в твоей модели участника
                            size: 28,
                            placeholder: Container(
                              color: surfaceColor,
                              child: const Icon(Icons.person_outline, color: textHintColor, size: 18),
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: textHintColor),
                          onTap: null, // позже можно открыть профиль
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Failed to load participants: $e'),
                ),

                const SizedBox(height: height20),

                const Text(
                  'Leaderboard',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),

                // если leaderboard_table у тебя уже красиво выглядит — ок.
                // если нет — потом тоже подгоним.
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

/// ---------------- Styled blocks ----------------

class _InfoCardStyled extends StatelessWidget {
  final Competition competition;
  final String statusLabel;
  final int participantCount;

  const _InfoCardStyled({
    required this.competition,
    required this.statusLabel,
    required this.participantCount,
  });

  @override
  Widget build(BuildContext context) {
    final routeTitle =
    (competition.routeName?.trim().isNotEmpty ?? false)
        ? competition.routeName!
        : competition.routeId;
    final vehicleLabel = switch ((competition.vehicleType ?? '').toLowerCase()) {
      'atv' => 'ATV',
      'jeep' => 'Jeep',
      'truck' => 'Truck',
      _ => '—',
    };
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
              _StatusBadge(text: statusLabel),
            ],
          ),

          if (competition.description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              competition.description,
              style: const TextStyle(color: Colors.black87),
            ),
          ],

          const SizedBox(height: 10),
          Text(
            'Route: $routeTitle',
            style: const TextStyle(color: textHintColor),
          ),

          const SizedBox(height: 4),
          Text(
            '${_formatDate(competition.startAt)} - ${_formatDate(competition.endAt)}',
            style: const TextStyle(color: textHintColor),
          ),

          const SizedBox(height: 4),
          Row(
            children: [
              _InfoPill(label: 'Car: $vehicleLabel'),
            ],
          ),
          Text(
            'Participants: $participantCount',
            style: const TextStyle(color: textHintColor),
          ),

          const SizedBox(height: 12),
          const Text('Rules', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            competition.rulesText,
            style: hintTextStyle.copyWith(color: Colors.black),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
        color: const Color(0xFFF4F0FA), // мягкий лиловый как на скрине
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9CFEA)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
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

    return AppButton(
      text: joined ? 'Leave competition' : 'Join competition',
      onPressed: isEnded ? null : (joined ? onLeave : onJoin),
      secondaryBackground: joined, // joined -> secondary style
    );
  }
}

class _AttemptsControls extends StatelessWidget {
  final CompetitionStatus status;
  final bool joined;
  final CompetitionAttempt? activeAttempt;
  final VoidCallback onStart;
  final VoidCallback onFinish;

  const _AttemptsControls({
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
    final canStart = isActive && activeAttempt == null;
    final canFinish = isActive && activeAttempt != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Attempts', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Start attempt',
                onPressed: canStart ? onStart : null,
                secondaryBackground: false, // primary
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                text: 'Finish',
                onPressed: canFinish ? onFinish : null,
                secondaryBackground: true, // secondary (чтобы отличалась)
              ),
            ),
          ],
        ),

        if (!isActive)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'Attempts are available only while competition is active.',
              style: TextStyle(color: textHintColor),
            ),
          ),
      ],
    );
  }
}

  // class _PillButton extends StatelessWidget {
  //   final String label;
  //   final bool enabled;
  //   final VoidCallback onTap;

  //   const _PillButton({
  //     required this.label,
  //     required this.enabled,
  //     required this.onTap,
  //   });

  //   @override
  //   Widget build(BuildContext context) {
  //     return SizedBox(
  //       height: 46,
  //       child: ElevatedButton(
  //         onPressed: enabled ? onTap : null,
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: const Color(0xFFE6E6EA),
  //           foregroundColor: Colors.black87,
  //           disabledBackgroundColor: const Color(0xFFE6E6EA),
  //           disabledForegroundColor: textHintColor,
  //           elevation: 0,
  //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
  //         ),
  //         child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
  //       ),
  //     );
  //   }
  // }

class _PillList extends StatelessWidget {
  final List<Widget> children;
  const _PillList({required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) const SizedBox(height: 10),
        ],
      ],
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

class _InfoPill extends StatelessWidget {
  final String label;
  const _InfoPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9CFEA)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}