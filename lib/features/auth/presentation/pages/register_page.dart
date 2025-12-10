import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/avatars.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/images.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';
import 'package:offroad_nav/features/auth/presentation/widgets/auth_card.dart';
import 'package:offroad_nav/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:offroad_nav/design/widgets/avatar_circle.dart';
import 'package:offroad_nav/features/auth/presentation/widgets/phone_input_field.dart';
import 'package:offroad_nav/design/widgets/verify_toggle_button.dart';
import 'package:offroad_nav/models/country_code.dart';
import 'package:offroad_nav/features/auth/presentation/pages/sign_up_success_page.dart';
import 'package:offroad_nav/services/phone_link_service.dart';
import 'package:offroad_nav/utils/validators.dart';

import 'package:offroad_nav/features/auth/presentation/controllers/auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullnameController = TextEditingController();
  final _phoneController = TextEditingController();
  late Future<List<CountryCode>> _codesFuture;
  String _dialCode = '+372';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _agreed = false;
  bool _verifyPhoneRequested = false;
  bool _phoneLinked = false;

  String? _selectedAvatarPath;

  @override
  void initState() {
    super.initState();
    _codesFuture = loadCountryCodes();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullnameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept Terms & Privacy')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // если запросили привязку телефона — подготовим номер
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

    // 1) регистрация по email через контроллер
    final authNotifier = ref.read(authControllerProvider.notifier);
    await authNotifier.registerWithEmail(
      context,
      name: _fullnameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    final authState = ref.read(authControllerProvider);
    if (authState.error != null) {
      // ошибка уже показана внутри контроллера — остаёмся на странице
      return;
    }

    // 2) если просили привязать телефон — запускаем линковку
    if (_verifyPhoneRequested && phoneE164 != null) {
      final ok = await PhoneLinkService().linkWithOtpPage(context, phoneE164);

      if (!ok) {
        if (mounted) {
          setState(() {
            _phoneLinked = false;
          });
        }
        return; // не идём на success, остаёмся на экране
      }

      if (mounted) {
        setState(() {
          _phoneLinked = true;
          _verifyPhoneRequested = false;
        });
      }
    }

    // 3) всё прошло — идём на success
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignUpSuccessPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: 'Sign up',
        onPressed: () => Navigator.of(context).pop(),
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
                                  final selected =
                                      await showAvatarPicker(context);
                                  if (selected == null) return;
                                  setState(
                                    () => _selectedAvatarPath = selected,
                                  );
                                },
                                placeholder: photoImage,
                              ),
                              const SizedBox(height: height12),

                              /// Full name
                              AuthTextField(
                                controller: _fullnameController,
                                hint: "Full name",
                                prefix: personAddIcon,
                                validator:
                                    Validators.required("Enter fullname"),
                              ),
                              const SizedBox(height: height12),

                              /// Phone + verify toggle
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: FutureBuilder<List<CountryCode>>(
                                      future: _codesFuture,
                                      builder: (ctx, snap) {
                                        if (!snap.hasData) {
                                          return const SizedBox(
                                            height: 56,
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        }
                                        if (snap.hasError) {
                                          return const Text(
                                              'Failed to load country codes');
                                        }
                                        final countries = snap.data!;
                                        return IgnorePointer(
                                          ignoring: _phoneLinked,
                                          child: PhoneInputField(
                                            controller: _phoneController,
                                            items: countries,
                                            initialDialCode: _dialCode,
                                            arrow: arrowDownImage,
                                            onDialCodeChanged: (code) {
                                              setState(() => _dialCode = code);
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  VerifyToggleButton(
                                    active: _verifyPhoneRequested,
                                    verified: _phoneLinked,
                                    busy: false,
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

                              /// Email
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

                              /// Password
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

                              /// Confirm password
                              AuthTextField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                hint: "Confirm password",
                                prefix: lockImage,
                                validator: Validators.compose([
                                  Validators.required("Repeat your password"),
                                  Validators.confirmPassword(
                                      _passwordController),
                                ]),
                              ),
                              const SizedBox(height: height16),

                              /// Terms checkbox
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: _agreed,
                                    onChanged: (v) => setState(
                                        () => _agreed = v ?? false),
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
                                            recognizer:
                                                TapGestureRecognizer()
                                                  ..onTap = () {
                                                    // TODO: open terms
                                                  },
                                          ),
                                          const TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: hintSmallTextStyle,
                                            recognizer:
                                                TapGestureRecognizer()
                                                  ..onTap = () {
                                                    // TODO: open policy
                                                  },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: height12),

                              /// Sign up button
                              AppButton(
                                width: width300,
                                text: "Sign up",
                                loading: authState.loading,
                                onPressed: (_agreed && !authState.loading)
                                    ? _register
                                    : null,
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
