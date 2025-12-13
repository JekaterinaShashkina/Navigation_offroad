import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';

import 'package:offroad_nav/features/groups/domain/entities/group.dart';

class GroupChatPage extends StatelessWidget {
  final Group group;

  const GroupChatPage({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: 'Group chat',
        onPressed: () => Navigator.pop(context),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(padding16),
          child: Text(
            'Group chat functionality will be implemented later.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize16,
              color: textHintColor,
            ),
          ),
        ),
      ),
    );
  }
}
