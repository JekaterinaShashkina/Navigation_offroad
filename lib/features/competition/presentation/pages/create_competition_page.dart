import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/features/competition/application/providers/competitions_providers.dart';
import 'package:offroad_nav/features/competition/data/repositories/competitions_repository.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/competition_form_fields.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/route_mode_switcher.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/vehicle_selector.dart';

class CreateCompetitionPage extends ConsumerStatefulWidget {
  const CreateCompetitionPage({super.key});

  @override
  ConsumerState<CreateCompetitionPage> createState() => _CreateCompetitionPageState();
}

class _CreateCompetitionPageState extends ConsumerState<CreateCompetitionPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();

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

  Future<void> _pickLimit() async {
    final options = <Duration>[
      const Duration(minutes: 30),
      const Duration(hours: 1),
      const Duration(hours: 2),
      const Duration(hours: 3),
    ];
    final res = await showModalBottomSheet<Duration>(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Time limit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          for (final d in options)
            ListTile(
              title: Text('${d.inHours > 0 ? '${d.inHours}h ' : ''}${d.inMinutes % 60}m'),
              onTap: () => Navigator.pop(context, d),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
    if (res != null) setState(() => _limit = res);
  }

  // ---------- submit через репозиторий ----------
  Future<void> _create() async {
    if (_submitting) return;
    if (!_form.currentState!.validate()) return;

    final repo = ref.read(competitionsRepositoryProvider);

    setState(() => _submitting = true);
    try {
      await repo.createCompetition(
        CompetitionCreateParams(
          title: _name.text,
          description: _desc.text,
          rule: _rule,
          startTime: _startTime,
          useLimit: _useLimit,
          limit: _useLimit ? _limit : null,
          vehicle: _vehicle,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Competition created')),
      );
      Navigator.pop(context);
    } on UnauthenticatedCompetitionException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _pickLimit,
                child: PillBox(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_limit.inHours > 0 ? '${_limit.inHours}h ' : ''}${_limit.inMinutes % 60}m',
                        ),
                      ),
                      const Icon(Icons.timer_rounded, color: textHintColor),
                    ],
                  ),
                ),
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
            RouteModeSwitcher(
              value: _mode, 
              onChanged: (m) => setState(() => _mode = m),

            ),
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
            onPressed: _submitting ? null : _create,
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
}
