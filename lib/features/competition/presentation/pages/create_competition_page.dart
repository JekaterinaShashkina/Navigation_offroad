import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/competition_form_fields.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/create_competition_action.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/route_mode_switcher.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/route_source_switcher.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/time_limit_picker.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/vehicle_selector.dart';
import 'package:offroad_nav/features/routes/domain/entities/route_entity.dart';
import 'package:offroad_nav/features/routes/presentation/pages/route_creation_page.dart';
import 'package:offroad_nav/features/routes/presentation/pages/route_planner_page.dart';
import 'package:offroad_nav/features/routes/presentation/pages/routes_list_page.dart';

class CreateCompetitionPage extends ConsumerStatefulWidget {
  const CreateCompetitionPage({super.key});

  @override
  ConsumerState<CreateCompetitionPage> createState() => _CreateCompetitionPageState();
}

class _CreateCompetitionPageState extends ConsumerState<CreateCompetitionPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  RouteSource _routeSource = RouteSource.choose;
  RouteEntity? _selectedRoute;

  // Rules
  final _rules = const <String>[
    'Fastest time',
    'Most waypoints',
    'Checkpoint hunt',
  ];
  String _rule = 'Fastest time';

  // Start time + limit
  DateTime? _startTime;
  bool _useLimit = false;
  Duration _limit = const Duration(hours: 1);

  // Vehicle
  String _vehicle = 'ATV';

  // Route mode 
  RouteMode _mode = RouteMode.drive;

  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  // ---------- pickers ----------
  Future<void> _pickStartTime() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _startTime ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (d == null) return;

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime ?? now),
    );
    if (t == null) return;

    setState(() {
      _startTime = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<RouteEntity?> _openChooseRoute() async {
  final route = await Navigator.push<RouteEntity>(
    context,
    MaterialPageRoute(
      builder: (_) => const RoutesListPage(
        selectionMode: true, // важно, чтобы страница возвращала RouteEntity
      ),
    ),
  );
  return route;
}

 // ---------- Create competition----------
Future<void> _create() async {
  if (_submitting) return;

  await submitCompetition(
    ref: ref,
    context: context,
    formKey: _form,
    nameCtrl: _name,
    descCtrl: _desc,
    rule: _rule,
    startTime: _startTime,
    useLimit: _useLimit,
    limit: _limit,
    vehicle: _vehicle,
    setSubmitting: (v) => setState(() => _submitting = v),
  );
}

Widget _buildRouteModeSheet() {
  return SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Create route',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),

        ListTile(
          title: const Text('Drive'),
          leading: const Icon(Icons.directions_car),
          onTap: () => Navigator.pop(context, RouteMode.drive),
        ),

        ListTile(
          title: const Text('Waypoints'),
          leading: const Icon(Icons.pin_drop_outlined),
          onTap: () => Navigator.pop(context, RouteMode.waypoints),
        ),

        const SizedBox(height: 12),
      ],
    ),
  );
}


  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: 'Create a competition', onPressed: () => Navigator.pop(context),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            FormFieldLabel('Name'),
            PillTextField(
              controller: _name,
              hint: 'Lorem ipsum',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),

            FormFieldLabel('Description'),
            PillTextField(controller: _desc, hint: 'Lorem ipsum'),
            const SizedBox(height: 12),

            FormFieldLabel('Rules'),
            PillBox(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _rule,
                  isExpanded: true,
                  items: _rules
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => _rule = v ?? _rule),
                ),
              ),
            ),
            const SizedBox(height: 12),

            FormFieldLabel('Time'),
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _pickStartTime,
              child: PillBox(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _startTime == null
                            ? 'Pick start date & time'
                            : _startTime!.toLocal().toString().substring(0, 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.schedule_rounded, color: textHintColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: FormFieldLabel('Time limit')),
                Switch(
                  value: _useLimit,
                  activeColor: buttonSecondBackgroundColor,
                  onChanged: (v) => setState(() => _useLimit = v),
                ),
              ],
            ),
            if (_useLimit) ...[
              TimeLimitPicker(
                value: _limit,
                onChanged: (d) => setState(() => _limit = d),
              ),
              const SizedBox(height: 12),
            ],

            FormFieldLabel('Car type'),
            const SizedBox(height: 8),
            VehicleSelector(
                  selected: _vehicle, 
                  onChanged: (value) => setState(() => _vehicle = value)
                ),
            const SizedBox(height: 24),

            FormFieldLabel('Make a route'),
            const SizedBox(height: 8),
            RouteSourceSwitcher(
                value: _routeSource,
                onChanged: (s) async {
                  setState(() => _routeSource = s);

                  if (s == RouteSource.choose) {
                    // Открываем список маршрутов
                    final route = await _openChooseRoute();
                    if (!mounted || route == null) return;
                    setState(() => _selectedRoute = route);
                  } else {
                    // Открываем флоу создания маршрута (Drive / Waypoints)
                    final route = await _openCreateRouteFlow();
                    if (!mounted || route == null) return;
                    setState(() => _selectedRoute = route);
                  }
                },
            ),
            if (_selectedRoute != null) ...[
              const SizedBox(height: 8),
              Text(
                'Selected route: ${_selectedRoute!.name}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),

      // нижняя кнопка Create
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _submitting ? null : _onCreatePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonSecondBackgroundColor,
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: _submitting
                ? const SizedBox(
                    height: 18, width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  Future<RouteEntity?> _openCreateRouteFlow() async {
  // тут можно показать bottom sheet с выбором:
  // Drive / Waypoints
  final mode = await showModalBottomSheet<RouteMode>(
    context: context,
    shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
    builder: (_) => _buildRouteModeSheet(), // или просто два ListTile
  );

  if (mode == null) return null;

  if (mode == RouteMode.drive) {
    // открыть экран записи маршрута
    final route = await Navigator.push<RouteEntity>(
      context,
      MaterialPageRoute(
        builder: (_) => const RouteCreationPage(
          // сделай там Navigator.pop(context, createdRoute);
        ),
      ),
    );
    return route;
  } else {
    // открыть экран планировщика точками
    final route = await Navigator.push<RouteEntity>(
      context,
      MaterialPageRoute(
        builder: (_) => const RoutePlannerPage(
          // и там тоже вернуть RouteEntity через Navigator.pop
        ),
      ),
    );
    return route;
  }
}

  Future<void> _onCreatePressed() async {
  if (_submitting) return;

  if (_selectedRoute == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please choose or create a route')),
    );
    return;
  }

  await _create(); // здесь уже submitCompetition
}

}
