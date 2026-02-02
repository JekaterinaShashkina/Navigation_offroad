import 'package:flutter/material.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition.dart';

class CompetitionJoinActions extends StatelessWidget {
  final bool joined;
  final CompetitionStatus status;
  final VoidCallback onJoin;
  final VoidCallback onLeave;

  const CompetitionJoinActions({
    super.key,
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
      secondaryBackground: joined,
    );
  }
}
