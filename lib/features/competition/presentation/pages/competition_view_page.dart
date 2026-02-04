import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';

import 'package:offroad_nav/features/competition/application/providers/competitions_providers.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition.dart';
import 'package:offroad_nav/features/competition/presentation/pages/competition_edit_page.dart';
import 'package:offroad_nav/features/competition/presentation/pages/competition_live_map_page.dart';
import 'package:offroad_nav/features/competition/presentation/pages/competition_participants_page.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/change_admin_sheet.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/competition_attempt_controls.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/competition_info_card.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/competition_join_actions.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/competition_participants_section.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/leaderboard_table.dart';
import 'package:offroad_nav/features/routes/presentation/controller/routes_controller.dart';
import 'package:offroad_nav/features/routes/presentation/pages/route_detail_page.dart';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
          final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
          final isAdmin = myUid.isNotEmpty && myUid == competition.adminId;

          final canEdit = isAdmin && competition.status == CompetitionStatus.upcoming;
          final canChangeAdmin = isAdmin; // если хочешь менять админа только админу
          final adminLabel = competition.adminId == myUid
            ? 'You'
            : '${competition.adminName}';

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
                  adminLabel: adminLabel,
                  canChangeAdmin: canChangeAdmin, 
                  onChangeAdmin: () => onChangeAdminTap(context, ref, competition),
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
                  onOpenRoute: () async {
                    try {
                      final route = await ref.read(
                        routeByIdProvider(competition.routeId).future,
                      );
                      if (!context.mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RouteDetailPage(
                            name: route.name,
                            points: route.points, // лучше так
                            routeId: route.id,
                            showGo: false,
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to open route: $e')),
                      );
                    }
                  },
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
                    } catch (e) {
                      showErr(e);
                    }
                  },
                  onLeave: () async {
                    try {
                      await ref
                          .read(competitionsRepositoryProvider)
                          .leaveCompetition(competitionId);
                    } catch (e) {
                      showErr(e);
                    }
                  },
                ),

                const SizedBox(height: height20),

                CompetitionAttemptControls(
                  status: competition.status,
                  joined: joined,
                  activeAttempt: activeAttempt,
                  isAdmin: isAdmin,
                  onStart: () async {
                    try {
                      final attemptId = await ref
                          .read(competitionsRepositoryProvider)
                          .startAttempt(competitionId);

                      // грузим маршрут по routeId из competition
                      final route = await ref.read(
                        routeByIdProvider(competition.routeId).future,
                      );
                      final pts = route.latLngPoints;

                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RouteTrackingPage(
                            points: pts,
                            mode: TrackingMode.competition, 
                            competitionId: competitionId,
                            routeId: route.id,
                            routeName: route.name,
                            onFinish: (result) async {
                              await ref
                                  .read(competitionsRepositoryProvider)
                                  .finishAttemptWithResult(
                                    competitionId: competitionId,
                                    attemptId: attemptId,
                                    durationSeconds: result.durationSec,
                                    distanceMeters: result.distanceMeters,
                                    startIndex: result.startIndex,
                                    endIndex: result.endIndex,
                                  );
                              // traversed: traversed,);
                            },
                            onCancel: () async {
                              await ref
                                  .read(competitionsRepositoryProvider)
                                  .cancelAttempt(competitionId, attemptId);
                            },
                          ),
                        ),
                      );
                    } catch (e) {
                      showErr(e);
                    }
                  },

                  onLiveMap: () async {
                    final route = await ref.read(routeByIdProvider(competition.routeId).future);
                    final pts = route.latLngPoints;

                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CompetitionLiveMapPage(
                          competitionId: competitionId,
                          routePoints: pts,
                          routeName: route.name,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: height20),
                CompetitionParticipantsSection(
                  participantsAsync: participantsAsync,
                  competitionId: competitionId,
                    onSeeAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CompetitionParticipantsPage(competitionId: competitionId),
                      ),
                    );
                  },
                ),

                const SizedBox(height: height20),

                const Text(
                  'Leaderboard',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: fontSize16,
                  ),
                ),
                const SizedBox(height: height8),

                leaderboard.when(
                  data: (entries) => LeaderboardTable(entries: entries),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Failed to load leaderboard: $e'),
                ),
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

Future<void> onChangeAdminTap(BuildContext context, WidgetRef ref, Competition c) async {
  final picked = await showModalBottomSheet<UserPickItem>(
    context: context,
    backgroundColor: surfaceColor,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  builder: (_) => FractionallySizedBox(
    heightFactor: 0.50, // 👈 фикс: всегда одинаковая “нижняя” модалка
    child: ChangeAdminSheet(currentAdminId: c.adminId),
  ),
  );
  if (picked == null) return;

  await ref.read(competitionsRepositoryProvider).updateCompetitionAdmin(
    competitionId: c.id,
    adminId: picked.uid,
    adminName: picked.name,
  );
}
