import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:offroad_nav/pages/profile/profile_page.dart';
import 'package:offroad_nav/design/widgets/smart_avatar.dart';

class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({
    super.key,
    this.size = 50,
    this.placeholder,
  });

  final double size;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Не авторизованы — просто плейсхолдер
      return _button(context, null);
    }

    final uid = user.uid;

    // Слушаем Firestore-документ, чтобы обновления аватара подтягивались реактивно
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data();
        final img = (data?['img'] as String?)?.trim();
        // Фоллбэк на Auth (Google) фото:
        final authPhoto = user.photoURL?.trim();

        // Выбираем источник: Firestore > Auth
        final rawSrc = (img != null && img.isNotEmpty)
            ? img
            : (authPhoto != null && authPhoto.isNotEmpty ? authPhoto : null);

        // Если gs:// — конвертируем в https
        if (rawSrc != null && rawSrc.startsWith('gs://')) {
          return FutureBuilder<String>(
            future: _resolveGsUrl(rawSrc),
            builder: (context, fsnap) {
              final resolved = fsnap.data;
              return _button(context, resolved);
            },
          );
        }

        return _button(context, rawSrc);
      },
    );
  }

  Future<String> _resolveGsUrl(String gsUrl) async {
    final ref = FirebaseStorage.instance.refFromURL(gsUrl);
    return await ref.getDownloadURL();
  }

  Widget _button(BuildContext context, String? src) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
      },
      child: SmartAvatar(
        src: src,                 // умеет http/https, svg, asset
        size: size,
        placeholder: placeholder, // например: Image.asset('assets/images/avatar_user.png')
        // можно добавить рамку/оверлей, если хочешь:
        // borderColor: Colors.white,
        // borderWidth: 2,
        // overlay: const Icon(Icons.camera_alt, size: 18),
      ),
    );
  }
}
