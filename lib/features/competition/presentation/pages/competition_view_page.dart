import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/competition_form_fields.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/expandable_description_box.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/pill_nav_row.dart';

import 'competition_rules_page.dart';

class CompetitionViewPage extends StatefulWidget {
  final Competition competition;
  
  const CompetitionViewPage({
    super.key, 
    required this.competition,
    
  });

  @override
  State<CompetitionViewPage> createState() => _CompetitionViewPageState();
}

class _CompetitionViewPageState extends State<CompetitionViewPage> {
  static const String _fallbackDescription =
      'Lorem ipsum, or lipsum as it is sometimes known, is dummy text used in laying out print, '
      'graphic or web designs. In publishing and graphic design, Lorem ipsum is a placeholder text.';

  late final TextEditingController _name;
  late final TextEditingController _desc;

  late String _rule;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    final c = widget.competition;

    _name = TextEditingController(text: c.title);
    _desc = TextEditingController(text: c.description ?? _fallbackDescription);
    _rule = c.rule;
    _startTime = c.startTime;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: 'Competition', onPressed: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          const FormFieldLabel('Name'),
          PillTextField(
            controller: _name,
            hint: 'Name',
          ),
          const SizedBox(height: 12),

          const FormFieldLabel('Description'),
          ExpandableDescriptionBox(
            controller: _desc,
          ),
          const SizedBox(height: 12),

          const FormFieldLabel('Rules'),
          PillNavRow(
            title: _rule,
            trailing:
                const Icon(Icons.chevron_right, color: Color(0xFF9AA2AE)),
            onTap: () async {
              final selected = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (_) => CompetitionRulesPage(current: _rule),
                ),
              );
              if (selected != null) setState(() => _rule = selected);
            },
          ),
          const SizedBox(height: 12),

          const FormFieldLabel('Time'),
          PillNavRow(
            title: _startTime == null
                ? 'Pick date & time'
                : _startTime!.toLocal().toString().substring(0, 16),
            leading: const Icon(Icons.schedule, color: Color(0xFF9AA2AE)),
            onTap: _pickTime,
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              // позже здесь будет старт/апдейт статуса
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Start: coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF4C84A),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'Start',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }


}