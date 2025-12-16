import 'package:firebase_auth/firebase_auth.dart';
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
  Future<AuthUser> signInWithEmail(
    String email,
    String password,
  ) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
        final user = cred.user;

    if (user != null) {
      await UserRepository.upsertOnLogin(user);
    }

    return _mapUser(user)!;
  }

  // 📧 Сброс пароля
  @override
  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }


  // 🟦 Регистрация по email/паролю
  @override
  Future<AuthUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
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

    return _mapUser(cred.user)!;
  }
  
    // 🟦 Логин через Google (через твой GoogleAuthService)
  @override
  Future<AuthUser> signInWithGoogle() async{
    final cred = await GoogleAuthService.instance.signInWithGoogle();
    final user = cred.user;
    return _mapUser(user)!;
  }

  // 🚪 Выход (через GoogleAuthService, он же дергает _auth.signOut)
  Future<void> signOut() async {
    await GoogleAuthService.instance.signOut();
  }
}
