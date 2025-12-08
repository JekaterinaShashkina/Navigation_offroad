import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/images.dart';
import 'package:offroad_nav/features/home/presentation/pages/main_screen.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';
import 'package:offroad_nav/features/competition/presentation/pages/competitions_page.dart';
import 'package:offroad_nav/features/groups/presentation/pages/groups_page.dart';
import 'package:offroad_nav/features/routes/presentation/pages/routes_list_page.dart';
import 'package:offroad_nav/features/friends/presentation/pages/friends_page.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        titleWidget: splashLogo(width: 142.85),
        onPressed: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const MainScreen(initialIndex: 0),
            ),
            (route) => false,
          );
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 160 / 200,
          children: [
            /// Routes
            _MenuButton(
              backgroundColor: buttonBackgroundColor,
              textColor: Colors.black,
              icon: routesMenuIcon,
              label: 'Routes',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RoutesListPage()),
                );
              },
            ),

            /// Competitions
            _MenuButton(
              backgroundColor: buttonBackgroundColor,
              textColor: Colors.black,
              icon: competitionsMenuIcon,
              label: 'Competitions',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CompetitionsPage()),
                );
              },
            ), 

           /// Friends
            _MenuButton(
              backgroundColor: buttonBackgroundColor,
              textColor: Colors.black,
              icon: friendsMenuIcon,
              label: 'Friends',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FriendsPage()),
                );
              },
            ),

            /// Groups
            _MenuButton(
              backgroundColor: buttonBackgroundColor,
              textColor: Colors.black,
              icon: groupsMenuIcon,
              label: 'Groups',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GroupsPage()),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: AppButton(
          text: 'Back to map',
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const MainScreen(initialIndex: 0),
              ),
              (route) => false,
            );
          },
          // если в AppButton есть эти параметры и хочешь чёрную кнопку — раскомментируй
          backgroundColor: bgNightColor,
          foregroundColor: surfaceColor,
        ),
      ),
    );
  }
}

/// Кастомная кнопка меню
class _MenuButton extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const _MenuButton({
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
