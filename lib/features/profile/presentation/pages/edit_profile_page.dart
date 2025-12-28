// lib/pages/profile/edit_profile_page.dart
import 'package:flutter/material.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';
import 'package:offroad_nav/design/widgets/app_text_field.dart';

// сервис + модель
import 'package:offroad_nav/features/profile/data/services/user_profile_service.dart';

class EditProfilePage extends StatefulWidget {
  final UserProfile profile;

  const EditProfilePage({
    super.key,
    required this.profile,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController descriptionController;
  late TextEditingController imgController;
  late bool locationSharing;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    nameController = TextEditingController(text: p.name);
    phoneController = TextEditingController(text: p.phone);
    descriptionController = TextEditingController(text: p.description);
    imgController = TextEditingController(text: p.img);
    locationSharing = p.locationSharing;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    descriptionController.dispose();
    imgController.dispose();
    super.dispose();
  }

  Future<void> saveProfile() async {
    final updated = widget.profile.copyWith(
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      description: descriptionController.text.trim(),
      img: imgController.text.trim(),
      locationSharing: locationSharing,
    );

    await UserProfileService.instance.updateProfile(updated);
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: 'Edit Profile',
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  AppTextField(hint:'Name', controller: nameController),
                  AppTextField(hint: 'Phone', controller: phoneController),
                  AppTextField(hint:'Description', controller: descriptionController),
                  AppTextField(hint:'Avatar URL', controller: imgController),
                  SwitchListTile(
                    title: const Text('Share location'),
                    value: locationSharing,
                    onChanged: (val) => setState(() => locationSharing = val),
                    activeColor: textMainColor,
                    activeTrackColor: buttonSecondBackgroundColor,
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Save',
              width: double.infinity,
              onPressed: saveProfile,
            ),
          ],
        ),
      ),
    );
  }
}
