import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';

class AccordionCard extends StatelessWidget {
  const AccordionCard({
    super.key,
    required this.title,
    required this.child,
    this.count,
    this.initiallyExpanded = false,
  });

  final String title;
  final int? count;
  final bool initiallyExpanded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final titleText = (count == null) ? title : '$title ($count)';

    return Card(
      elevation: 0,
      color: backgroundMainColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide.none,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          title: Text(titleText),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: [child],
        ),
      ),
    );
  }
}
