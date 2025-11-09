import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:offroad_nav/design/avatars.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/images.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';
import 'package:offroad_nav/design/widgets/auth_card.dart';
import 'package:offroad_nav/design/widgets/auth_text_field.dart';
import 'package:offroad_nav/design/widgets/avatar_circle.dart';
import 'package:offroad_nav/design/widgets/phone_input_field.dart';
import 'package:offroad_nav/design/widgets/verify_toggle_button.dart';
import 'package:offroad_nav/models/country_code.dart';
import 'package:offroad_nav/pages/auth/phone_otp_page.dart';
import 'package:offroad_nav/pages/auth/sign_up_success_page.dart';
import 'package:offroad_nav/services/phone_link_service.dart';
import 'package:offroad_nav/services/user_repository.dart';
import 'package:offroad_nav/utils/validators.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullnameController = TextEditingController();
  final _phoneController = TextEditingController();
  late Future<List<CountryCode>> _codesFuture;
  String _dialCode = '+372';
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreed = false;
  bool _loading = false;
  bool _verifyPhoneRequested = false; // просит привязать в этой регистрации
  bool _phoneLinked = false;

  String? _selectedAvatarPath;

  Future<void> _register() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept Terms & Privacy')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // если попросили верифицировать телефон — проверим, что он введён
    String? phoneE164;
    if (_verifyPhoneRequested) {
      final raw = _phoneController.text.trim();
      final digits = raw.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid phone number')),
        );
        return;
      }
      phoneE164 = '$_dialCode$digits';
    }

    setState(() => _loading = true);
    try {
      // 1) создаём e-mail аккаунт
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      final user = userCredential.user!;

      // 2) базовый апсерт (имя/аватар) — без телефона
      await UserRepository.upsertOnLogin(
        user,
        extra: {
          'name': _fullnameController.text.trim(),
          'img': _selectedAvatarPath ?? '',
        },
      );

      // 3) если просили линковку телефона — запускаем flow линковки
      if (_verifyPhoneRequested && phoneE164 != null) {
        final ok = await PhoneLinkService().linkWithOtpPage(context, phoneE164);
        if (!ok) {
          // Остаться на странице регистрации, чтобы пользователь мог повторить
          if (mounted) {
            setState(() {
              _loading = false;
              _phoneLinked = false;
            });
          }
          return;
        }
        // OTP-страница уже сделала upsert {'phone': phoneE164}
        if (mounted) {
          setState(() {
            _phoneLinked = true;
            _verifyPhoneRequested = false;
          });
        }
      }

      // 4) всё прошло — идём на success
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignUpSuccessPage()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'email-already-in-use' => 'Email is already in use.',
        'invalid-email' => 'Invalid email.',
        'weak-password' => 'Weak password.',
        _ => e.message ?? 'Registration failed.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Future<bool> _startLinkPhoneFlow(
  //   BuildContext context,
  //   String phoneE164,
  // ) async {
  //   final c = Completer<bool>();

  //   await FirebaseAuth.instance.verifyPhoneNumber(
  //     phoneNumber: phoneE164,

  //     verificationCompleted: (PhoneAuthCredential cred) async {
  //       try {
  //         await FirebaseAuth.instance.currentUser!.linkWithCredential(cred);
  //         c.complete(true);
  //       } on FirebaseAuthException catch (e) {
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(SnackBar(content: Text(e.message ?? 'Link failed')));
  //         c.complete(false);
  //       }
  //     },
  //     verificationFailed: (e) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text(e.message ?? 'Phone verification failed')),
  //       );
  //       c.complete(false);
  //     },
  //     codeSent: (verificationId, resendToken) async {
  //       if (!context.mounted) return;
  //       final res = await Navigator.push<bool>(
  //         context,
  //         MaterialPageRoute(
  //           builder: (_) => PhoneOtpPage(
  //             // ваш экран OTP
  //             // Страница должна уметь работать в «link»-режиме (см. ниже)
  //             key: UniqueKey(),
  //           ),
  //           settings: RouteSettings(
  //             arguments: {
  //               'verificationId': verificationId,
  //               'resendToken': resendToken,
  //               'phone': phoneE164,
  //               'flow': 'link', // ⟵ режим ЛИНКОВКИ
  //             },
  //           ),
  //         ),
  //       );
  //       c.complete(res == true);
  //     },

  //     codeAutoRetrievalTimeout: (_) {},
  //   );

  //   return c.future;
  // }

  @override
  void initState() {
    super.initState();
    _codesFuture = loadCountryCodes(); // 👈 грузим JSON
  }

  // Освобождаем контроллеры, чтобы избежать утечек памяти
  @override
  void dispose() {
    _emailController.dispose();
    _fullnameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: 'Sign up',
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AuthCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AvatarCircle(
                                path: _selectedAvatarPath ?? '',
                                radius: 44,
                                onTap: () async {
                                  final selected = await showAvatarPicker(
                                    context,
                                  );
                                  if (selected == null) return;
                                  setState(
                                    () => _selectedAvatarPath = selected,
                                  );
                                },
                                placeholder: photoImage,
                              ),
                              const SizedBox(height: height12),
                              AuthTextField(
                                controller: _fullnameController,
                                hint: "Full name",
                                prefix: personAddIcon,
                                validator: Validators.required(
                                  "Enter fullname",
                                ),
                              ),
                              const SizedBox(height: height12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: FutureBuilder<List<CountryCode>>(
                                      future: _codesFuture,
                                      builder: (ctx, snap) {
                                        if (!snap.hasData) {
                                          return const SizedBox(
                                            height:
                                                56, // чтобы макет не “скакал”
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        }
                                        if (snap.hasError) {
                                          return const Text(
                                            'Failed to load country codes',
                                          );
                                        }
                                        final countries = snap.data!;
                                        return Expanded(
                                          child: IgnorePointer(
                                            ignoring: _phoneLinked,
                                            child: PhoneInputField(
                                              controller: _phoneController,
                                              items: countries, // ← список из JSON
                                              initialDialCode: _dialCode, // ← стартовый код
                                              arrow: arrowDownImage, // ← твоя SVG-стрелка как Widget
                                              onDialCodeChanged: (code) {
                                                // ← обновляем выбранный код
                                                setState(
                                                  () => _dialCode = code,
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  VerifyToggleButton(
                                    active: _verifyPhoneRequested,
                                    verified: _phoneLinked,
                                    busy:
                                        false, // можно подвязать отдельный флаг, если нужен спиннер
                                    onToggle: () => setState(() {
                                      _verifyPhoneRequested =
                                          !_verifyPhoneRequested;
                                    }),
                                  ),
                                ],
                              ),
                              if (_verifyPhoneRequested && !_phoneLinked)
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Text(
                                    'We will send an SMS after you tap Sign up',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: height12),
                              AuthTextField(
                                controller: _emailController,
                                hint: "Email",
                                keyboardType: TextInputType.emailAddress,
                                prefix: emailImage,
                                validator: Validators.compose([
                                  Validators.required('Enter email'),
                                  Validators.email('Invalid email'),
                                ]),
                              ),
                              const SizedBox(height: height12),
                              AuthTextField(
                                controller: _passwordController,
                                obscureText: true,
                                hint: "Password",
                                prefix: lockImage,
                                validator: Validators.compose([
                                  Validators.required(),
                                  Validators.minLength(6),
                                ]),
                              ),
                              const SizedBox(height: height12),

                              AuthTextField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                hint: "Confirm password",
                                prefix: lockImage,
                                validator: Validators.compose([
                                  Validators.required("Repeat your password"),
                                  Validators.confirmPassword(
                                    _passwordController,
                                  ),
                                ]),
                              ),
                              const SizedBox(height: height16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: _agreed,
                                    onChanged: (v) =>
                                        setState(() => _agreed = v ?? false),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    activeColor: buttonBackgroundColor,
                                  ),
                                  const SizedBox(width: width2),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: bodySmallTextStyle,
                                        children: [
                                          const TextSpan(
                                            text:
                                                'By creating an account you agree to our ',
                                          ),
                                          TextSpan(
                                            text: 'Terms of Service',
                                            style: hintSmallTextStyle,
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                /* open terms */
                                              },
                                          ),
                                          const TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: hintSmallTextStyle,
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                /* open policy */
                                              },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: height12),

                              AppButton(
                                width: width300,
                                text: "Sign up",
                                loading: _loading,
                                onPressed: (_agreed && !_loading)
                                    ? _register
                                    : null, // ← отключаем до галочки
                              ),

                              const SizedBox(height: height12),
                              RichText(
                                text: TextSpan(
                                  style: bodyTextStyle,
                                  children: [
                                    const TextSpan(
                                      text: "Already have an account? ",
                                    ),
                                    TextSpan(
                                      text: 'Sign in',
                                      style: hintTextStyle,
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () => Navigator.pushNamed(
                                          context,
                                          '/login',
                                        ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
