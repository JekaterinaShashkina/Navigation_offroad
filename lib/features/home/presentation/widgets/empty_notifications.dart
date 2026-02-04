import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';

class EmptyNotifications extends StatelessWidget {
  final VoidCallback onBackHome;
  final String bellAssetPath;

  const EmptyNotifications({
    super.key,
    required this.onBackHome,
    this.bellAssetPath = 'assets/images/notification_bell.png',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 10),
                color: textMainColor.withOpacity(0.08),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                bellAssetPath,
                height: 90,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 18),
              const Text(
                "Stay in the Task Mangement",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "You’ll be notified about activity on tasks\nyou’re a collaborator on.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 18),

              // ✅ ваша стандартная кнопка
              AppButton(
                text: "Back to Home",
                onPressed: onBackHome,
                width: 190,
                height: 46,
                radius: 999, // pill как в макете
              ),
            ],
          ),
        ),
      ),
    );
  }
}
