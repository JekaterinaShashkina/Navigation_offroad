import 'package:flutter/material.dart';
import 'package:offroad_nav/MyHomeScreen/my_home_screen.dart';
import 'package:offroad_nav/pages/routes/routes_list_page.dart';
import 'package:offroad_nav/pages/profile/profile_page.dart';
import 'package:offroad_nav/pages/friends/friends_page.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pages = [
      MyHomeScreen(),            // Home
      const RoutesListPage(),    // Routes
      const FriendsPage(),       // Friends
      const ProfilePage(),       // Profile
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      // bottomNavigationBar больше не нужен
    );
  }
}