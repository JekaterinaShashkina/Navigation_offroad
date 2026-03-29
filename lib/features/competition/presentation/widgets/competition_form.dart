import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/pill_picker.dart';

import 'package:offroad_nav/features/competition/data/repositories/competitions_repository.dart';
import 'package:offroad_nav/features/competition/domain/config/competition_rules.dart';
import 'package:offroad_nav/features/competition/domain/config/competition_rules.dart'
    show CompetitionRule;
import 'package:offroad_nav/features/competition/domain/entities/competition.dart';
import 'package:offroad_nav/features/competition/presentation/pages/competition_rules_page.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/vehicle_selector.dart';

import 'package:offroad_nav/features/routes/domain/entities/route_entity.dart';
import 'package:offroad_nav/features/routes/presentation/controller/routes_controller.dart';
import 'package:offroad_nav/features/routes/presentation/pages/routes_list_page.dart';

import 'package:offroad_nav/design/widgets/pill_nav_row.dart';
import 'package:offroad_nav/design/widgets/form_fields_label.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/time_limit_picker.dart';

class CompetitionForm extends ConsumerStatefulWidget {
  final String submitLabel;
  final Future<void> Function(CompetitionInput input) onSubmit;

  /// Если не null — это редактирование (prefill полей)
  final Competition? initial;

  const CompetitionForm({
    super.key,
    required this.submitLabel,
    required this.onSubmit,
    this.initial,
  });

  @override
  ConsumerState<CompetitionForm> createState() => _CompetitionFormState();
}

class _CompetitionFormState extends ConsumerState<CompetitionForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  CompetitionRule? _rule;

  RouteEntity? _route;
  DateTime? _startAt;
  DateTime? _endAt;

  Duration _timeLimit = const Duration(hours: 1);
  bool _saving = false;

  String _vehicleTypeUi = 'ATV';

  @override
  void initState() {
    super.initState();

    final c = widget.initial;
    if (c == null) return;

    _nameCtrl.text = c.name;
    _descriptionCtrl.text = c.description;

    _startAt = c.startAt;
    _endAt = c.endAt;

    _vehicleTypeUi = (c.vehicleType ?? 'atv').toUpperCase();

    // rule: ищем по title (потому что rulesText ты сохраняла как title)
    _rule = competitionRules.firstWhere(
      (r) => r.title == c.rulesText,
      orElse: () => competitionRules.first,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routesState = ref.watch(routesControllerProvider);

    // --- EDIT PREFILL: подставляем выбранный RouteEntity по routeId ---
    // Чтобы PillPicker показал текущий маршрут в edit режиме.
    final initRouteId = widget.initial?.routeId;
    if (_route == null &&
        initRouteId != null &&
        routesState.routes.isNotEmpty) {
      final match = routesState.routes.cast<RouteEntity?>().firstWhere(
        (r) => r?.id == initRouteId,
        orElse: () => null,
      );

      if (match != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          // на случай, если пользователь уже успел выбрать маршрут вручную
          if (_route == null) setState(() => _route = match);
        });
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          padding16,
          padding12,
          padding16,
          padding24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FormFieldLabel('Name'),
              const SizedBox(height: 8),
              PillTextField(
                controller: _nameCtrl,
                hint: 'Enter competition name',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter name' : null,
              ),
              const SizedBox(height: height16),

              const FormFieldLabel('Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 3,
                decoration: pillInputDecoration('Enter description'),
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
                        MaterialPageRoute(
                          builder: (_) => const CompetitionRulesPage(),
                        ),
                      );
                    },
                    child: const Text('Rules'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              PillPicker<CompetitionRule>(
                placeholder: 'Select rule',
                items: competitionRules,
                selected: _rule,
                idOf: (r) => r.id,
                titleOf: (r) => r.title,
                subtitleOf: (r) => r.description,
                onSelect: (r) {
                  if (!r.enabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('This rule is coming soon')),
                    );
                    return;
                  }
                  setState(() => _rule = r);
                },
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
                placeholder: 'Select route',
                items: routesState.routes,
                selected: _route,
                titleOf: (r) => r.name,
                idOf: (r) => r.id,
                sheetTitle: 'Select route',
                onSelect: (r) => setState(() => _route = r),
              ),

              const SizedBox(height: height16),
              const FormFieldLabel('Time'),
              const SizedBox(height: 8),

              PillNavRow(
                title: _startAt == null
                    ? 'Start time'
                    : 'Start: ${_formatDt(_startAt!)}',
                trailing: const Icon(
                  Icons.calendar_month_rounded,
                  color: textHintColor,
                ),
                onTap: () async {
                  final dt = await _pickDateTime(context, initial: _startAt);
                  if (dt != null) setState(() => _startAt = dt);
                },
              ),
              const SizedBox(height: 10),

              PillNavRow(
                title: _endAt == null
                    ? 'End time'
                    : 'End: ${_formatDt(_endAt!)}',
                trailing: const Icon(
                  Icons.calendar_month_rounded,
                  color: textHintColor,
                ),
                onTap: () async {
                  final dt = await _pickDateTime(context, initial: _endAt);
                  if (dt != null) setState(() => _endAt = dt);
                },
              ),
              const SizedBox(height: 10),

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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.submitLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
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

  Future<DateTime?> _pickDateTime(
    BuildContext context, {
    DateTime? initial,
  }) async {
    final now = DateTime.now();
    final init = initial ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
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

    if (_rule == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a rule')));
      return;
    }

    if (_route == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a route')));
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
      );

      await widget.onSubmit(input);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
