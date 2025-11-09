import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/images.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';
import 'package:offroad_nav/design/widgets/auth_card.dart';
import 'package:offroad_nav/design/widgets/phone_input_field.dart';
import 'package:offroad_nav/models/country_code.dart';
import 'package:offroad_nav/services/phone_auth_service.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _phoneController = TextEditingController();
  late Future<List<CountryCode>> _codesFuture;
  String _dialCode = '+372';
  bool _loading = false;

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
  // собираем E.164: +код + только цифры
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  final phoneE164 = '$_dialCode$digits';

  setState(() => _loading = true);
  await PhoneAuthService.instance.startPhoneSignIn(
    context: context,
    phoneE164: phoneE164,
  );
}

  @override
  void initState() {
    super.initState();
    _codesFuture = loadCountryCodes(); // 👈 грузим JSON
  }

  @override
  void dispose() {
    // _emailController.dispose();
    // _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                          height: 56, // чтобы макет не “скакал”
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snap.hasError) {
                        return const Text('Failed to load country codes');
                      }
                      final countries = snap.data!;
                      return PhoneInputField(
                        controller: _phoneController,
                        items: countries, // ← список из JSON
                        initialDialCode: _dialCode, // ← стартовый код
                        arrow: arrowDownImage, // ← твоя SVG-стрелка как Widget
                        onDialCodeChanged: (code) {
                          // ← обновляем выбранный код
                          setState(() => _dialCode = code);
                        },
                      );
                    },
                  ),

                  // Container(
                  //   padding: const EdgeInsets.symmetric(horizontal: padding16),
                  //   decoration: BoxDecoration(
                  //     color: backgroundMainColor,
                  //     borderRadius: BorderRadius.circular(radius24),
                  //   ),
                  //   child: Row(
                  //     children: [
                  //       // Префикс страны
                  //       GestureDetector(
                  //         onTap:() {
                  //           showModalBottomSheet(
                  //             context: context,
                  //             builder: (_) => ListView(
                  //               children: [
                  //                 ListTile(title: Text("+1  USA")),
                  //                 ListTile(title: Text("+44 UK")),
                  //                 ListTile(title: Text("+49 Germany")),
                  //                 ListTile(title: Text("+88 Bangladesh")),
                  //               ],
                  //             ));
                  //         },
                  //         child: Row(
                  //           children: [
                  //             const Text("+88", style: bodyTextStyle),
                  //             const SizedBox(width: 6),
                  //             arrowDownImage
                  //           ],
                  //         ),
                  //       ),
                  const SizedBox(height: height24),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: bodyTextStyle,
                      children: [
                        TextSpan(
                          text: "By using our mobile app, you agree to our ",
                        ),
                        TextSpan(
                          text: "Privacy Policy",
                          style: hintTextStyle,
                          recognizer: TapGestureRecognizer()..onTap = () {},
                        ),
                        TextSpan(text: " and "),
                        TextSpan(
                          text: "Terms of Use",
                          style: hintTextStyle,
                          recognizer: TapGestureRecognizer()..onTap = () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Center(
              child: Column(
                children: [
                  AppButton(
                    width: width335,
                    text: "Continue ",
                    loading: _loading,
                    onPressed: _loading ? null : _onContinue,
                  ),
                  SizedBox(height: height24),
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
            SizedBox(height: height24),
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
                        ..onTap = _goToRegister, // твоя функция
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: height24),
          ],
        ),
      )
    );
  }
}
