import 'package:firebase_auth/firebase_auth.dart';

import '../services/google_auth_service.dart';
import 'user_repository.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // 📧 Логин по email/паролю
  Future<UserCredential> signInWithEmail(
    String email,
    String password,
  ) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // 📧 Сброс пароля
  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  // 🟦 Регистрация по email/паролю
  Future<UserCredential> registerWithEmail({
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

    return cred;
  }
  
    // 🟦 Логин через Google (через твой GoogleAuthService)
  Future<UserCredential> signInWithGoogle() {
    return GoogleAuthService.instance.signInWithGoogle();
  }

  // 🚪 Выход (через GoogleAuthService, он же дергает _auth.signOut)
  Future<void> signOut() async {
    await GoogleAuthService.instance.signOut();
  }
}
