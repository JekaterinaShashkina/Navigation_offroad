// services/phone_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:offroad_nav/features/auth/data/repositories/user_repository.dart';

class PhoneAuthService {
  PhoneAuthService._();
  static final instance = PhoneAuthService._();

  final _auth = FirebaseAuth.instance;

  /// 1) Старт входа по телефону: отправляет СМС или автоподтверждает
  Future<void> startPhoneSignIn({
    required BuildContext context,
    required String phoneE164,          // +372...
    int? forceResendToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneE164,
      timeout: const Duration(seconds: 60),

      // Android может авторизовать автоматически (без ввода кода)
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final uc = await _auth.signInWithCredential(credential);
          await _onSignedIn(context, uc.user!, phoneE164: phoneE164);
        } on FirebaseAuthException catch (e) {
          _show(context, _mapError(e));
        } catch (e) {
          _show(context, 'Auto verification failed: $e');
        }
      },

      verificationFailed: (FirebaseAuthException e) {
        _show(context, _mapError(e));
      },

      // Код отправлен — открываем экран ввода кода
      codeSent: (String verificationId, int? resendToken) {
        if (!context.mounted) return;
        Navigator.pushNamed(
          context,
          '/phone_otp', // ваш экран ввода кода
          arguments: {
            'verificationId': verificationId,
            'resendToken': resendToken,
            'phone': phoneE164,
          },
        );
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        // нормальная ситуация, если автоподтверждение не успело
      },

      forceResendingToken: forceResendToken,
    );
  }

  /// 2) Повторная отправка кода (используй resendToken с экрана OTP)
  Future<void> resendCode({
    required BuildContext context,
    required String phoneE164,
    required int resendToken,
  }) {
    return startPhoneSignIn(
      context: context,
      phoneE164: phoneE164,
      forceResendToken: resendToken,
    );
  }

  /// 3) Подтверждение СМС-кода (вход по телефону)
  Future<void> submitSmsCode(
    BuildContext context, {
    required String verificationId,
    required String smsCode,
    required String phoneE164,
  }) async {
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final uc = await _auth.signInWithCredential(cred);
      await _onSignedIn(context, uc.user!, phoneE164: phoneE164);
    } on FirebaseAuthException catch (e) {
      _show(context, _mapError(e));
    }
  }

  /// Общая логика после успешного входа:
  /// апсерт профиля и переход в приложение
  Future<void> _onSignedIn(
    BuildContext context,
    User user, {
    String? phoneE164,
  }) async {
    try {
      await UserRepository.upsertOnLogin(
        user,
        extra: {
          // сохраняем телефон, если есть (user.phoneNumber на Android/iOS тоже может прийти)
          if ((phoneE164 ?? user.phoneNumber)?.isNotEmpty == true)
            'phone': phoneE164 ?? user.phoneNumber!,
        },
      );
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false);
    } catch (e) {
      _show(context, 'Profile update failed: $e');
    }
  }

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number.';
      case 'missing-phone-number':
        return 'Enter phone number.';
      case 'invalid-verification-code':
        return 'Invalid code. Please try again.';
      case 'session-expired':
        return 'Code expired. Request a new one.';
      case 'captcha-check-failed':
      case 'app-not-authorized':
        return 'Verification failed. Check app configuration / Google Play services.';
      case 'quota-exceeded':
        return 'SMS quota exceeded for this project.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      default:
        return e.message ?? 'Phone auth error.';
    }
  }

  void _show(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }
}
