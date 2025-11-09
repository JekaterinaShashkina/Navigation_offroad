import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/images.dart';
import 'competition_rules_page.dart';

class CompetitionViewPage extends StatefulWidget {
  final String title;
  final String? description;
  final String initialRule;
  final DateTime? initialTime;

  const CompetitionViewPage({
    super.key,
    required this.title,
    this.description,
    this.initialRule = 'Fastest time',
    this.initialTime,
  });

  @override
  State<CompetitionViewPage> createState() => _CompetitionViewPageState();
}

class _CompetitionViewPageState extends State<CompetitionViewPage> {
  late final TextEditingController _name;
  late final TextEditingController _desc;

  String _rule = 'Fastest time';
  DateTime? _startTime;

  bool _descExpanded = true;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.title);
    _desc = TextEditingController(text: widget.description ?? _lorem);
    _rule = widget.initialRule;
    _startTime = widget.initialTime;
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
      appBar: AppBar(
        backgroundColor: backgroundMainColor,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(icon: arrowBackImage, onPressed: () => Navigator.pop(context)),
        title: const Text('Competition', style: head1TextStyle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          _label('Name'),
          _pillInput(_name, hint: 'Name'),
          const SizedBox(height: 12),

          _label('Description'),
          _descBox(),
          const SizedBox(height: 12),

          _label('Rules'),
          _navRow(
            title: _rule,
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF9AA2AE)),
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

          _pillInput(TextEditingController(text: 'Lorem ipsum')),
          const SizedBox(height: 12),

          _pillInput(TextEditingController(text: 'Lorem ipsum')),
          const SizedBox(height: 12),

          _label('Time'),
          _navRow(
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
            child: const Text('Start', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  /// UI helpers

  Widget _label(String t) => Text(
        t,
        style: const TextStyle(
          color: textMainColor,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      );

  Widget _pillInput(TextEditingController c, {String? hint}) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: hintTextStyle,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFE6E6EA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFE6E6EA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFD0D0D6)),
        ),
        filled: true,
        fillColor: surfaceColor,
      ),
    );
  }

  Widget _descBox() {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E6EA)),
        boxShadow: const [BoxShadow(color: Color(0x141A1A1A), blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Description',
                        style: TextStyle(fontWeight: FontWeight.w700, color: textMainColor)),
                  ),
                  Icon(_descExpanded ? Icons.expand_less : Icons.expand_more, color: const Color(0xFF9AA2AE)),
                ],
              ),
            ),
          ),
          if (_descExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: TextField(
                controller: _desc,
                maxLines: 6,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Description',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _navRow({required String title, Widget? leading, Widget? trailing, VoidCallback? onTap}) {
    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE6E6EA)),
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading, const SizedBox(width: 8)],
              Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}

const _lorem =
    'Lorem ipsum, or lipsum as it is sometimes known, is dummy text used in laying out print, '
    'graphic or web designs. In publishing and graphic design, Lorem ipsum is a placeholder text.';
