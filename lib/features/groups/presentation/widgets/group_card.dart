import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/smart_avatar.dart';
import 'package:offroad_nav/features/groups/domain/entities/group.dart';

class GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;

  const GroupCard({
    super.key,
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius16),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(radius16),
          boxShadow: [
            BoxShadow(
              color: listShadowColor,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(padding16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SmartAvatar(
                src: group.avatarUrl,        // 👈 то же поле, что в деталях
                size: 56,
                placeholder: const Icon(
                  Icons.group,
                  color: textHintColor,
                  size: 32,
                ),
              ),

              const SizedBox(height: height12),

              // Название группы
              Text(
                group.name,
                style: const TextStyle(
                  fontSize: fontSize16,
                  fontWeight: FontWeight.w600,
                  color: textMainColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: height8),

              // Тип группы
              Text(
                group.isOpen ? 'Open group' : 'Private group',
                style: const TextStyle(
                  fontSize: fontSize12,
                  color: textHintColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
