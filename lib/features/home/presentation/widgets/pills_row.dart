import 'package:flutter/material.dart';
import 'package:offroad_nav/design/widgets/pill.dart'; 

class PillsRow extends StatelessWidget {
  const PillsRow({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    this.gap = 10,
    this.scrollable = false,
  });

  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  final double gap;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final children = List.generate(items.length, (i) {
      return Pill(
        text: items[i],
        selected: i == selectedIndex,
        onTap: () => onSelect(i),
        // тут всё уже в стиле routes по дефолту
      );
    });

    if (scrollable) {
      return SizedBox(
        height: 44, // чтобы не прыгало
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: children.length,
          separatorBuilder: (_, __) => SizedBox(width: gap),
          itemBuilder: (_, i) => children[i],
        ),
      );
    }

    return Row(
      children: List.generate(children.length, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == children.length - 1 ? 0 : gap),
            child: children[i],
          ),
        );
      }),
    );
  }
}
