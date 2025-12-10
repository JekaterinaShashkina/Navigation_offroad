import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/smart_avatar.dart';
import 'package:offroad_nav/features/groups/domain/entities/group.dart';

class GroupHeader extends StatelessWidget {
  const GroupHeader({
    super.key,
    required this.group,
    required this.isLeader,
    required this.leaderName
  });

  final Group group;
  final bool isLeader;
  final String leaderName; 

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(padding20),
      decoration: const BoxDecoration(
        color: surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: listShadowColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // avatar
          SmartAvatar(
            src: group.avatarUrl, // то же поле, что и в GroupCard
            size: 100,
            placeholder: const CircleAvatar(
              radius: 50,
              backgroundColor: backgroundMainColor,
              child: Icon(Icons.group, size: 40, color: textHintColor),
            ),
          ),
          const SizedBox(height: height16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                group.name,
                style: const TextStyle(
                  fontSize: fontSize22,
                  fontWeight: FontWeight.w600,
                  color: textMainColor,
                ),
              ),
              if (isLeader) ...[
                const SizedBox(width: width8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: padding8,
                    vertical: padding6,
                  ),
                  decoration: BoxDecoration(
                    color: buttonBackgroundColor,
                    borderRadius: BorderRadius.circular(radius12),
                  ),
                  child: Text(
                    'Leader: $leaderName',
                    style: const TextStyle(
                      fontSize: fontSize12,
                      fontWeight: FontWeight.w500,
                      color: textMainColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
