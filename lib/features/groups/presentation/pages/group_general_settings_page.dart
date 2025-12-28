import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offroad_nav/design/avatars.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';
import 'package:offroad_nav/design/widgets/app_text_field.dart';
import 'package:offroad_nav/design/widgets/smart_avatar.dart';
import 'package:offroad_nav/features/groups/application/providers/groups_providers.dart';
import 'package:offroad_nav/features/groups/data/repositories/groups_repository.dart';
import 'package:offroad_nav/features/groups/domain/entities/group.dart';

class GroupGeneralSettingsPage extends ConsumerStatefulWidget {
  final Group group;

  const GroupGeneralSettingsPage({
    super.key,
    required this.group,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
 _GroupGeneralSettingsPageState();
  }
  
  class _GroupGeneralSettingsPageState 
  extends ConsumerState<GroupGeneralSettingsPage> {
    late final TextEditingController _nameCtrl;
    late final TextEditingController _descCtrl;
    late final TextEditingController _maxCtrl;

    late bool _isOpen;
    String? _avatar;
    
  @override
  void initState() {
    super.initState();
    final g = widget.group;
    _nameCtrl = TextEditingController(text: g.name);
    _descCtrl = TextEditingController(text: g.description ?? '');
    _maxCtrl = TextEditingController(text: (g.maxMembers ?? 20).toString());
    _isOpen = g.isOpen;
    _avatar = g.avatarUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(groupsRepositoryProvider);

    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: 'General Settings',
        onPressed: () => Navigator.pop(context),
      ),
      body: Container(
        padding: EdgeInsets.all(padding16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(radius16),
          boxShadow: [
            BoxShadow(
              color: listShadowColor,
              blurRadius: 6,
              offset: Offset(0, 3),
            )
          ]
        ),
        child: Column(
          // AVatar 
          children: [
            Row(
              children: [
              SmartAvatar(
              src: _avatar,
              size: 56,
              placeholder: const Icon(Icons.group, color: textHintColor,),
            ),
            const SizedBox(width: 12,),
              AppButton(onPressed: () async {
                      final picked = await showGroupAvatarPicker(context);
                      if (picked != null) setState(() => _avatar = picked);
                    }, 
                    width: width200,
                    text:'Change avatar')
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                hint: 'Group name',
                controller: _nameCtrl,
              ),
            const SizedBox(height: 12),
              AppTextField(
                controller: _descCtrl,
                hint: 'Description',
                maxLines: 3,
              ),
              
              const SizedBox(height: 12),
              AppTextField(
                controller: _maxCtrl,
                keyboardType: TextInputType.number,
                hint: 'Max members (e.g. 20)'
              ),
            const SizedBox(height: 12),
              SwitchListTile(
              value: _isOpen,
              onChanged: (v) => setState(() => _isOpen = v),
              title: const Text('Open group'),
              subtitle: Text(_isOpen
                  ? 'Anyone can join'
                  : 'Only owner can add members'),
              activeColor: textMainColor,
              activeTrackColor: buttonSecondBackgroundColor,
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.shade400,
            ),
                        const Spacer(),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                onPressed: () async {
                final name = _nameCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Name can'tbe empty")),
                  );
                  return;
                }
                final max = int.tryParse(_maxCtrl.text.trim()) ?? 20;
                  if (max < 1) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Max members must be > 0')),
                    );
                    return;
                  }
                    await repo.updateGroup(
                    widget.group.id,
                    name: name,
                    description: _descCtrl.text.trim().isEmpty
                        ? null
                        : _descCtrl.text.trim(),
                    avatarUrl: _avatar,
                    maxMembers: max,
                    isOpen: _isOpen,
                  );

                  if (mounted) Navigator.pop(context);                
              }, text: 'Save'),
            )

          ],
        )
      ),
    );
  }
  

}
