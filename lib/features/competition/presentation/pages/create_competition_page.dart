import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/widgets/pill_picker.dart';

import 'package:offroad_nav/features/competition/data/repositories/competitions_repository.dart';
import 'package:offroad_nav/features/competition/application/providers/competitions_providers.dart';
import 'package:offroad_nav/features/competition/domain/config/competition_rules.dart';
import 'package:offroad_nav/features/competition/presentation/pages/competition_rules_page.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/competition_form.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/vehicle_selector.dart';

import 'package:offroad_nav/features/routes/domain/entities/route_entity.dart';
import 'package:offroad_nav/features/routes/presentation/controller/routes_controller.dart';
import 'package:offroad_nav/features/routes/presentation/pages/routes_list_page.dart';

// твои виджеты/стили
import 'package:offroad_nav/design/widgets/pill_nav_row.dart';
import 'package:offroad_nav/design/widgets/form_fields_label.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/time_limit_picker.dart';

class CreateCompetitionPage extends ConsumerStatefulWidget {
  const CreateCompetitionPage({super.key});

  @override
  ConsumerState<CreateCompetitionPage> createState() => _CreateCompetitionPageState();
}

class _CreateCompetitionPageState extends ConsumerState<CreateCompetitionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  // final _rulesCtrl = TextEditingController(text: 'Fastest time wins');
  CompetitionRule? _rule;

  RouteEntity? _route;
  DateTime? _startAt;
  DateTime? _endAt;

  // как “Time” в макете (ограничение по времени)
  Duration _timeLimit = const Duration(hours: 1);

  bool _saving = false;

  String _vehicleTypeUi = 'ATV';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    //_rulesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routesState = ref.watch(routesControllerProvider);

    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: 'Create a competition',
        onPressed: () => Navigator.pop(context),
      ),
      body: CompetitionForm(
          submitLabel: 'Create',
          onSubmit: (input) async {
            await ref.read(competitionsRepositoryProvider).createCompetition(input);
            if (context.mounted) Navigator.pop(context);
          },
      ),
    );
  }

}
