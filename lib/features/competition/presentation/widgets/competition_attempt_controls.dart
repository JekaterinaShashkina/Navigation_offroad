import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition_attempt.dart';

class CompetitionAttemptControls extends StatelessWidget {
  final CompetitionStatus status;
  final bool joined;
  final CompetitionAttempt? activeAttempt;
  final VoidCallback onStart;
  final VoidCallback? onFinish;

  const CompetitionAttemptControls({
    super.key,
    required this.status,
    required this.joined,
    required this.activeAttempt,
    required this.onStart,
    this.onFinish,
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
                secondaryBackground: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                text: 'Finish',
                onPressed: canFinish ? onFinish : null,
                secondaryBackground: true,
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
