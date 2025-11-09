import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/images.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';
import 'package:offroad_nav/design/widgets/auth_card.dart';
import 'package:offroad_nav/design/widgets/auth_text_field.dart';
import 'package:offroad_nav/utils/validators.dart';

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/main');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final code = e.code;
      final msg = switch (code) {
        'invalid-email' => 'Invalid email address.',
        'user-not-found' => 'No user found for this email.',
        'wrong-password' => 'Wrong password.',
        'user-disabled' => 'This account is disabled.',
        _ => e.message ?? 'Login failed. Try again.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email to reset password.')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset link sent to your email.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to send reset link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: "Sign in",
        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
      ),
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Spacer(),
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
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter password';
                        if (v.length < 6) return 'At least 6 characters';
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
              loading: _loading,
              onPressed: _loading ? null : _signIn,
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
                      ..onTap = () => Navigator.pushNamed(context, '/register'),
                  ),
                ],
              ),
            ),
            SizedBox(height: height24),
          ],
        ),
      ),
    );
  }
}
