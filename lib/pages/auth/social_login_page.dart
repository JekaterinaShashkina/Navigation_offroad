import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/images.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';
import 'package:offroad_nav/design/widgets/auth_card.dart';
import 'package:offroad_nav/services/auth_service.dart';

class SocialLoginPage extends StatelessWidget {
  const SocialLoginPage({super.key});

  void _loginEmail(BuildContext context) {
    Navigator.pushNamed(context, '/login_email');
  }

  @override
  Widget build(BuildContext context) {
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
              Spacer(),
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
                    SizedBox(height: height24),
                    AppButton(
                      icon: fbImage,
                      width: width335,
                      text: "Facebook ",
                      onPressed: () {},
                    ),
                    SizedBox(height: height24),
                    AppButton(
                      icon: googleImage,
                      width: width335,
                      text: "Google ",
                      onPressed: () async {
                        try {
                          await AuthService.instance.signInWithGoogle();
                          if (!context.mounted) return;
                          Navigator.pushReplacementNamed(context, '/main');
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      },
                    ),
                    SizedBox(height: height24),
                    AppButton(
                      icon: appleImage,
                      width: width335,
                      text: "Apple ",
                      onPressed: () {},
                    ),
                    SizedBox(height: height24),
                    AppButton(
                      icon: emailImage,
                      width: width335,
                      text: "Email/password",
                      onPressed: () => _loginEmail(context),
                    ),
                    SizedBox(height: height24),
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
