import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';
import 'package:offroad_nav/features/auth/presentation/widgets/auth_card.dart';

class SignUpSuccessPage extends StatelessWidget {
  const SignUpSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: 'Success',
        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: AuthCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const Icon(Icons.check_circle, size: 72, color: Colors.green),
                  const SizedBox(height: 16),
                  Text('Account created!', style: head1TextStyle, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    'You can now use your credentials to sign in.',
                    style: bodyTextStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    text: 'Continue to app',
                    width: 300,
                    onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text('Sign in again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

