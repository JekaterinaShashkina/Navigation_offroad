import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
    this.height = 50,
    this.backgroundColor,
    this.foregroundColor,
    this.secondaryBackground = false,
    this.radius = radius24,
    this.icon,
    this.loading = false,
    this.suffix,
  });

  final String text;
  final VoidCallback? onPressed;

  final double? width;
  final double height;
  final double radius;

  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool secondaryBackground;

  final Widget? icon;
  final bool loading;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final enabledBg = secondaryBackground
        ? buttonSecondBackgroundColor
        : (backgroundColor ?? buttonBackgroundColor);
    final enabledFg = foregroundColor ?? textMainColor;

    // цвета для disabled
    const disabledBg = surfaceColor;
    final disabledFg = textCustomColor;
    final disabledBorder = textCustomColor;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.disabled) ? disabledBg : enabledBg,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.disabled) ? disabledFg : enabledFg,
          ),
          // бордер появится только в disabled
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? BorderSide(color: disabledBorder, width: 1)
                : BorderSide.none,
          ),
          elevation: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled) ? 0 : 2,
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: fontSize18, fontWeight: FontWeight.w600),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,

                children: [
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            icon!,
                            const SizedBox(width: 8),
                          ],
                          Text(text, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),

                  if (suffix != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 26),
                      child: FittedBox(fit: BoxFit.scaleDown, child: suffix!),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Отдельный виджет, чтобы не перехватывать тап и иметь паддинг справа
class _SuffixAligner extends StatelessWidget {
  const _SuffixAligner();

  @override
  Widget build(BuildContext context) {
    final parent = context.findAncestorWidgetOfExactType<AppButton>()!;
    final suffix = (parent as dynamic).suffix as Widget?;
    if (suffix == null) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: IgnorePointer(child: suffix),
      ),
    );
  }
}
