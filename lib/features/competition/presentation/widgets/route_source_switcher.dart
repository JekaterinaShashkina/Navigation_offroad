import 'package:flutter/material.dart';

enum RouteSource { choose, create }

class RouteSourceSwitcher extends StatelessWidget {
  final RouteSource value;
  final ValueChanged<RouteSource> onChanged;

  const RouteSourceSwitcher({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget btn(String label, RouteSource s, {required bool selected}) {
      return Expanded(
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: () => onChanged(s),
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
        btn(
          'Choose route',
          RouteSource.choose,
          selected: value == RouteSource.choose,
        ),
        const SizedBox(width: 12),
        btn(
          'Create route',
          RouteSource.create,
          selected: value == RouteSource.create,
        ),
      ],
    );
  }
}
