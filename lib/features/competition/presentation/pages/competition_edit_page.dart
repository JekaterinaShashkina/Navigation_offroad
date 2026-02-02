import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/features/competition/application/providers/competitions_providers.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/competition_form.dart';

class CompetitionEditPage extends ConsumerWidget {
  final String competitionId;
  const CompetitionEditPage({super.key, required this.competitionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitionAsync = ref.watch(competitionProvider(competitionId));

    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: 'Edit competition',
        onPressed: () => Navigator.pop(context),
      ),
      body: competitionAsync.when(
        data: (competition) {
          if (competition == null) {
            return const Center(child: Text('Competition not found'));
          }
          // защита: редактирование только до старта
          if (competition.status != CompetitionStatus.upcoming) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Editing is available only before the competition starts.',
                ),
              ),
            );
          }
          return CompetitionForm(
            initial: competition,
            submitLabel: 'Save changes',
            onSubmit: (input) async {
              await ref
                  .read(competitionsRepositoryProvider)
                  .updateCompetition(competitionId, input);
              if (context.mounted) Navigator.pop(context);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load competition: $e')),
      ),
    );
  }
}
