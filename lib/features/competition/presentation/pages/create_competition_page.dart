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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(padding16, padding12, padding16, padding24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FormFieldLabel('Name'),
                const SizedBox(height: 8),
                PillTextField(
                  controller: _nameCtrl,
                  hint: 'Lorem ipsum',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
                ),
                const SizedBox(height: height16),

                const FormFieldLabel('Description'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 3,
                  decoration: pillInputDecoration('Lorem ipsum'),
                ),
                const SizedBox(height: height16),

                Row(
                  children: [
                    const FormFieldLabel('Rules'),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CompetitionRulesPage()),
                        );
                      },
                      child: const Text('Rules'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                PillPicker<CompetitionRule>(
                 // title: 'Select rule',
                  placeholder: 'Select rule',
                  items: competitionRules,
                  selected: _rule,
                  idOf: (r) => r.id,
                  titleOf: (r) => r.title,
                  subtitleOf: (r) => r.description, // ← опционально, но красиво
                  onSelect: (r) => setState(() => _rule = r),
                ),
                const SizedBox(height: height16),

                // ROUTE
                Row(
                  children: [
                    const FormFieldLabel('Route'),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _pickRouteFromList(context),
                      child: const Text(
                        'Browse routes',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                PillPicker<RouteEntity>(
                  //label: '',
                  placeholder: 'Select route',
                  items: routesState.routes,
                  selected: _route,
                  titleOf: (r) => r.name,
                  idOf: (r) => r.id,
                  sheetTitle: 'Select route',
                  onSelect: (r) => setState(() => _route = r),
                ),
                // TIME (как в макете)
                const FormFieldLabel('Time'),
                const SizedBox(height: 8),

                PillNavRow(
                  title: _startAt == null ? 'Start time' : 'Start: ${_formatDt(_startAt!)}',
                  trailing: const Icon(Icons.calendar_month_rounded, color: textHintColor),
                  onTap: () async {
                    final dt = await _pickDateTime(context, initial: _startAt);
                    if (dt != null) setState(() => _startAt = dt);
                  },
                ),
                const SizedBox(height: 10),

                PillNavRow(
                  title: _endAt == null ? 'End time' : 'End: ${_formatDt(_endAt!)}',
                  trailing: const Icon(Icons.calendar_month_rounded, color: textHintColor),
                  onTap: () async {
                    final dt = await _pickDateTime(context, initial: _endAt);
                    if (dt != null) setState(() => _endAt = dt);
                  },
                ),
                const SizedBox(height: 10),

                // Time limit picker (как отдельная строка)
                TimeLimitPicker(
                  value: _timeLimit,
                  onChanged: (d) => setState(() => _timeLimit = d),
                ),

                const SizedBox(height: height16),

                  const FormFieldLabel('Car type'),
                  const SizedBox(height: 8),

                  VehicleSelector(
                    selected: _vehicleTypeUi,
                    onChanged: (v) => setState(() => _vehicleTypeUi = v),
                  ),

                const SizedBox(height: height24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : () => _submit(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonBackgroundColor,
                      foregroundColor: textMainColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickRouteFromList(BuildContext context) async {
    final selected = await Navigator.push<RouteEntity?>(
      context,
      MaterialPageRoute(
        builder: (_) => const RoutesListPage(selectionMode: true),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _route = selected);
    }
  }

  Future<DateTime?> _pickDateTime(BuildContext context, {DateTime? initial}) async {
    final now = DateTime.now();
    final init = initial ?? now;

    final date = await showDatePicker(
        context: context,
        initialDate: init,
        firstDate: now.subtract(const Duration(days: 1)),
        lastDate: now.add(const Duration(days: 365)));
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(init),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatDt(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y/$m/$d $hh:$mm';
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    if (_route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a route')),
      );
      return;
    }
    if (_startAt == null || _endAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select start and end time')),
      );
      return;
    }
    if (_endAt!.isBefore(_startAt!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final input = CompetitionInput(
        name: _nameCtrl.text,
        description: _descriptionCtrl.text,
        rulesText: _rule!.title,
        routeId: _route!.id,
        routeName: _route!.name,
        vehicleType: _vehicleTypeUi.toLowerCase(),
        startAt: _startAt!,
        endAt: _endAt!,
        // NOTE: если хочешь реально сохранять timeLimit —
        // добавь поле в CompetitionInput и прокинь сюда _timeLimit.
      );

      await ref.read(competitionsRepositoryProvider).createCompetition(input);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
