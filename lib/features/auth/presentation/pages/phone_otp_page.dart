import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';
import 'package:offroad_nav/design/widgets/auth_card.dart';
import 'package:offroad_nav/services/phone_auth_service.dart';
import 'package:offroad_nav/services/user_repository.dart'; // ← для upsert после link

class PhoneOtpPage extends StatefulWidget {
  const PhoneOtpPage({super.key});

  @override
  State<PhoneOtpPage> createState() => _PhoneOtpPageState();
}

class _PhoneOtpPageState extends State<PhoneOtpPage> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  int _secs = 60;
  Timer? _timer;

  late String _verificationId;
  late String _phoneE164;
  int? _resendToken;
  late String _flow; // 'signIn' | 'link'

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      _verificationId = args['verificationId'] as String;
      _phoneE164      = args['phone']         as String;
      _resendToken    = args['resendToken']   as int?;
      _flow           = (args['flow'] as String?) ?? 'signIn';
      _startTimer();
    });
    _codeCtrl.addListener(() => setState(() {}));
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secs = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secs <= 1) {
        t.cancel();
        setState(() => _secs = 0);
      } else {
        setState(() => _secs--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) return;

    setState(() => _loading = true);
    try {
      if (_flow == 'signIn') {
        // ВХОД по телефону (создает/логинит phone-пользователя)
        await PhoneAuthService.instance.submitSmsCode(
          context,
          verificationId: _verificationId,
          smsCode: code,
          phoneE164: _phoneE164,
        );
        // навигация в сервисе
      } else {
        // ЛИНКОВКА к текущему e-mail пользователю
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          _show('Not signed in');
          return;
        }
        final cred = PhoneAuthProvider.credential(
          verificationId: _verificationId,
          smsCode: code,
        );

        try {
          await user.linkWithCredential(cred);
          await UserRepository.upsertOnLogin(user, extra: {'phone': _phoneE164});
          if (!mounted) return;
            Navigator.pop(context, true); 
        } on FirebaseAuthException catch (e) {
          // если такой номер уже привязан к другому аккаунту
          if (e.code == 'credential-already-in-use' || e.code == 'provider-already-linked') {
            _show('This phone number is already linked to another account.');
            setState(() => _loading = false);
            return;
          }
          rethrow;
        }
      }
    } on FirebaseAuthException catch (e) {
      _show(e.message ?? 'Invalid code');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_secs > 0) return;

    if (_flow == 'signIn') {
      // Для входа — переотправляем и снова открываем OTP через сервис входа
      Navigator.pop(context);
      await PhoneAuthService.instance.startPhoneSignIn(
        context: context,
        phoneE164: _phoneE164,
        forceResendToken: _resendToken,
      );
    } else {
      // Для линковки — НЕ делаем signIn!
      // Просто повторно вызовем verifyPhoneNumber для link-потока,
      // обновим verificationId и перезапустим таймер, оставаясь на этой странице.
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _show('Not signed in');
        return;
      }
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneE164,
        verificationCompleted: (cred) async {
          try {
            await user.linkWithCredential(cred);
            await UserRepository.upsertOnLogin(user, extra: {'phone': _phoneE164});
            if (mounted) Navigator.pop(context, true);
          } on FirebaseAuthException catch (e) {
            _show(e.message ?? 'Link failed');
          }
        },
        verificationFailed: (e) => _show(e.message ?? 'Verification failed'),
        codeSent: (id, token) {
          setState(() {
            _verificationId = id;
            _resendToken = token;
          });
          _startTimer();
        },
        codeAutoRetrievalTimeout: (_) {},
        forceResendingToken: _resendToken,
      );
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: _flow == 'link' ? 'Verify & Link phone' : 'OTP Verification',
        onPressed: () => Navigator.pop(context, false),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            AuthCard(
              child: Column(
                children: [
                  Text(
                    'An authentication code has been sent to\n$_phoneE164',
                    textAlign: TextAlign.center,
                    style: bodyTextStyle,
                  ),
                  const SizedBox(height: height24),
                  _OtpBoxes(controller: _codeCtrl, length: 6),
                  const SizedBox(height: height16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("I didn't receive code. ", style: bodySmallTextStyle),
                      GestureDetector(
                        onTap: _secs == 0 ? _resend : null,
                        child: Text(
                          'Resend Code',
                          style: _secs == 0 ? hintSmallTextStyle : bodySmallTextStyle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _secs == 0 ? 'You can resend now' : '${_secs}s left',
                    style: bodySmallTextStyle,
                  ),
                  const SizedBox(height: height24),
                  AppButton(
                    text: 'Verify Now',
                    width: 300,
                    loading: _loading,
                    onPressed: (_codeCtrl.text.length == 6 && !_loading) ? _verify : null,
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}


/// Отрисовывает 6 «пузырей» кода и скрытый TextField.
/// Пользователь печатает в один контроллер, а мы показываем символы по коробочкам.
class _OtpBoxes extends StatefulWidget {
  const _OtpBoxes({required this.controller, this.length = 6});
  final TextEditingController controller;
  final int length;

  @override
  State<_OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<_OtpBoxes> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(_focus),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.length, (i) {
              final char = i < text.length ? text[i] : '';
              return Container(
                width: 35,
                height: 35,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: backgroundMainColor,
                  borderRadius: BorderRadius.circular(radius12),
                ),
                alignment: Alignment.center,
                child: Text(
                  char,
                  style: head1TextStyle,
                ),
              );
            }),
          ),
          // Невидимый TextField
          Opacity(
            opacity: 0.0,
            child: SizedBox(
              width: 0,
              height: 0,
              child: TextField(
                focusNode: _focus,
                controller: widget.controller,
                keyboardType: TextInputType.number,
                maxLength: widget.length,
                autofocus: true, 
                      inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                decoration: const InputDecoration(counterText: ''),
              ),
            ),
          ),
        ],
      ),
    );
  }
  }
