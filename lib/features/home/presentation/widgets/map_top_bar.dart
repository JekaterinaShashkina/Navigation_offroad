import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/features/home/presentation/widgets/profile_avatar_button.dart';
import 'package:offroad_nav/design/widgets/route_search_widget.dart';
import 'package:offroad_nav/features/friends/presentation/widgets/pending_invites_bell.dart';

class MapTopBar extends StatelessWidget {
  const MapTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(padding16, padding12, padding16, padding12),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(0.5), // толщина белой рамки
              child: const ProfileAvatarButton(size: 50),
            ),
            const SizedBox(width: width16),
            const Expanded(child: RouteSearchWidget()),
            const SizedBox(width: width16),
            PendingInvitesBell(),
          ],
        ),
      ),
    );
  }
}
