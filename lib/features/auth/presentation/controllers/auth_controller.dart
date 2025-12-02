import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/phone_auth_service.dart';
import '../../data/auth_repository.dart';

class AuthState {
  final bool loading;
  final String? error;

  const AuthState({
    this.loading = false,
    this.error,
  });

  AuthState copyWith({
    bool? loading,
    String? error,
  }) {
    return AuthState(
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

// репозиторий
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

    // 📧 Логин по email/паролю
  Future<void> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    state = state.copyWith(loading: true, error: null);

    try {
      await ref.read(authRepositoryProvider).signInWithEmail(email, password);
      state = state.copyWith(loading: false);
      // успех, ошибки нет — навигацию оставим на странице
    } on FirebaseAuthException catch (e) {
      final code = e.code;
      final msg = switch (code) {
        'invalid-email' => 'Invalid email address.',
        'user-not-found' => 'No user found for this email.',
        'wrong-password' => 'Wrong password.',
        'user-disabled' => 'This account is disabled.',
        _ => e.message ?? 'Login failed. Try again.',
      };

      state = state.copyWith(loading: false, error: msg);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: $e')),
      );
    }
  }

  // 📧 Сброс пароля
  Future<void> sendPasswordReset(
    BuildContext context,
    String email,
  ) async {
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset link sent to your email.')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to send reset link')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reset link: $e')),
      );
    }
  }


  /// Старт авторизации по телефону (через твой PhoneAuthService)
  Future<void> signInWithPhone({
    required BuildContext context,
    required String phoneE164,
  }) async {
    // включаем лоадер
    state = state.copyWith(loading: true, error: null);

    try {
      await PhoneAuthService.instance.startPhoneSignIn(
        context: context,
        phoneE164: phoneE164,
      );
      // если всё ок — просто убираем лоадер, ошибку не трогаем
      state = state.copyWith(loading: false);
    } catch (e) {
      // если что-то сломалось — сохраняем текст ошибки
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );

      // можно сразу показать SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auth error: ${e.toString()}')),
      );
    }
  }
  /// 🟦 Google
  Future<void> signInWithGoogle(BuildContext context) async {
    state = state.copyWith(loading: true, error: null);

    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      state = state.copyWith(loading: false);
      // навигацию после успешного входа оставляем на странице
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'aborted-by-user' => 'Sign-in cancelled.',
        'google-sign-in-failed' => 'Google sign-in failed.',
        _ => e.message ?? 'Google sign-in error.',
      };

      state = state.copyWith(loading: false, error: msg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google login error: $e')),
      );
    }
  }

// 🟣 Регистрация по email/паролю
  Future<void> registerWithEmail(
    BuildContext context, {
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(loading: true, error: null);

    try {
      await ref.read(authRepositoryProvider).registerWithEmail(
            name: name,
            email: email,
            password: password,
          );

      state = state.copyWith(loading: false);
      // навигацию будем делать в самой странице, если ошибки нет
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'email-already-in-use' => 'This email is already in use.',
        'invalid-email' => 'Invalid email address.',
        'weak-password' => 'Password is too weak.',
        _ => e.message ?? 'Registration failed. Try again.',
      };

      state = state.copyWith(loading: false, error: msg);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration error: $e')),
      );
    }
  }
  /// 🚪 Выход (опционально, если где-то нужен)
  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }
}
