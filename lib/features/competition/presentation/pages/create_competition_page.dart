import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/features/competition/application/providers/competitions_providers.dart';
import 'package:offroad_nav/features/competition/data/repositories/competitions_repository.dart';
import 'package:offroad_nav/features/routes/domain/entities/route_entity.dart';
import 'package:offroad_nav/features/routes/presentation/controller/routes_controller.dart';
import 'package:offroad_nav/features/routes/presentation/pages/routes_list_page.dart';

class CreateCompetitionPage extends ConsumerStatefulWidget {
  const CreateCompetitionPage({super.key});

  @override
  ConsumerState<CreateCompetitionPage> createState() => _CreateCompetitionPageState();
}

class _CreateCompetitionPageState extends ConsumerState<CreateCompetitionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _rulesCtrl = TextEditingController(text: 'Fastest time wins');

  RouteEntity? _route;
  DateTime? _startAt;
  DateTime? _endAt;
  bool _saving = false;


  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _rulesCtrl.dispose();
    super.dispose();
  }

   // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final routesState = ref.watch(routesControllerProvider);
    
    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: 'Create competition',
        onPressed: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(padding16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
              ),
              const SizedBox(height: height12),
              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),

              const SizedBox(height: height12),
              TextFormField(
                controller: _rulesCtrl,
                decoration: const InputDecoration(labelText: 'Rules'),
                maxLines: 3,
              ),

              const SizedBox(height: height12),
              _RouteSelector(
                selected: _route,
                routes: routesState.routes,
                onSelect: (route) => setState(() => _route = route),
                onPickFromList: () async {
                  final selected = await Navigator.push<RouteEntity?>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RoutesListPage(selectionMode: true),
                    ),
                  );
                  if (selected != null && mounted) {
                    setState(() => _route = selected);
                  }
                },

              ),
              const SizedBox(height: height12),
              _DateTimeField(
                label: 'Start time',
                value: _startAt,
                onChanged: (value) => setState(() => _startAt = value),
              ),
              const SizedBox(height: height12),
              _DateTimeField(
                label: 'End time',
                value: _endAt,
                onChanged: (value) => setState(() => _endAt = value),
              ),
              const SizedBox(height: height24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : () => _submit(context),
                  style: ElevatedButton.styleFrom(backgroundColor: textHintColor, foregroundColor: Colors.black),
                  child: _saving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),


              ),
            ],
            
          ),
        ),
      ),
    );
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
        rulesText: _rulesCtrl.text,
        routeId: _route!.id,
        startAt: _startAt!,
        endAt: _endAt!,
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

class _RouteSelector extends StatelessWidget {
  final RouteEntity? selected;
  final List<RouteEntity> routes;
  final ValueChanged<RouteEntity> onSelect;
  final VoidCallback onPickFromList;

  const _RouteSelector({
    required this.selected,
    required this.routes,
    required this.onSelect,
    required this.onPickFromList,
  });

    @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Route', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton(onPressed: onPickFromList, child: const Text('Browse routes')),
          ],

        ),

        DropdownButtonFormField<RouteEntity>(
          value: selected,
          decoration: const InputDecoration(hintText: 'Select route'),
          items: routes
              .map(
                (r) => DropdownMenuItem<RouteEntity>(
                  value: r,
                  child: Text(r.name),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onSelect(value);
          },
          validator: (value) => value == null ? 'Select route' : null,
          // и там тоже вернуть RouteEntity через Navigator.pop
        ),
      ]

      );
  }
}

class _DateTimeField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onChanged,
  });
    @override
  Widget build(BuildContext context) {
    final text = value == null
        ? 'Select...'
        : '${value!.year}/${value!.month.toString().padLeft(2, '0')}/${value!.day.toString().padLeft(2, '0')} ${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}';

    return ListTile(
      tileColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius12)),
      title: Text(label),
      subtitle: Text(text, style: hintTextStyle.copyWith(color: textHintColor)),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date == null) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value ?? DateTime.now()),
        );
        if (time == null) return;

        final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        onChanged(dt);
      },

     );
  }
}
