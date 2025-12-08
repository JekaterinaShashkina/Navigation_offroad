import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';

class ExpandableDescriptionBox extends StatefulWidget {
  final TextEditingController controller;
  final String title;
  final bool initiallyExpanded;

  const ExpandableDescriptionBox({
    super.key,
    required this.controller,
    this.title = 'Description',
    this.initiallyExpanded = true,
  });

  @override
  State<ExpandableDescriptionBox> createState() =>
      _ExpandableDescriptionBoxState();
}

class _ExpandableDescriptionBoxState extends State<ExpandableDescriptionBox> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E6EA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141A1A1A),
            blurRadius: 16,
            offset: Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: textMainColor,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF9AA2AE),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: TextField(
                controller: widget.controller,
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
}
