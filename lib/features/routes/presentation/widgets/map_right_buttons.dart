import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';

class MapRightButtons extends StatelessWidget {
  final VoidCallback onCenter;
  final VoidCallback onNorth;

  const MapRightButtons({
    super.key,
    required this.onCenter,
    required this.onNorth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _circleBtn(Icons.explore, onNorth),     // компас
        const SizedBox(height: height12),
        _circleBtn(Icons.my_location, onCenter), // центрирование
      ],
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius32),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: surfaceColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: textMainColor.withOpacity(.15),
              blurRadius: radius8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: textMainColor),
      ),
    );
  }
}
