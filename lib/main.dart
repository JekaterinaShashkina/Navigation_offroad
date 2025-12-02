  import 'package:flutter/material.dart';
  import 'package:firebase_core/firebase_core.dart';
  import 'firebase_options.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  import 'features/auth/presentation/pages/email_login_page.dart';
  import 'features/auth/presentation/pages/social_login_page.dart';
  import 'features/auth/presentation/pages/auth_page.dart';
  import 'features/auth/presentation/pages/login_page.dart';
  import 'features/auth/presentation/pages/phone_otp_page.dart';

  import 'features/auth/presentation/pages/sign_up_success_page.dart';
  import 'features/routes/presentation/pages/make_route_page.dart';
  import 'pages/splash_page.dart';
  import 'pages/welcome_login_page.dart';
  import 'features/auth/presentation/pages/register_page.dart';

  import 'pages/welcome_page.dart';
  import 'MyHomeScreen/main_screen.dart';
  import 'pages/main_menu/main_menu_page.dart';

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(const ProviderScope(child: LoadingApp()));
  }

  class LoadingApp extends StatelessWidget {
    const LoadingApp({super.key});

    Future<void> _initializeFirebase() async {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    }

    @override
    Widget build(BuildContext context) {
      return FutureBuilder(
        future: _initializeFirebase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return const App();
          } else if (snapshot.hasError) {
            return MaterialApp(
              home: Scaffold(
                body: Center(child: Text('Ошибка Firebase: ${snapshot.error}')),
              ),
            );
          } else {
            return const MaterialApp(
              home: Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }
        },
      );
    }
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
          '/': (context) => const SplashScreen(),
          '/auth': (context) => const AuthPage(),
          '/welcome': (context) => const WelcomePage(),
          '/welcomelogin': (context) => const WelcomeLoginPage(),
          '/login': (context) => const LoginForm(),
          '/main': (context) => const MainScreen(),
          '/register': (context) => const RegisterPage(),
          '/socialLoginPage': (context) => const SocialLoginPage(),
          '/login_email': (context) => const EmailLoginPage(),
          '/signup-success': (context) => const SignUpSuccessPage(),
          '/phone_otp': (_) => const PhoneOtpPage(),
          '/main_menu': (context) => const MainMenuPage(),
          '/makeroutepage': (context) => const MakeRoutePage(),
        },
      );
    }
  }

