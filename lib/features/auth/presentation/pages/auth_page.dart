import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:offroad_nav/pages/auth/login_page.dart';
import 'package:offroad_nav/pages/welcome_page.dart';
import 'package:offroad_nav/MyHomeScreen/main_screen.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
    Widget build(BuildContext context) {
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            // Если пользователь залогинен — главный экран
            return const MainScreen();
          } else {
            // Если нет — показываем WelcomePage
            return const WelcomePage();
          }
        },
      );
    }
}