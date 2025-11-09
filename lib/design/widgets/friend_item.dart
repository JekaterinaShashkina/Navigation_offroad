import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:offroad_nav/design/colors.dart';

const kDefaultAvatarPng = 'assets/images/avatar_user.png';

class FriendItem extends StatelessWidget {
  final String title;     // имя
  final String handle;    // ник без @
  final String? avatarUrl;
  final VoidCallback? onTap;
  final VoidCallback? onCall;
  final VoidCallback? onVideo;
  final Widget? trailing;

  const FriendItem({
    super.key,
    required this.title,
    required this.handle,
    this.avatarUrl,
    this.onTap,
    this.onCall,
    this.onVideo,
    this.trailing,
  });

  Widget _avatarWidget(String? url) {
    final u = (url ?? '').trim();
    if (u.isEmpty) {
      return Image.asset(kDefaultAvatarPng, fit: BoxFit.cover);
    }
    if (u.toLowerCase().endsWith('.svg')) {
      // локальный svg из assets (или относительный путь)
      return SvgPicture.asset(
        u,
        fit: BoxFit.cover,
        // если вдруг файла нет — покажем плейсхолдер
        placeholderBuilder: (_) => Image.asset(kDefaultAvatarPng, fit: BoxFit.cover),
      );
    }
    if (u.startsWith('http')) {
      return Image.network(
        u,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(kDefaultAvatarPng, fit: BoxFit.cover),
      );
    }
    // локальный png/jpg из assets
    return Image.asset(
      u,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(kDefaultAvatarPng, fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80, // высота по макету
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x141A1A1A),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: chipBgColor,
              shape: BoxShape.circle,
            ),
            child: ClipOval(child: _avatarWidget(avatarUrl)),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: textMainColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            handle,
            style: const TextStyle(color: textHintColor),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: trailing ??
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _pillIcon(Icons.phone_rounded, onCall),
                  const SizedBox(width: 8),
                  _pillIcon(Icons.videocam_rounded, onVideo),
                ],
              ),
        ),
      ),
    );
  }

  Widget _pillIcon(IconData icon, VoidCallback? onTap) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: buttonSecondBackgroundColor),
        onPressed: onTap,
      ),
    );
  }
}
