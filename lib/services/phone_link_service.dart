import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:offroad_nav/pages/auth/phone_otp_page.dart';

/// Сервис для привязки телефона к ТЕКУЩЕМУ пользователю (link).
class PhoneLinkService {
  PhoneLinkService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Запускает verifyPhoneNumber и, если нужен код, открывает PhoneOtpPage.
  /// Возвращает true при успешной линковке, иначе false.
  Future<bool> linkWithOtpPage(BuildContext context, String phoneE164) async {
    final c = Completer<bool>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneE164,

      // Авто-верификация (иногда на Android)
      verificationCompleted: (PhoneAuthCredential cred) async {
        try {
          final user = _auth.currentUser;
          if (user == null) {
            _showError(context, 'No signed-in user.');
            if (!c.isCompleted) c.complete(false);
            return;
          }
          await user.linkWithCredential(cred);
          if (!c.isCompleted) c.complete(true);
        } on FirebaseAuthException catch (e) {
          if (!c.isCompleted) c.complete(false);
          _showError(context, _mapLinkError(e));
        }
      },

      verificationFailed: (FirebaseAuthException e) {
        if (!c.isCompleted) c.complete(false);
        _showError(context, e.message ?? 'Phone verification failed');
      },

      codeSent: (String verificationId, int? resendToken) async {
        if (!context.mounted) return;
        final res = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => const PhoneOtpPage(),
            settings: RouteSettings(arguments: {
              'verificationId': verificationId,
              'resendToken': resendToken,
              'phone': phoneE164,
              'flow': 'link', // режим ЛИНКОВКИ
            }),
          ),
        );
        if (!c.isCompleted) c.complete(res == true);
      },

      codeAutoRetrievalTimeout: (_) {},
    );

    return c.future;
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _mapLinkError(FirebaseAuthException e) {
    switch (e.code) {
      case 'credential-already-in-use':
        return 'This phone is already linked to another account.';
      case 'provider-already-linked':
        return 'Phone provider already linked.';
      case 'requires-recent-login':
        return 'Please re-login and try again.';
      default:
        return e.message ?? 'Link failed';
    }
  }
}
