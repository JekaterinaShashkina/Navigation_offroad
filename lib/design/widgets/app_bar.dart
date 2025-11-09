import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/images.dart';
import 'package:offroad_nav/design/styles.dart';

class NewAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final VoidCallback onPressed;

  const NewAppBar({
    super.key,
    this.title,
    this.titleWidget,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!, style: head1TextStyle) : null),
      centerTitle: true,
      backgroundColor: surfaceColor,
      leading: IconButton(onPressed: onPressed, icon: arrowBackImage),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}