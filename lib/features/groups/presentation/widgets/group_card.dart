import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offroad_nav/features/groups/data/repositories/groups_repository.dart';

import '../../../../design/colors.dart';
import '../../../../design/dimension.dart';
import '../../../../design/widgets/smart_avatar.dart';
import '../../application/providers/groups_providers.dart';
import '../../domain/entities/group.dart';

class GroupCard extends ConsumerWidget {
  final Group group;
  final VoidCallback onTap;

  const GroupCard({
    super.key,
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(groupsRepositoryProvider);

    String membersLabel(int n) => n == 1 ? '1 member' : '$n members';

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

              const SizedBox(height: height8),

              FutureBuilder<int>(
                future: repo.getMembersCount(group.id),
                builder: (context, snap) {
                  final count = snap.data;
                  if (count == null) {
                    return const Text(
                      '—',
                      style: TextStyle(fontSize: fontSize12, color: textHintColor),
                    );
                  }

                  final max = group.maxMembers;
                  final text = max == null ? membersLabel(count) : '$count/$max';

                  return Text(
                    text,
                    style: const TextStyle(
                      fontSize: fontSize12,
                      color: textHintColor,
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),

            ],
          ),
        ),
      ),
    );
  }
}
