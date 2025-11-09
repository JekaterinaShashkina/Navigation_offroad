import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:offroad_nav/design/colors.dart';

class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    this.path,
    this.radius = 44,
    this.onTap,
    this.placeholder,
  });

  /// asset-путь до svg; если null/пусто — показываем плейсхолдер.
  final String? path;
  final double radius;
  final VoidCallback? onTap;

  /// Виджет по умолчанию (если path пуст). Если не передан — иконка камеры.
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = path != null && path!.isNotEmpty;

    final child = hasAvatar
        ? SvgPicture.asset(path!, width: radius * 2, height: radius * 2)
        : (placeholder ??
            Icon(Icons.camera_alt, size: radius, color: Theme.of(context).primaryColorDark));

    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: backgroundMainColor,
        child: child,
      ),
    );
  }
}
