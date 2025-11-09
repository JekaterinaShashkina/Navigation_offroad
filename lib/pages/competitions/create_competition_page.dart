// lib/pages/competitions/create_competition_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/styles.dart';

/// Иконки 
const kAtvIcon   = 'assets/images/atv_icon.png';
const kJeepIcon  = 'assets/images/jeep_icon.png';
const kTruckIcon = 'assets/images/truck_icon.png';

class CreateCompetitionPage extends StatefulWidget {
  const CreateCompetitionPage({super.key});

  @override
  State<CreateCompetitionPage> createState() => _CreateCompetitionPageState();
}

class _CreateCompetitionPageState extends State<CreateCompetitionPage> {
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
  _RouteMode _mode = _RouteMode.drive;

  bool _submitting = false;

  @override
  void dispose() {
    _name
      ..dispose();
    _desc
      ..dispose();
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

  // ---------- Firestore ----------
  Future<void> _create() async {
    if (_submitting) return;
    if (!_form.currentState!.validate()) return;

    final me = FirebaseAuth.instance.currentUser;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await FirebaseFirestore.instance.collection('competitions').add({
        'title'        : _name.text.trim(),
        'description'  : _desc.text.trim(),
        'rule'         : _rule,
        'start_time'   : _startTime != null ? Timestamp.fromDate(_startTime!) : null,
        'use_limit'    : _useLimit,
        'limit_minutes': _useLimit ? _limit.inMinutes : null,
        'vehicle'      : _vehicle, // 'ATV' | 'Jeep' | 'Truck'
        'owner_id'     : me.uid,
        'status'       : 'draft',
        'created_at'   : FieldValue.serverTimestamp(),
        'updated_at'   : FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Competition created')),
      );
      Navigator.pop(context);
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
      appBar: AppBar(
        backgroundColor: backgroundMainColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textMainColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create a competition', style: head1TextStyle),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            _fieldLabel('Name'),
            _textField50(
              controller: _name,
              hint: 'Lorem ipsum',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),

            _fieldLabel('Description'),
            _textField50(controller: _desc, hint: 'Lorem ipsum'),
            const SizedBox(height: 12),

            _fieldLabel('Rules'),
            _box50(
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

            _fieldLabel('Time'),
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _pickStartTime,
              child: _box50(
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
                Expanded(child: _fieldLabel('Time limit')),
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
                child: _box50(
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

            _fieldLabel('Car type'),
            const SizedBox(height: 8),
            Row(
              children: [
                _vehicleCard('ATV',   kAtvIcon),
                const SizedBox(width: 12),
                _vehicleCard('Jeep',  kJeepIcon),
                const SizedBox(width: 12),
                _vehicleCard('Truck', kTruckIcon),
              ],
            ),
            const SizedBox(height: 24),

            _fieldLabel('Make a route'),
            const SizedBox(height: 8),
            _routeModeSwitcher(),
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

  // ===== helpers =====

  InputDecoration _dec(String? hint) => InputDecoration(
        hintText: hint,
        hintStyle: hintTextStyle,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: surfaceColor,
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
      );

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: textMainColor,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      );

  /// Поле ввода фиксированной высоты 50px 
  Widget _textField50({
    required TextEditingController controller,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      height: 50,
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: 1,
        decoration: _dec(hint),
      ),
    );
  }

  /// Контейнер с бордюром и высотой 50px 
  Widget _box50({required Widget child}) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6E6EA)),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  /// Универсальный рендер ассета (PNG/JPG/SVG)
  Widget _assetIcon(String path, {double size = 28}) {
    final p = path.toLowerCase();
    if (p.endsWith('.svg')) {
      return SvgPicture.asset(path, width: size, height: size);
    }
    return Image.asset(path, width: size, height: size, fit: BoxFit.contain);
  

  }

  Widget _vehicleCard(String value, String asset) {
    final selected = _vehicle == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _vehicle = value),
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? buttonSecondBackgroundColor : const Color(0xFFE6E6EA),
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x141A1A1A), blurRadius: 16, offset: Offset(0, 8)),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 32, child: Center(child: _assetIcon(asset, size: 28))),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? buttonSecondBackgroundColor : textMainColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //  Route mode switcher 
  Widget _routeModeSwitcher() {
    Widget btn(String label, _RouteMode m, {required bool selected}) {
      return Expanded(
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: () => setState(() => _mode = m),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: const StadiumBorder(),
              backgroundColor: selected ? const Color(0xFFF4C84A) : Colors.black,
              foregroundColor: selected ? Colors.black : Colors.white,
            ),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      );
    }

    return Row(
      children: [
        btn('Drive', _RouteMode.drive, selected: _mode == _RouteMode.drive),
        const SizedBox(width: 12),
        btn('Waypoints', _RouteMode.waypoints, selected: _mode == _RouteMode.waypoints),
      ],
    );
  }
}

enum _RouteMode { drive, waypoints }
