import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/images.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';
import 'package:offroad_nav/design/widgets/auth_card.dart';
import 'package:offroad_nav/design/widgets/phone_input_field.dart';
import 'package:offroad_nav/models/country_code.dart';
import 'package:offroad_nav/features/auth/presentation/controllers/auth_controller.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _phoneController = TextEditingController();
  late Future<List<CountryCode>> _codesFuture;
  String _dialCode = '+372';

  void _goToRegister() {
    Navigator.pushNamed(context, '/register');
  }

  void _goToSocialLoginPage() {
    Navigator.pushNamed(context, '/socialLoginPage');
  }

  Future<void> _onContinue() async {
    final raw = _phoneController.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter phone number')),
      );
      return;
    }

    // как и раньше — чистим номер и собираем E.164
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final phoneE164 = '$_dialCode$digits';

    // дергаем контроллер, он сам выставит loading/error
    await ref
        .read(authControllerProvider.notifier)
        .signInWithPhone(context: context, phoneE164: phoneE164);
  }

  @override
  void initState() {
    super.initState();
    _codesFuture = loadCountryCodes();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: 'Sign in',
        onPressed: () {
          Navigator.pushReplacementNamed(context, '/welcomelogin');
        },
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            AuthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    style: bodyTextStyle,
                    "Simply enter your phone number to login",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: height24),

                  // Телефонный ввод
                  FutureBuilder<List<CountryCode>>(
                    future: _codesFuture,
                    builder: (ctx, snap) {
                      if (!snap.hasData) {
                        return const SizedBox(
                          height: 56,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snap.hasError) {
                        return const Text('Failed to load country codes');
                      }
                      final countries = snap.data!;
                      return PhoneInputField(
                        controller: _phoneController,
                        items: countries,
                        initialDialCode: _dialCode,
                        arrow: arrowDownImage,
                        onDialCodeChanged: (code) {
                          setState(() => _dialCode = code);
                        },
                      );
                    },
                  ),

                  const SizedBox(height: height24),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: bodyTextStyle,
                      children: [
                        const TextSpan(
                          text: "By using our mobile app, you agree to our ",
                        ),
                        TextSpan(
                          text: "Privacy Policy",
                          style: hintTextStyle,
                          recognizer: TapGestureRecognizer()..onTap = () {},
                        ),
                        const TextSpan(text: " and "),
                        TextSpan(
                          text: "Terms of Use",
                          style: hintTextStyle,
                          recognizer: TapGestureRecognizer()..onTap = () {},
                        ),
                      ],
                    ),
                  ),

                  // при желании можно сюда же добавить вывод ошибки:
                  if (authState.error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      authState.error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),

            Center(
              child: Column(
                children: [
                  AppButton(
                    width: width335,
                    text: "Continue ",
                    loading: authState.loading,
                    onPressed: authState.loading ? null : _onContinue,
                  ),
                  const SizedBox(height: height24),
                  AppButton(
                    width: width335,
                    text: "Log in with ",
                    onPressed: _goToSocialLoginPage,
                    suffix: Container(child: socialSuffix),
                    backgroundColor: buttonSecondBackgroundColor,
                    foregroundColor: surfaceColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: height24),
            Center(
              child: RichText(
                text: TextSpan(
                  style: bodyTextStyle,
                  children: [
                    const TextSpan(text: 'Already have not an account? '),
                    TextSpan(
                      text: 'Sign up',
                      style: hintTextStyle,
                      recognizer: TapGestureRecognizer()
                        ..onTap = _goToRegister,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: height24),
          ],
        ),
      ),
    );
  }
}
