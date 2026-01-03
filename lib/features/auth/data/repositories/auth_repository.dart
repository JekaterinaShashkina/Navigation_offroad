import 'package:firebase_auth/firebase_auth.dart';
import 'package:offroad_nav/core/failure.dart';
import 'package:offroad_nav/core/result.dart';
import 'package:offroad_nav/features/auth/domain/entities/auth_user.dart';
import 'package:offroad_nav/features/auth/domain/repositories/i_auth_repository.dart';

import '../services/google_auth_service.dart';
import 'user_repository.dart';

class AuthRepository implements IAuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

    // --- маппер из Firebase User в наш доменный AuthUser ----
  AuthUser? _mapUser(User? u) {
    if (u == null) return null;
    return AuthUser(
      id: u.uid,
      email: u.email,
      phone: u.phoneNumber,
      name: u.displayName,
      photoUrl: u.photoURL,
    );
  }

  @override
  Stream<AuthUser?> authStateChanges() =>
      _auth.authStateChanges().map(_mapUser);

  @override
  AuthUser? get currentUser => _mapUser(_auth.currentUser);

  // 📧 Логин по email/паролю
  @override
  Future<Result<AuthUser>> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
          final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
        final user = cred.user;
            if (user != null) {
      await UserRepository.upsertOnLogin(user);
    }
    return Result.ok(_mapUser(user)!);
    } on FirebaseAuthException catch (e) {
      return Result.err(_mapFirebaseException(e));
    } on Failure catch (f) {
      return Result.err(f);
    } catch (e) {
      return Result.err(AuthFailure(e.toString()));
    }
  }

  // 📧 Сброс пароля
  @override
  Future<Result<void>> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return Result.okVoid();
    } on FirebaseAuthException catch (e) {
      return Result.err(_mapFirebaseException(e));
    } catch (e) {
      return Result.err(AuthFailure(e.toString()));
    }
  }


  // 🟦 Регистрация по email/паролю
  @override
  Future<Result<AuthUser>> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
        final user = cred.user;
    if (user != null) {
      // обновим отображаемое имя в Firebase Auth
      await user.updateDisplayName(name);
      await user.reload();

      // и в Firestore (или где там у тебя users)
      await UserRepository.upsertOnLogin(
        user,
        extra: {
          'name': name,
          'email': email,
        },
      );
    }
          return Result.ok(_mapUser(cred.user)!);
    } on FirebaseAuthException catch (e) {
      return Result.err(_mapFirebaseException(e));
    } on Failure catch (f) {
      return Result.err(f);
    } catch (e) {
      return Result.err(AuthFailure(e.toString()));
    }
  }
  
    // 🟦 Логин через Google (через твой GoogleAuthService)
  @override
  Future<Result<AuthUser>> signInWithGoogle() async {
    try {
          final cred = await GoogleAuthService.instance.signInWithGoogle();
    final user = cred.user;
    return Result.ok(_mapUser(user)!);
    } on FirebaseAuthException catch (e) {
      return Result.err(_mapFirebaseException(e));
    } on Failure catch (f) {
      return Result.err(f);
    } catch (e) {
      return Result.err(AuthFailure(e.toString()));
    }
  }

  // 🚪 Выход (через GoogleAuthService, он же дергает _auth.signOut)
  Future<Result<void>> signOut() async{
    try {
          await GoogleAuthService.instance.signOut();
          return Result.okVoid();
    } on FirebaseAuthException catch (e) {
      return Result.err(_mapFirebaseException(e));
    } catch (e) {
      return Result.err(AuthFailure(e.toString()));
    }
  }

  AuthFailure _mapFirebaseException(FirebaseAuthException e) {
    final msg = switch (e.code) {
      'invalid-email' => 'Invalid email address.',
      'user-not-found' => 'No user found for this email.',
      'wrong-password' => 'Wrong password.',
      'user-disabled' => 'This account is disabled.',
      'email-already-in-use' => 'This email is already in use.',
      'weak-password' => 'Password is too weak.',
      'aborted-by-user' => 'Sign-in cancelled.',
      'google-sign-in-failed' => 'Google sign-in failed.',
      _ => e.message ?? 'Authentication error. Try again.',
    };

    return AuthFailure(msg);
  }
}
