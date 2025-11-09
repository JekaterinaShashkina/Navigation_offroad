import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';

/// Кнопка-тумблер для верификации телефона.
/// - verified=true → показывается зелёный бейдж "Verified"
/// - active=true   → режим "хочу верифицировать сейчас" (кнопка желтая)
/// - busy=true     → спиннер, onToggle отключён
class VerifyToggleButton extends StatelessWidget {
  const VerifyToggleButton({
    super.key,
    required this.active,
    required this.verified,
    required this.onToggle,
    this.busy = false,
    this.height = 44,
  });

  final bool active;         // запрос на верификацию (до сабмита)
  final bool verified;       // уже привязан телефон
  final bool busy;           // идёт операция
  final double height;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    if (verified) return const VerifiedChip();

    final bg = active ? buttonBackgroundColor : buttonSecondBackgroundColor;
    final fg = active ? textMainColor : surfaceColor;
    // final label = active ? 'Cancel' : 'Verify';

    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: busy ? null : onToggle,
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius24),
          ),
          side: BorderSide(color: active ? buttonBackgroundColor : backgroundSecondColor),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: busy
            ? const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: textMainColor),
              )
            : Text("Verify"),
      ),
    );
  }
}

/// Желтый бейдж "Verified" (когда телефон уже привязан).
class VerifiedChip extends StatelessWidget {
  const VerifiedChip({super.key, this.height = 44});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: buttonBackgroundColor),
      ),
      alignment: Alignment.center,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 18, color: buttonBackgroundColor),
          SizedBox(width: 6),
          Text('Verified', style: TextStyle(color: buttonBackgroundColor)),
        ],
      ),
    );
  }
}
