import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:offroad_nav/design/colors.dart';

/// Универсальный круглый аватар:
/// - `src` может быть http(s) URL, локальный SVG или локальная картинка.
/// - при ошибке/пустом значении показывает `placeholder`.
class SmartAvatar extends StatelessWidget {
  const SmartAvatar({
    super.key,
    this.src,
    this.size = 88,
    this.placeholder,
    this.onTap,
    this.borderColor,
    this.borderWidth = 0,
    this.overlay, // например, иконка «камеры»
  });

  /// Путь/URL к изображению (может быть null/пустой).
  final String? src;

  /// Диаметр аватара.
  final double size;

  /// Что показать, если картинки нет/не загрузилась.
  final Widget? placeholder;

  /// Обработчик нажатия по аватару.
  final VoidCallback? onTap;

  /// Опциональная рамка.
  final Color? borderColor;
  final double borderWidth;

  /// Опциональный overlay (например иконка редактирования).
  final Widget? overlay;

  bool get _isEmpty => (src == null || src!.trim().isEmpty);

  @override
  Widget build(BuildContext context) {
    final child = _buildChild();

    Widget avatar = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: child,
      ),
    );

    if (borderWidth > 0 && borderColor != null) {
      avatar = Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor!, width: borderWidth),
        ),
        child: ClipOval(child: child),
      );
    }

    // Наложим overlay-виджет, если передан
    avatar = Stack(
      alignment: Alignment.center,
      children: [
        avatar,
        if (overlay != null) Positioned(bottom: 0, right: 0, child: overlay!),
      ],
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }
    return avatar;
  }

  Widget _buildChild() {
    if (_isEmpty) {
      return _placeholderBox();
    }

    final path = src!.trim();

    // Сетевое изображение
  if (path.startsWith('http')) {
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        path,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => _placeholderBox(),
      );
    }
    return Image.network(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholderBox(),
    );
  }

    // Локальный SVG
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => _placeholderBox(),
      );
    }

    // Локальный PNG/JPG/WebP и т.п.
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholderBox(),
    );
  }

  Widget _placeholderBox() {
    // если плейсхолдер не передан — простая «заглушка»
    return placeholder ??
        Container(
          color: surfaceColor,
          child: const Icon(Icons.person, color: textHintColor),
        );
  }
}
