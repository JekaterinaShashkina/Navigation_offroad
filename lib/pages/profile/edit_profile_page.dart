import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';
import 'package:offroad_nav/design/styles.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController descriptionController;
  late TextEditingController imgController;
  bool locationSharing = false;

  @override
  void initState() {
    super.initState();
    final data = widget.userData;
    nameController = TextEditingController(text: data['name'] ?? '');
    phoneController = TextEditingController(text: data['phone'] ?? '');
    descriptionController = TextEditingController(text: data['description'] ?? '');
    imgController = TextEditingController(text: data['img'] ?? '');
    locationSharing = data['location_sharing'] ?? false;
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
    final userId = widget.userData['userID'];
    final updatedUserData = {
      'name': nameController.text.trim(),
      'phone': phoneController.text.trim(),
      'description': descriptionController.text.trim(),
      'img': imgController.text.trim(),
      'location_sharing': locationSharing,
      'userID': userId,
    };
    await FirebaseFirestore.instance.collection('users').doc(userId).update(updatedUserData);

    Navigator.pop(context, updatedUserData); // return updated data
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
        style: robotoRegular18TextStyle, // стиль введенного текста
        decoration: InputDecoration(
          hintText: label,
          hintStyle: robotoRegular14TextStyle, // стиль placeholder
          border: InputBorder.none,
          isDense: true, // уменьшает высоту TextField
          contentPadding: const EdgeInsets.symmetric(vertical: 4), // отступы внутри поля
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
            // White block for profile fields
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