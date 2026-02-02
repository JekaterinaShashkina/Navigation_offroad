import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';

import 'package:offroad_nav/features/competition/application/providers/competitions_providers.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition.dart';
import 'package:offroad_nav/features/competition/presentation/pages/competition_edit_page.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/competition_attempt_controls.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/competition_info_card.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/competition_join_actions.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/competition_participants_section.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/leaderboard_table.dart';
import 'package:offroad_nav/features/routes/presentation/controller/routes_controller.dart';
import 'package:offroad_nav/features/routes/presentation/pages/route_tracking_page.dart';

class CompetitionViewPage extends ConsumerWidget {
  final String competitionId;
  const CompetitionViewPage({super.key, required this.competitionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitionAsync = ref.watch(competitionProvider(competitionId));
    final participantsAsync = ref.watch(
      competitionParticipantsProvider(competitionId),
    );
    final leaderboard = ref.watch(leaderboardProvider(competitionId));
    final uid = FirebaseAuth.instance.currentUser?.uid;

    void showErr(Object e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

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
          final canEdit = competition.status == CompetitionStatus.upcoming
          // если есть ownerId/createdBy — раскомментируй:
          // && uid != null && uid == competition.ownerId
          ;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              padding16,
              padding12,
              padding16,
              padding24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CompetitionInfoCard(
                  competition: competition,
                  statusLabel: statusLabel,
                  participantCount: participants.length,
                  canEdit: canEdit,
                  onEdit: canEdit
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CompetitionEditPage(
                                competitionId: competitionId,
                              ),
                            ),
                          );
                        }
                      : null,
                ),

                const SizedBox(height: height12),

                CompetitionJoinActions(
                  joined: joined,
                  status: competition.status,
                  onJoin: () async {
                    try {
                      await ref
                          .read(competitionsRepositoryProvider)
                          .joinCompetition(competitionId);
                    } catch (e) {showErr(e);}
                  },
                  onLeave: () async {
                    try {
                      await ref
                          .read(competitionsRepositoryProvider)
                          .leaveCompetition(competitionId);
                    } catch (e) {showErr(e);}
                  },
                ),

                const SizedBox(height: height20),

                CompetitionAttemptControls(
                  status: competition.status,
                  joined: joined,
                  activeAttempt: activeAttempt,
                  onStart: () async {
                    try {
                      final attemptId = await ref
                          .read(competitionsRepositoryProvider)
                          .startAttempt(competitionId);

                              // грузим маршрут по routeId из competition
                      final route = await ref.read(routeByIdProvider(competition.routeId).future);
                      final pts = route.latLngPoints;

                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RouteTrackingPage(
                            points: pts,
                            mode: TrackingMode.competition, // пока можно live, позже сделаем TrackingMode.competition
                            routeId: route.id,
                            routeName: route.name,
                            onFinish: (result) async {
                              await ref.read(competitionsRepositoryProvider)
                                .finishAttemptWithResult(
                                  competitionId: competitionId,
                                  attemptId: attemptId,
                                  durationSeconds: result.durationSec,
                                  distanceMeters: result.distanceMeters,
                                  startIndex: result.startIndex,
                                  endIndex: result.endIndex);
      // traversed: traversed,);
                            },
                            onCancel: () async {
                              await ref.read(competitionsRepositoryProvider)
                                .cancelAttempt(competitionId, attemptId);
                            },
                          ),
                        ),
                      );
                    } catch (e) {showErr(e);}
                  },
                  // onFinish: () async {
                  //   try {
                  //     await ref
                  //         .read(competitionsRepositoryProvider)
                  //         .finishAttempt(competitionId);
                  //     if (context.mounted) {
                  //       ScaffoldMessenger.of(context).showSnackBar(
                  //         const SnackBar(content: Text('Attempt finished')),
                  //       );
                  //     }
                  //   } catch (e) {showErr(e);}
                  // },
                ),

                const SizedBox(height: height20),
                CompetitionParticipantsSection(
                  participantsAsync: participantsAsync,
                ),

                const SizedBox(height: height20),

                const Text(
                  'Leaderboard',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: fontSize16),
                ),
                const SizedBox(height: height8),

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
