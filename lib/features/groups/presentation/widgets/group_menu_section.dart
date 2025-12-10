import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';

class GroupMenuSection extends StatelessWidget {
  const GroupMenuSection({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: padding16,
        vertical: padding8,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(radius12),
        border: Border.all(color: listShadowColor, width: 1),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: enabled ? textMainColor : textHintColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: fontSize16,
            fontWeight: FontWeight.w500,
            color: enabled ? textMainColor : textHintColor,
          ),
        ),
        trailing: enabled
            ? const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: textHintColor,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
