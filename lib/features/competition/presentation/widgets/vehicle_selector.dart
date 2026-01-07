import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/images.dart';

class VehicleSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const VehicleSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _vehicleCard('ATV', motoIconPath),
        const SizedBox(width: 12),
        _vehicleCard('Jeep', jeepIconPath),
        const SizedBox(width: 12),
        _vehicleCard('Truck', truckIconPath),
      ],
    );
  }

  Widget _vehicleCard(String value, String assetPath) {
    final isSelected = selected == value;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onChanged(value),
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? buttonSecondBackgroundColor
                  : const Color(0xFFE6E6EA),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x141A1A1A),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 32,
                child: Center(
                  child: SvgPicture.asset(
                    assetPath,
                    width: 28,
                    height: 28,
                    colorFilter: ColorFilter.mode(
                      isSelected
                          ? textMainColor   // выбранная — почти чёрная
                          : buttonSecondBackgroundColor, // невыбранные — серые
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? textMainColor
                      : buttonSecondBackgroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
