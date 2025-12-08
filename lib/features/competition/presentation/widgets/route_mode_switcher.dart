import 'package:flutter/material.dart';

class RouteModeSwitcher extends StatelessWidget {
  final RouteMode value;
  final ValueChanged<RouteMode> onChanged;

  const RouteModeSwitcher({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget btn(String label, RouteMode m, {required bool selected}) {
      return Expanded(
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: () => onChanged(m),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: const StadiumBorder(),
              backgroundColor:
                  selected ? const Color(0xFFF4C84A) : Colors.black,
              foregroundColor: selected ? Colors.black : Colors.white,
            ),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        btn('Drive', RouteMode.drive, selected: value == RouteMode.drive),
        const SizedBox(width: 12),
        btn('Waypoints', RouteMode.waypoints,
            selected: value == RouteMode.waypoints),
      ],
    );
  }
}

enum RouteMode { drive, waypoints }
