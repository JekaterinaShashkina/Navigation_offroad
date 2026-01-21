import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';

class BellButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const BellButton({
    super.key,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: surfaceColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: textMainColor,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.notifications_none_rounded,
                color: textMainColor,
              ),
            ),
            if (count > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: const BoxDecoration(
                    color: chipBgColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                      color: surfaceColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
