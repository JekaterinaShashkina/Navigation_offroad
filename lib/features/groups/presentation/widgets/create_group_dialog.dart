import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../design/colors.dart';
import '../../../../design/dimension.dart';
import '../../../../design/avatars.dart';
import '../../application/providers/groups_providers.dart';
import '../../data/repositories/groups_repository.dart';

class CreateGroupDialog extends ConsumerStatefulWidget {
  const CreateGroupDialog({super.key});

  @override
  ConsumerState<CreateGroupDialog> createState() => _CreateGroupDialogState();

  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (_) => const CreateGroupDialog(),
    );
  }
}

class _CreateGroupDialogState extends ConsumerState<CreateGroupDialog> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedAvatar;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Create group',
        style: TextStyle(
          fontSize: fontSize20,
          fontWeight: FontWeight.w600,
          color: textMainColor,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group name',
                labelStyle: TextStyle(color: textHintColor),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: buttonBackgroundColor),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: height20),

            const Text(
              'Choose avatar',
              style: TextStyle(
                fontSize: fontSize16,
                fontWeight: FontWeight.w500,
                color: textMainColor,
              ),
            ),
            const SizedBox(height: height12),

            GestureDetector(
              onTap: () async {
                final chosen = await showGroupAvatarPicker(context);
                if (chosen != null) {
                  setState(() => _selectedAvatar = chosen);
                }
              },
              child: CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white,
                child: _selectedAvatar == null
                    ? const Icon(Icons.add_a_photo, color: textHintColor)
                    : avatarPreview(_selectedAvatar!, size: 48),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: textHintColor)),
        ),
        ElevatedButton(
          onPressed: _canCreate ? _createGroup : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonBackgroundColor,
            foregroundColor: textMainColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius8),
            ),
          ),
          child: const Text('Create'),
        ),
      ],
    );
  }

  bool get _canCreate =>
      _nameController.text.trim().isNotEmpty && _selectedAvatar != null;

  Future<void> _createGroup() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to create a group'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    try {
      final repo = ref.read(groupsRepositoryProvider);

      final groupId = await repo.createGroup(
        GroupCreateParams(
          ownerId: currentUser.uid,
          name: _nameController.text.trim(),
          avatarUrl: _selectedAvatar!,
        ),
      );

      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group created successfully'),
          backgroundColor: buttonBackgroundColor,
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create group: $e'),
          backgroundColor: errorColor,
        ),
      );
    }
  }
}
