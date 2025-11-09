import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:offroad_nav/design/colors.dart';

/// Все доступные svg-аватары (пути из assets).
const List<String> kAvatarPaths = [
  'assets/images/avatar_boy_01.svg',
  'assets/images/avatar_boy_02.svg',
  'assets/images/avatar_boy_03.svg',
  'assets/images/avatar_boy_04.svg',
  'assets/images/avatar_boy_05.svg',
  'assets/images/avatar_girl_01.svg',
  'assets/images/avatar_girl_02.svg',
  'assets/images/avatar_girl_03.svg',
  'assets/images/avatar_girl_04.svg',
  'assets/images/avatar_girl_05.svg',
];

/// Удобный виджет для отрисовки любого svg-аватара.
Widget avatarSvg(String path, {double size = 40}) =>
    SvgPicture.asset(path, width: size, height: size);

/// Диалог выбора аватара. Возвращает выбранный asset-путь или null.
Future<String?> showAvatarPicker(BuildContext context,
    {double itemSize = 44}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final p in kAvatarPaths)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(ctx).pop(p),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: backgroundMainColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: avatarSvg(p, size: itemSize),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
