import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/features/competition/application/providers/competitions_providers.dart';
import 'package:offroad_nav/features/competition/data/repositories/competitions_repository.dart';

Future<void> submitCompetition({
  required WidgetRef ref,
  required BuildContext context,
  required GlobalKey<FormState> formKey,
  required TextEditingController nameCtrl,
  required TextEditingController descCtrl,
  required String rule,
  required DateTime? startTime,
  required bool useLimit,
  required Duration limit,
  required String vehicle,
  required ValueChanged<bool> setSubmitting,
}) async {
  if (formKey.currentState == null || !formKey.currentState!.validate()) {
    return;
  }

  final repo = ref.read(competitionsRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);

  setSubmitting(true);
  try {
    await repo.createCompetition(
      CompetitionCreateParams(
        title: nameCtrl.text,
        description: descCtrl.text,
        rule: rule,
        startTime: startTime,
        useLimit: useLimit,
        limit: useLimit ? limit : null,
        vehicle: vehicle,
      ),
    );

    messenger.showSnackBar(
      const SnackBar(content: Text('Competition created')),
    );
    Navigator.pop(context);
  } on UnauthenticatedCompetitionException {
    messenger.showSnackBar(
      const SnackBar(content: Text('Please sign in')),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('Failed to create: $e')),
    );
  } finally {
    setSubmitting(false);
  }
}
