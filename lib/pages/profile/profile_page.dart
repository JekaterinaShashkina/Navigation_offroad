import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/images.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/widgets/smart_avatar.dart';
import 'package:offroad_nav/pages/profile/edit_profile_page.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/MyHomeScreen/main_screen.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:offroad_nav/pages/profile/membership_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userData;

  Future<void> _fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    setState(() {
      _userData = doc.data();
    });
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
  }

  Future<void> _showSignOutDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            35,
            16,
            35,
          ), // отступ сверху, отступ снизу
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 200,
                ), // ограничиваем ширину, чтобы текст переносился
                child: Text(
                  "Are you sure you want to sign out?",
                  style: bodyTextStyle,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 35), // отступ между текстом и кнопками
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Cancel',
                      onPressed: () => Navigator.of(ctx).pop(),
                      width: double.infinity,
                      secondaryBackground:
                          true, // цвет buttonSecondBackgroundColor
                      foregroundColor: surfaceColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
                      text: 'Sure',
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _signOut(context);
                      },
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // function to save avatar path to Firebase
  Future<void> _saveAvatarToFirebase(String avatarPath) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'img': avatarPath, // save the avatar path
    });

    setState(() {
      _userData!['img'] = avatarPath;
    });
  }

  Future<void> _showAvatarPickerDialog(BuildContext context) async {
    final Map<String, SvgPicture> avatars = {
      'avatar_boy_01.svg': avatarBoy01,
      'avatar_boy_02.svg': avatarBoy02,
      'avatar_boy_03.svg': avatarBoy03,
      'avatar_boy_04.svg': avatarBoy04,
      'avatar_boy_05.svg': avatarBoy05,
      'avatar_girl_01.svg': avatarGirl01,
      'avatar_girl_02.svg': avatarGirl02,
      'avatar_girl_03.svg': avatarGirl03,
      'avatar_girl_04.svg': avatarGirl04,
      'avatar_girl_05.svg': avatarGirl05,
    };

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // text
              Text(
                'Choose your avatar',
                style: robotoRegular16TextStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // avatars grid
              SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: avatars.entries.map((entry) {
                    return GestureDetector(
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        await _saveAvatarToFirebase(
                          'assets/images/${entry.key}',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: backgroundMainColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: entry.value,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final name = _userData!['name'] ?? 'Unknown username';
    final ImageProvider defaultAvatar = const AssetImage(
      'assets/images/avatar_user.png',
    );

    // Список настроек
    final List<Map<String, dynamic>> settings = [
      {'icon': settingIcon, 'title': 'General settings', 'onTap': null},
      {'icon': mapIcon, 'title': 'Map display', 'onTap': null},
      {'icon': navigationIcon, 'title': 'Navigation', 'onTap': null},
      {'icon': carIcon, 'title': 'Car details', 'onTap': null},
      {'icon': membershipIcon,
        'title': 'Membership',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MembershipPage()),
        ),
      },
      {'icon': accountIcon, 'title': 'Account', 'onTap': null},
      {'icon': helpIcon, 'title': 'Help centre', 'onTap': null},
      {
        'icon': logoutIcon,
        'title': 'Logout',
        'onTap': () => _showSignOutDialog(context),
      },
    ];

    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: 'Profile',
        onPressed: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const MainScreen(initialIndex: 0),
            ),
            (route) => false,
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Блок с аватаром и Edit Profile
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, // белый фон
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _showAvatarPickerDialog(context),
                    child: SmartAvatar(
                      src: (_userData?['img'] as String?) ?? '',
                      size: 88,
                      onTap: () => _showAvatarPickerDialog(context),
                      placeholder: Image.asset(
                        'assets/images/avatar_user.png',
                        fit: BoxFit.cover,
                      ),
                      // опционально рамка/оверлей:
                      // borderColor: Colors.white,
                      // borderWidth: 2,
                      // overlay: Container(
                      //   padding: const EdgeInsets.all(6),
                      //   decoration: BoxDecoration(
                      //     color: Colors.black54, shape: BoxShape.circle,
                      //   ),
                      //   child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      // ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: robotoRegular18TextStyle),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final updatedData = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditProfilePage(userData: _userData!),
                        ),
                      );
                      if (updatedData != null) {
                        setState(() {
                          _userData = updatedData;
                        });
                      }
                    },
                    child: Text(
                      'Edit profile',
                      style: robotoRegular14TextStyle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Блок со списком настроек
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white, // белый фон
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: settings.length,
                itemBuilder: (context, index) {
                  final item = settings[index];
                  return ListTile(
                    leading: item['icon'] as Widget,
                    title: Text(
                      item['title'] as String,
                      style: robotoRegular16TextStyle,
                    ),
                    trailing: arrowForwardIcon,
                    onTap: item['onTap'] as VoidCallback?,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
