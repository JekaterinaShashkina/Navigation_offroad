import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/images.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';
import 'package:offroad_nav/features/auth/presentation/widgets/auth_card.dart';
import 'package:offroad_nav/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:offroad_nav/core/utils/validators.dart';

import 'package:offroad_nav/features/auth/presentation/controllers/auth_controller.dart';

class EmailLoginPage extends ConsumerStatefulWidget {
  const EmailLoginPage({super.key});

  @override
  ConsumerState<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends ConsumerState<EmailLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();


  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _email.text.trim();
    final password = _password.text;

    await ref
        .read(authControllerProvider.notifier)
        .signInWithEmail(email, password);
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty ||
        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid email to reset password.'),
        ),
      );
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(email);
  }

  @override
  Widget build(BuildContext context) {
        ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (!mounted) return;
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

      if (!finishedRequest) return;

      switch (completedAction) {
        case AuthAction.emailSignIn:
          Navigator.pushReplacementNamed(context, '/main');
          break;
        case AuthAction.resetPassword:
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Reset link sent to your email.'),
            ),
          );
          break;
        default:
          break;
      }
    });
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: "Sign in",
        onPressed: () =>
            Navigator.pushReplacementNamed(context, '/login'),
      ),
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Spacer(),
            AuthCard(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sign in with email',
                      style: head1TextStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: height24),
                    AuthTextField(
                      controller: _email,
                      hint: "Enter email",
                      keyboardType: TextInputType.emailAddress,
                      prefix: emailImage,
                      validator: Validators.compose([
                        Validators.required('Enter email'),
                        Validators.email('Invalid email'),
                      ]),
                    ),
                    const SizedBox(height: height24),
                    AuthTextField(
                      controller: _password,
                      hint: 'Enter password',
                      obscureText: _obscure,
                      prefix: lockImage,
                      suffix: IconButton(
                        icon: _obscure ? hideEyeImage : eyeImage,
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Enter password';
                        }
                        if (v.length < 6) {
                          return 'At least 6 characters';
                        }
                        return null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _resetPassword,
                        child: const Text(
                          'Forgot password?',
                          style: hintSmallTextStyle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppButton(
              width: width335,
              text: 'Sign in',
              loading: authState.loading,
              onPressed: authState.loading ? null : _signIn,
            ),
            const SizedBox(height: height24),
            RichText(
              text: TextSpan(
                style: bodyTextStyle,
                children: [
                  const TextSpan(text: "Don't have an account? "),
                  TextSpan(
                    text: 'Sign up',
                    style: hintTextStyle,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () =>
                          Navigator.pushNamed(context, '/register'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: height24),
          ],
        ),
      ),
    );
  }
}
