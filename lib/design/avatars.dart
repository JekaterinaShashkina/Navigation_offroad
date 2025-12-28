import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:offroad_nav/design/colors.dart';

/// Все доступные svg-аватары (пути из assets).
const List<String> userAvatarPaths = [
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

const List<String> groupAvatarPaths = [
  'assets/images/groups_avatars/avatar_1.png',
  'assets/images/groups_avatars/avatar_2.png',
  'assets/images/groups_avatars/avatar_3.png',
  'assets/images/groups_avatars/avatar_4.png',
  'assets/images/groups_avatars/avatar_5.png',
  'assets/images/groups_avatars/avatar_6.png'
];

// /// Удобный виджет для отрисовки любого svg-аватара.
// Widget avatarSvg(String path, {double size = 40}) =>
//     SvgPicture.asset(path, width: size, height: size);

Widget avatarPreview(String path, {double size = 40}) {
  final p = path.trim().toLowerCase();

  // SVG
  if (p.endsWith('.svg')) {
    return SvgPicture.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholderBuilder: (_) => SizedBox(
        width: size,
        height: size,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }

  // PNG/JPG/WebP
  return Image.asset(
    path,
    width: size,
    height: size,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => SizedBox(
      width: size,
      height: size,
      child: const Icon(Icons.image_not_supported),
    ),
  );
}


Future<String?> showUserAvatarPicker(BuildContext context) =>
  showAvatarPicker(context, avatars: userAvatarPaths);

Future<String?> showGroupAvatarPicker(BuildContext context) =>
  showAvatarPicker(context, avatars: groupAvatarPaths);

/// Диалог выбора аватара. Возвращает выбранный asset-путь или null.
Future<String?> showAvatarPicker(
  BuildContext context, {
      required List<String> avatars,      
      double itemSize = 44
    }) {
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
              for (final p in avatars)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(ctx).pop(p),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: backgroundMainColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: avatarPreview(p, size: itemSize),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
