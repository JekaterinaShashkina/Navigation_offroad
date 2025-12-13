// lib/pages/profile/edit_profile_page.dart
import 'package:flutter/material.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';

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

  Widget _buildField(String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: backgroundMainColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: controller,
        style: robotoRegular18TextStyle,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: robotoRegular14TextStyle,
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        ),
      ),
    );
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  _buildField('Name', nameController),
                  _buildField('Phone', phoneController),
                  _buildField('Description', descriptionController),
                  _buildField('Avatar URL', imgController),
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
