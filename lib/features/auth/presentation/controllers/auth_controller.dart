import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offroad_nav/core/failure.dart';
import 'package:offroad_nav/core/result.dart';
import 'package:offroad_nav/features/auth/domain/repositories/i_auth_repository.dart';

import '../../data/services/phone_auth_service.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthAction {
  emailSignIn,
  resetPassword,
  phoneSignIn,
  googleSignIn,
  register;
}


class AuthState {
  final bool loading;
  final Failure? error;
  final AuthAction? lastAction;
  static const _unset = Object();

  const AuthState( {
    this.loading = false,
    this.error, 
    this.lastAction,

  });

  AuthState copyWith({
    bool? loading,
    Failure? error,
    Object? lastAction = _unset,
  }) {
    return AuthState(
      loading: loading ?? this.loading,
      error: error,
      lastAction: identical(lastAction, _unset)
          ? this.lastAction
          : lastAction as AuthAction?,
    );
  }
}

// репозиторий
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository();
});

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  IAuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() => const AuthState();

    Result<void> _toVoidResult<T>(Result<T> result) {
    if (result.error != null) {
      return Result.err(result.error!);
    }
    return Result.okVoid();
  }

    // 📧 Логин по email/паролю
  Future<Result<void>> signInWithEmail(
    String email,
    String password,
  ) async {
    state = state.copyWith(
      loading: true,
      error: null,
      lastAction: AuthAction.emailSignIn,
    );

    final result = await _repo.signInWithEmail(email, password);
    state = state.copyWith(
      loading: false,
      error: result.error,
      lastAction: AuthAction.emailSignIn,
    );
    return _toVoidResult(result);
  }

  // 📧 Сброс пароля
  Future<Result<void>> sendPasswordReset(
    String email,
  ) async {
    state = state.copyWith(
      loading: true,
      error: null,
      lastAction: AuthAction.resetPassword,
    );
    final result = await _repo.sendPasswordReset(email);
    state = state.copyWith(
      loading: false,
      error: result.error,
      lastAction: AuthAction.resetPassword,
    );
    return result;
  }


  /// Старт авторизации по телефону (через твой PhoneAuthService)
  Future<void> signInWithPhone({
    required BuildContext context,
    required String phoneE164,
  }) async {
    // включаем лоадер
        state = state.copyWith(
      loading: true,
      error: null,
      lastAction: AuthAction.phoneSignIn,
    );
    try {
      await PhoneAuthService.instance.startPhoneSignIn(
        context: context,
        phoneE164: phoneE164,
      );
      // если всё ок — просто убираем лоадер, ошибку не трогаем
      state = state.copyWith(
        loading: false,
        lastAction: AuthAction.phoneSignIn,
      );
    } catch (e) {
      // если что-то сломалось — сохраняем текст ошибки
      state = state.copyWith(
        loading: false,
        error: AuthFailure(e.toString()),
        lastAction: AuthAction.phoneSignIn,
      );
    }
  }
  /// 🟦 Google
  Future<Result<void>> signInWithGoogle() async {
    state = state.copyWith(
      loading: true,       
      error: null,
      lastAction: AuthAction.googleSignIn,
    );
    final result = await _repo.signInWithGoogle();
    state = state.copyWith(
      loading: false,
      error: result.error,
      lastAction: AuthAction.googleSignIn,
    );
    return _toVoidResult(result);
  }

// 🟣 Регистрация по email/паролю
  Future<Result<void>> registerWithEmail(
    BuildContext context, {
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      loading: true, 
      error: null,
      lastAction: AuthAction.register,
    );
    final result = await _repo.registerWithEmail(
          name: name,
          email: email,
          password: password,
        );

    state = state.copyWith(
      loading: false,
      error: result.error,
      lastAction: AuthAction.register,
    );
    return _toVoidResult(result);
  }

  /// 🚪 Выход (опционально, если где-то нужен)
  Future<Result<void>> signOut() async {
    return _repo.signOut();
  }
}
