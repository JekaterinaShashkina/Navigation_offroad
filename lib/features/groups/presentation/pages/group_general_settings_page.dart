import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/features/groups/domain/entities/group.dart';

class GroupGeneralSettingsPage extends ConsumerWidget {
  final Group group;

  const GroupGeneralSettingsPage({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: 'General Settings',
        onPressed: () => Navigator.pop(context),
      ),
      body: const Padding(
        padding: EdgeInsets.all(padding16),
        child: Text(
          'Edit group name and avatar functionality will be implemented later.',
          style: TextStyle(
            fontSize: fontSize16,
            color: textHintColor,
          ),
        ),
      ),
    );
  }
}
