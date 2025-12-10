import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/images.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/models/country_code.dart';
import 'package:offroad_nav/utils/validators.dart';

class PhoneInputField extends StatefulWidget {
  final TextEditingController? controller;
  final List<CountryCode> items;
  final String initialDialCode;
  final ValueChanged<String>? onDialCodeChanged;
  final Widget? arrow;

  const PhoneInputField({
    super.key,
    this.controller,
    this.initialDialCode = '+372',
    this.onDialCodeChanged,
    required this.items,
    this.arrow,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late String _selectedDialCode;

  @override
  void initState() {
    super.initState();
    _selectedDialCode = widget.initialDialCode;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: padding16),
      decoration: BoxDecoration(
        color: backgroundMainColor,
        borderRadius: BorderRadius.circular(radius24),
      ),
      child: Row(
        children: [
          // Префикс страны
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDialCode,
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selectedDialCode = v);
                widget.onDialCodeChanged?.call(v);
              },
              items: widget.items.map((c) {
                return DropdownMenuItem(
                  value: c.dialCode,
                  child: Text(c.dialCode),
                );
              }).toList(),
              icon: Padding(
                padding: const EdgeInsets.only(
                  left: padding6,
                ), // ← сдвигаем стрелку
                child: widget.arrow ?? const Icon(Icons.arrow_drop_down),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextFormField(
              controller: widget.controller,
              style: bodyTextStyle,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: "Phonenumber",
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: padding16,
                ),
                border: InputBorder.none, // убрали стандартный underline
                enabledBorder:
                    InputBorder.none, // убрали в неактивном состоянии
                focusedBorder: InputBorder.none, // убрали в активном состоянии
                disabledBorder: InputBorder.none, // убрали если отключено
              ),
              validator: Validators.compose([
                Validators.required('Enter phone'),
                Validators.minLength(5), // или свой RegExp
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
