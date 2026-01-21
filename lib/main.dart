import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offroad_nav/features/auth/presentation/pages/splash_page.dart';

import 'firebase_options.dart';

// AUTH / ONBOARDING
import 'features/auth/presentation/pages/welcome_page.dart';
import 'features/auth/presentation/pages/welcome_login_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/social_login_page.dart';
import 'features/auth/presentation/pages/email_login_page.dart';
import 'features/auth/presentation/pages/phone_otp_page.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/auth/presentation/pages/sign_up_success_page.dart';

// MAIN APP
import 'features/home/presentation/pages/main_screen.dart';
import 'features/home/presentation/pages/main_menu_page.dart';

// ROUTES
import 'features/routes/presentation/pages/make_route_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Инициализация Firebase перед runApp()
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navigation Offroad',
      theme: ThemeData(
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        // AUTH FLOW
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthPage(),
        '/welcome': (context) => const WelcomePage(),
        '/welcomelogin': (context) => const WelcomeLoginPage(),
        '/login': (context) => const LoginForm(),
        '/register': (context) => const RegisterPage(),
        '/socialLoginPage': (context) => const SocialLoginPage(),
        '/login_email': (context) => const EmailLoginPage(),
        '/signup-success': (context) => const SignUpSuccessPage(),
        '/phone_otp': (_) => const PhoneOtpPage(),

        // APP MAIN FLOW
        '/main': (context) => const MainScreen(),
        '/main_menu': (context) => const MainMenuPage(),
        '/makeroutepage': (context) => const MakeRoutePage(),
      },
    );
  }
}
