import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/images.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';
import 'package:offroad_nav/features/auth/presentation/widgets/auth_card.dart';
import 'package:offroad_nav/features/auth/presentation/controllers/auth_controller.dart';

class SocialLoginPage extends ConsumerWidget {
  const SocialLoginPage({super.key});

  void _loginEmail(BuildContext context) {
    Navigator.pushNamed(context, '/login_email');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      final messenger = ScaffoldMessenger.of(context);
      if (next.error != null && next.error != prev?.error) {
        messenger.showSnackBar(
          SnackBar(content: Text(next.error!.message)),
        );
        return;
      }

      final completedAction = next.lastAction;
      final finishedRequest =
          (prev?.loading ?? false) && !next.loading && next.error == null;

      if (finishedRequest && completedAction == AuthAction.googleSignIn) {
        Navigator.pushReplacementNamed(
          context,
          '/main',
        );
      }
    });

    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: "Sign in",
        onPressed: () {
          Navigator.pushReplacementNamed(context, '/login');
        },
      ),
      body: Container(
        decoration: mainBackgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              AuthCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Sign in with social networks or with email",
                      style: head1TextStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: height24),

                    // Facebook — пока заглушка
                    AppButton(
                      icon: fbImage,
                      width: width335,
                      text: "Facebook ",
                      onPressed: authState.loading ? null : () {},
                    ),
                    const SizedBox(height: height24),

                    // 🟦 Google — теперь через AuthController
                    AppButton(
                      icon: googleImage,
                      width: width335,
                      text: "Google ",
                      loading: authState.loading,
                      onPressed: authState.loading
                          ? null
                          : () async {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .signInWithGoogle();
                            },
                    ),
                    const SizedBox(height: height24),

                    // Apple — пока заглушка
                    AppButton(
                      icon: appleImage,
                      width: width335,
                      text: "Apple ",
                      onPressed: authState.loading ? null : () {},
                    ),
                    const SizedBox(height: height24),

                    // Email / password
                    AppButton(
                      icon: emailImage,
                      width: width335,
                      text: "Email/password",
                      onPressed:
                          authState.loading ? null : () => _loginEmail(context),
                    ),

                    const SizedBox(height: height24),

                    // Можно при желании показать текст ошибки:
                    if (authState.error != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        authState.error!.message,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
