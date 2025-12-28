import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/features/groups/data/repositories/groups_repository.dart';
import 'package:offroad_nav/features/groups/domain/entities/group.dart';
import 'package:offroad_nav/features/groups/application/providers/groups_providers.dart';

/// Диалог "Group Management" (Delete / Leave)
Future<void> showGroupManagementDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Group group,
  required bool isLeader,
  required Future<void> Function() onLeaveGroup,
}) async {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Group Management'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLeader)
            ListTile(
              leading: const Icon(Icons.delete, color: errorColor),
              title: const Text(
                'Delete Group',
                style: TextStyle(color: errorColor),
              ),
              onTap: () {
                Navigator.pop(context); // закрываем этот диалог
                _showDeleteGroupDialog(
                  context: context,
                  ref: ref,
                  group: group,
                );
              },
            ),
          ListTile(
  leading: const Icon(Icons.exit_to_app, color: errorColor),
  title: const Text(
    'Leave Group',
    style: TextStyle(color: errorColor),
  ),
  onTap: () async {
    Navigator.pop(context); // закрываем "Group Management"

    // показываем отдельный диалог подтверждения
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text(
          'Are you sure you want to leave this group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // закрываем Leave-dialog
              await onLeaveGroup();   // тут вызывается _leaveGroup(group)
            },
            child: const Text(
              'Leave',
              style: TextStyle(color: errorColor),
            ),
          ),
        ],
      ),
    );
  },
),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

Future<void> _showDeleteGroupDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Group group,
}) async {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Delete Group'),
      content: const Text(
        'Are you sure you want to delete this group? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context); // закрываем диалог Delete

            final repo = ref.read(groupsRepositoryProvider);
            await repo.deleteGroup(group.id);

            // закрываем страницу деталей группы
            Navigator.of(context).pop();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Group deleted'),
                backgroundColor: errorColor,
              ),
            );
          },
          child: const Text(
            'Delete',
            style: TextStyle(color: errorColor),
          ),
        ),
      ],
    ),
  );
}
