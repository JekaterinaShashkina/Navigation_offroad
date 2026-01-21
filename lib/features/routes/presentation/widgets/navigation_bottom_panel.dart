import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';

class NavigationBottomPanel extends StatelessWidget {
  final String timeText;
  final String distanceText;
  final VoidCallback? onGo;
  final VoidCallback onClose;
  final bool showPrimaryButton;

  const NavigationBottomPanel({
    super.key,
    required this.timeText,
    required this.distanceText,
    this.onGo,
    required this.onClose,
    this.showPrimaryButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(radius24),
          topRight: Radius.circular(radius24),
        ),
        boxShadow: [
          BoxShadow(
            color: textMainColor.withOpacity(0.1),
            blurRadius: radius12,
          )
        ],
      ),
      child: Row(
        children: [
          // close btn
          InkWell(
            onTap: onClose,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: surfaceColor,
                      border: Border.all(
                      color: buttonSecondBackgroundColor,   // цвет обводки
                      width: 2,             // толщина
                    ),
              ),
              child: const Icon(Icons.close),
            ),
          ),
          const SizedBox(width: width16),

          // time + distance
          Expanded(
            child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeText,
                  style: const TextStyle(
                    fontSize: fontSize20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  distanceText,
                  style: const TextStyle(color: buttonSecondBackgroundColor),
                ),
              ],
            ),
            ),
          ),
          if (showPrimaryButton)
            ElevatedButton(
              onPressed: onGo,
              style: ElevatedButton.styleFrom(
                backgroundColor: chipBgColor,
                foregroundColor: textMainColor,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(18),
              ),
              child: const Text("GO"),
            )
        ],
      ),
    );
  }
}
